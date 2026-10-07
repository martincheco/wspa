;Soubor definuje funkci LoadCS, ktera cte spektroskopii na nepravidelne mrizce ze souboru *.cs
;Navratovou hodnotou je struktura typu CsStruct, obsahujici data o spektroskopii
;POLOZKY struktury CsStruct:
;n = pocet spekter
;x, y = ukazatele na pole se souradnicemi bodu, ve kterych byla snimana spektra
;data = ukazatel na dvourozmerne pole se spektroskopickymi daty:
;  1. index pole urcuje spektrum (topograficky bod, ve kterem bylo spektrum mereno)
;  2. index urcuje bod spektra (jeden z bodu namerene zavislosti)
;xscl = ukazatel na pole s nezavislou promennou analogicke poli data

function EmptyStr, s
;Zjisti, zda je zadany retezec prazdny
;Za prazdny je zde povazovan takovy retezec, ktery
;neobsahuje zadne jine znaky nez bile (mezery apod.)
return, strcompress(s, /remove_all) EQ ''
end

function readln, LUN
;precte radek ze souboru s cislem LUN
;navratovou hodnotou funkce je precteny radek

line = ''
c = 0B ;promenna pro ulozeni znaku
if not eof(LUN) then readu, LUN, c
while (not eof(LUN)) and (c NE 10) and (c NE 13) do begin
  line = line + string(c)
  readu, LUN, c;
endwhile
return, line
end

function ContainsStr, source, searched, case_sensitive
;Zjisti, zda zdrojovy retezec v sobe obsahuje hledany podretezec
;source = zdrojovy retezec
;searched = hledany podretezec
;/case_sensitive = pri testovani vyskytu se zohlednuji velka a mala pismena
;pocet mezer se nezohlednuje

if not keyword_set(case_sensitive) then case_sensitive = 0
s = strcompress(source)
t = strcompress(searched)
if not case_sensitive then begin
  s = strlowcase(s)
  t = strlowcase(t)
endif
return, strpos(s, t) GT -1
end


function LoadCS, filename, OK = OK, npoints = npoints
;nacita spektroskpii ze souboru typu *.cs0
;filename = jmeno souboru se spektry (vcetne pripony cs*)
;npoints = predpokladany pocet bodu v jednom spektru
;OK = indikator bezchybneho precteni souboru

;vraci strukturu typu CsStruct (viz vyse)

csdata = {CsStruct, n:0, x:ptr_new(), y:ptr_new(), data:ptr_new(), xscl:ptr_new()}

;otevirani souboru s detekci chyby
catch, error
if keyword_set (error) then begin
  OK = 0
  print, !ERROR_STATE.MSG_PREFIX + 'loadcs: Unable to open file "' + filename + '"'
close,/all  
 ; free_LUN, LUN
  return, 0
endif
openr, LUN, filename, /get_LUN
catch, /cancel

OK = 1

;cteni souradnic
line = ''
i = 0
x0 = 0.0
y0 = 0.0
while not(ContainsStr(line, 'BEGIN COORD') or eof(LUN)) do line = readln(LUN)
while not(ContainsStr(line, 'END COORD') or eof(LUN)) do begin    
  line = readln(LUN)
  if not (EmptyStr(line) or ContainsStr(line, 'END COORD')) then begin
    on_ioerror, ErrCoords
    reads, line, x0, y0
    if not keyword_set(x) then begin
      x = [x0]
      y = [y0]
    endif else begin
      x = [x, x0]
      y = [y, y0]
    endelse
    i = i +  1
    continue
    ErrCoords: 
    print, !ERROR_STATE.MSG_PREFIX + 'Wrong line "' + line + "'
  endif
endwhile
ns = i

if ns EQ 0 then begin
  OK = 0
  print, !ERROR_STATE.MSG_PREFIX + 'No coordinates found'
  
  ;free_LUN, LUN

  return, 0
endif

;cteni spekter
i = 0
while not(eof(LUN) or (i GE ns)) do begin

  ;cteni jednoho spektra
  j = 0
  while not(ContainsStr(line, 'BEGIN') or eof(LUN)) do line = readln(LUN)

  ;precteni poradoveho cisla spekta
  ii = ns; nepripustna hodnota poradoveho cisla - indikator chybneho cteni
  on_ioerror, ErrSpectNum
  num = strmid(line, (strpos(line, 'BEGIN') > 0) + strlen('BEGIN'))
  reads, num, ii
  ErrSpectNum: if ii GE ns then ii = i
  
  ;cteni vlastnich dat pro jedno spektrum  
  while not(ContainsStr(line, 'END') or eof(LUN) or (i GE ns)) do begin    
    line = readln(LUN)
    if not (EmptyStr(line) or ContainsStr(line, 'END')) then begin
      on_ioerror, ErrSpectLine
      
      reads, line, p, f
      if j EQ 0 then begin
      ;print,p
      ;print,f
        xscla = [float(p)]
        spectrum = [f] 
      endif else begin
        xscla = [xscla, p]
        spectrum = [spectrum, f]
      endelse
      j = j + 1
    endif
    continue
    ErrSpectLine:
    print, !ERROR_STATE.MSG_PREFIX + 'Wrong line "' + line + "'
  endwhile

  ;zapis precteneho spektra do promenne data
  if j GT 0 then begin
    if (i EQ 0) then begin
      if keyword_set(npoints) then np = npoints else np = j
      data = intarr(ns, np)
      xscl = fltarr(ns, np)
    endif
    bound = min([np, j]) - 1
    data[ii, 0: bound] = spectrum[0: bound]
    xscl[ii, 0: bound] = xscla[0: bound]
    i = i + 1
  endif
endwhile

if not keyword_set(data) then begin
  OK = 0
  print, !ERROR_STATE.MSG_PREFIX + 'No spectra found'
  
;free_LUN, LUN

  return, 0
endif else if i LT ns then begin
  OK = 0
  errtext = 'Read ' + string(ns) + ' pairs of coordinates but only ' + string(i) + ' spectra' 
  print, !ERROR_STATE.MSG_PREFIX + errtext
  ns = i
  data = data[0: ns-1, *]
  xscl = xscl[0: ns-1, *]
  
endif
  
csdata.n = ns
csdata.x = ptr_new(x)
csdata.y = ptr_new(y)
csdata.data = ptr_new(data)
csdata.xscl = ptr_new(xscl)

free_LUN, LUN

return, csdata
end
