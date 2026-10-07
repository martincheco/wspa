;DERIVOVANI JEDNOTLIVYCH SPEKTROSKOPICKYCH KRIVEK (KRIVKY ZE SOUBORU TYPU *.crv)

;Funkce pro vyhlazovani a derivovani

function BinomFilter, x, width = width, extrapolate = extrapolate
;vraci data vyhlazena binomickym filtrem
;binomicky filtr je diskretni obdobou gaussovskeho filtru
;width = sirka nosice filtru (druhy moment filtru = sqrt(width)/2)
;/extrapolate = pred vyhlazovanim prodlouzi sadu dat stredove soumerne s krajnimi body
;Neni-li zadano extrapolate, sada dat se prodlouzi kopirovanim krajnich bodu

if not keyword_set(width) then width = 2 else width = fix(width)
if width LT 1 then message, 'Filter width must be positive', /continue
;generovani filtru
filter = fltarr(width)
filter[0] = 1
for i = 2, width do filter = (filter + shift(filter, 1))/2.0
;filtr vytvoren
n = n_elements(x)
over = (width-1)/2; presah filtru pres okraj sady dat
if (keyword_set(extrapolate)) and (size(x, /n_dimensions) LT 2) and (width GT 2) and (over LT n) $
then begin
  ;extrapolace
  xx = [2*x[0] - rotate(x[0:over-1],2), x, 2*x[n-1] - rotate(x[n-over:n-1],2)]
  y = convol(xx, filter)
  y = y[over:n-1+over]
endif  else begin
  y = convol(x, filter, /edge_truncate)
endelse
if ((width mod 2) EQ 0) and (n GT 1) then y = y[1:*]
return, y
end

function SimpleDeriv, x, y, OK = OK
;vypocet derivace
;y(x) = puvodni funkce
;Bod vysledku o indexu 0 odpovida bodu uprostred mezi indexy 0 a 1 v zadani
;Celkem je vysledny vektor o jeden bod kratsi nez vektor vstupni
;Lze take zadat jen hodnoty y, hodnoty nezavisle promene pak budou zvoleny x = [0, 1, 2,...]

n = (size(x,/dimension))(0) - 1
if not keyword_set(y) then begin
  y = x
  x = indgen(n)
endif else if n_elements(x) NE n_elements(y) then begin
  OK = 0
  message, 'Vectors x and y must have the same size', /continue
  return, 0
endif else if n LT 2 then begin
  OK = 0
  message, 'At least 2 points needed to evaluate the derivative', /continue
  return, 0
endif
OK = 1
d = float((shift(y, -1) - y)[0:n-1])
return, d / ((shift(x, -1) - x)[0:n-1])
end

function LogDeriv, x, y, OK = OK
;Vypocet logaritmicke derivace pomoci prostych diferenci
;Puvodni funkce se automaticky vertikalne posouva tak, aby prochazela pocatkem
;Velikost nutneho posuvu je vyuzita jako numericka konstanta, modifikujici vzorec
;pro derivaci tak, aby nedochazelo k divergenci
;Bod vysledku o indexu 0 odpovida bodu uprostred mezi indexy 0 a 1 v zadani
;Celkem je vysledny vektor o jeden bod kratsi nez vektor vstupni
;y(x) = puvodni funkce

n = (size(x,/dimension))[0] - 1
if n_elements(x) NE n_elements(y) then begin
  OK = 0
  message, 'Vectors x and y must have the same size', /continue
  return, 0
endif else if n LT 2 then begin
  OK = 0
  message, 'At least 2 points needed to evaluate the derivative', /continue
  return, 0
endif
OK = 1
;interpolacni nalezeni hodnoty v nule
if (min(x) LE 0) and (max(x) GE 0) then begin
  ind = sort(abs(x))
  a = ind[0]
  b = ind[1]
  y0 = (y[a] * x[b] - y[b] * x[a]) / float(x[b] - x[a])
endif else y0 = 0.0
dy = ((shift(y, -1) - y) / float(shift(x, -1) - x))[0:n-1]
yy = float((abs(shift(y - y0, -1)) > abs(y - y0))[0:n-1])
xx = abs((shift(x, -1) + x)[0:n-1] / 2.0)
ly = fltarr(n)
ind = where(yy NE 0, count)
if count GE 0 then ly[ind] = dy[ind] / (yy[ind] + abs(y0)) * xx[ind]
return, ly
end

function PolynomAprox, x, y, xo = xo, degree = degree, OK = OK
;Provede polynomialni aproximaci bodu [x, y] (x, y jsou n-tice cisel)
;a vraci koeficienty a[k] aproximujiciho polynomu.
;Cleny polynomu se predpokladaji ve tvaru a[k]*(x-xo)^k
;Neni-li xo zadano, predpoklada se nulove
;degree = stupen approximujiciho polynomu (nejvyssi)

if not n_elements(x) EQ n_elements(y) then begin
  OK = 0
  message, 'Vectors x and y must have the same size', /continue
  return, 0
endif
n = n_elements(x)
if not keyword_set(xo) then xo = 0.0
if n_elements(degree) EQ 0 then degree = n - 1
if degree GE n then begin
  OK = 0
  message, 'The degree of the polynomial must be smaller than the number of points', /continue
  return, 0
endif
if degree EQ 0 then return, total(y) / n
;generovani matice soustavy
A = fltarr(degree + 1, n)
for i = 0, degree do A[i, *] = (x - xo)^i
SVDC, A, W, U, V
koef = SVSol(U, W, V, y)
OK = 1
return, koef
end

function PolynomDeriv, x, y, degree = degree, width = width, OK = OK, errortext = errortext
;Provede ciselnou derivaci navzorkovane zavislosti y(x) pomoci aproximujicich polynomu
;degree = rad aproximujicich polynomu
;width = pocet bodu, z nichz se vypocitavaji polynomy
;OK = vypocet probehl bezchybne
;errortext = vraci text chybove zpravy, pokud OK = 0
;Pokud je pocet bodu pro vypocet polynomu lichy, vraci funkce hodnoty derivace v bodech x,
;je-li sudy, vraci hodnoty v bodech lezicih vzdy mezi x[i] a x[i+1], techto bodu je vzdy o jeden mene nez bodu x
;Lze take zadat jen hodnoty y, hodnoty nezavisle promene pak budou zvoleny x = [0, 1, 2,...]

OK = 1
n = n_elements(x)
if n_elements(y) EQ 0 then begin
  y = x
  x = indgen(n)
endif else if n_elements(x) NE n_elements(y) then begin
  OK = 0
  errortext = 'Vectors x and y must have the same size'
  message, errortext, /continue
  return, 0
endif
if n_elements(degree) EQ 0 then degree = 1 else degree = fix(degree)
if n_elements(width) EQ 0 then width = degree + 1 else width = fix(width)
if degree LT 1 then begin
  OK = 0
  errortext = 'Polynomial degree must be at least 1'
  message, errortext, /continue
  return, 0
endif
if degree GE width then  begin
  OK = 0
  errortext = 'The degree of a polynomial must be lesser than the number of used points'
  message, errortext, /continue
  return, 0
endif
if (width LT 2) or (n LT width) then begin
  OK = 0
  errortext = 'Not enough points used to do the computation'
  message, errortext, /continue
  return, 0
endif

if (width mod 2) EQ 1 then begin
  dy = fltarr(n)
  for i = 0, n - 1 do begin
    leftmost = ((i - width / 2) > 0 ) < (n - width)
    rightmost = leftmost + width -1
    dy[i] = (PolynomAprox(x[leftmost:rightmost], y[leftmost:rightmost], $
      xo = x[i], degree = degree))[1]
  endfor
endif else begin
  dy = fltarr(n-1)
  for i = 0, n - 2 do begin
    leftmost = ((i + 1 - width / 2) > 0) < (n - width)
    rightmost = leftmost + width - 1
      dy[i] = (PolynomAprox(x[leftmost:rightmost], y[leftmost:rightmost], $
      xo = (x[i]+x[i+1])/2, degree = degree))[1]
  endfor
endelse
return, dy
end

function PolynomFilter, x, y, degree = degree, width = width, OK = OK, errortext = errortext
;Provede polynomialni filtraci navzorkovane zavislosti y(x)
;degree = rad aproximujicich polynomu
;width = pocet bodu, z nichz se vypocitavaji polynomy
;OK = vypocet probehl bezchybne
;Pokud je pocet bodu pro vypocet polynomu lichy, vraci funkce hodnoty derivace v bodech x,
;je-li sudy, vraci hodnoty v bodech lezicih vzdy mezi x[i] a x[i+1], techto bodu je vzdy o jeden mene nez bodu x
;Lze take zadat jen hodnoty y, hodnoty nezavisle promene pak budou zvoleny x = [0, 1, 2,...]

OK = 1
n = n_elements(x)
if n_elements(y) EQ 0 then begin
  y = x
  x = indgen(n)
endif else if n_elements(x) NE n_elements(y) then begin
  OK = 0
  errortext = 'Vectors x and y must have the same size'
  message, errortext, /continue
  return, 0
endif
if n_elements(degree) EQ 0 then degree = 0 else degree = fix(degree)
if n_elements(width) EQ 0 then width = degree + 1 else width = fix(width)
if degree LT 0 then begin
  OK = 0
  errortext = 'Polynomial degree must be positive'
  message, errortext, /continue
  return, 0
endif
if degree GE width then  begin
  OK = 0
  errortext = 'The degree of a polynomial must be lesser than the number of used points'
  message, errortext, /continue
  return, 0
endif
if (width LT 1) or (n LT width) then begin
  OK = 0
  errortext = 'Not enough points used to do the computation'
  message, errortext, /continue
  return, 0
endif

if (width mod 2) EQ 1 then begin
  dy = fltarr(n)
  for i = 0, n - 1 do begin
    leftmost = ((i - width / 2) > 0 ) < (n - width)
    rightmost = leftmost + width -1
    dy[i] = (PolynomAprox(x[leftmost:rightmost], y[leftmost:rightmost], $
      xo = x[i], degree = degree))[0]
  endfor
endif else begin
  dy = fltarr(n-1)
  for i = 0, n - 2 do begin
    leftmost = ((i + 1 - width / 2) > 0) < (n - width)
    rightmost = leftmost + width - 1
      dy[i] = (PolynomAprox(x[leftmost:rightmost], y[leftmost:rightmost], $
      xo = (x[i]+x[i+1])/2, degree = degree))[0]
  endfor
endelse
return, dy
end


;Funkce pro nacitani dat z textovych souboru

function readln, LUN
;precte a radek ze souboru s cislem LUN
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

function BeginsWith, source, searched, case_sensitive
;Zjisti, zda zdrojovy retezec zacina hledanym podretezcem
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
return, strpos(s, t) EQ 0
end

function EmptyStr, s
;Zjisti, zda je zadany retezec prazdny
;Za prazdny je zde povazovan takovy retezec, ktery
;neobsahuje zadne jine znaky nez bile (mezery apod.)
return, strcompress(s, /remove_all) EQ ''
end

function ReadCrvFile, filename
;Nacteni  dat ze souboru *.crv
;Vraci data ze souboru jako strukturovanou promennou
;Parametr:
;jmeno souboru (vcetne pripony)
;Polozky navracene struktury:
;x = nezavisle promenna
;y = zavisle promenna
;xunit = nazev jednotky nezavisle promenne veliciny
;yunit = nazev jednotky zavisle promenne veliciny
;n_points = pocet bodu jedne krivky
;n_curves = pocet krivek
;Pole x, y jsou dvourozmerna. Prvni index oznacuje bod v ramci krivky, druhy krivku

on_ioerror, exception
openr, LUN, filename, /get_LUN
line = ''
xunit = ''
yunit = ''
type = ''
np = 0
nc = 0
while not (eof(LUN) or ContainsStr(line, 'File for curve data')) do line = readln(LUN)
if ContainsStr(line, 'File for curve data') then begin
  ;soubor v predepsanem formatu
  ;CTENI HLAVICKY
  repeat begin
    line = readln(LUN)
    if ContainsStr(line, 'Number of Curves') then begin
      str = strmid(line, strpos(line, ':')+1)
      reads, str, nc
    endif
    if ContainsStr(line, 'Number of Points per Curve') then begin
      str = strmid(line, strpos(line, ':')+1)
      reads, str, np
    endif
    if ContainsStr(line, 'X Unit') then begin
      str = strmid(line, strpos(line, ':')+1)
      reads, str, xunit
      xunit = strtrim(strcompress(xunit), 2)
    endif
    if ContainsStr(line, 'Y Unit') then begin
      str = strmid(line, strpos(line, ':')+1)
      reads, str, yunit
      yunit = strtrim(strcompress(yunit), 2)
    endif
    if ContainsStr(line, 'Type of Curve') then begin
      str = strmid(line, strpos(line, ':')+1)
      reads, str, type
      type = strtrim(strcompress(type) ,2)
    endif
    if eof(LUN) then goto, exception
  endrep until BeginsWith(line, 'Curve :') or eof(LUN)
  ;CTENI KRIVEK
  if (np EQ 0) or (nc EQ 0) then goto, exception
  x = fltarr(np, nc)
  y = fltarr(np, nc)
  a = 0.0
  b = 0.0
  i = 0
  repeat begin
    j = 0
    curve = 0
    while not (BeginsWith(line, 'Curve :') or eof(LUN)) do line = readln(LUN)
    if not eof(LUN) then begin
    reads, strmid(line, strpos(line, ':') + 1), curve
    repeat begin
      line = readln(LUN)
      if not EmptyStr(line) then begin
        reads, line, a, b
        x[j, curve-1] = a
        y[j, curve-1] = b
        j = j + 1
      endif
    endrep until (j EQ np) or eof (LUN)
  i = i + 1
  endif
  endrep until (i EQ nc) or eof(LUN)
endif else begin

  free_LUN, LUN
  openr, LUN, filename, /get_LUN
  ;neformatovany soubor
  nc = 1
  np = 0
  repeat begin
    line = readln(LUN)
    if not EmptyStr(line) then begin
      reads, line, a, b
      if np EQ 0 then begin
        x = [a]
        y = [b]
      endif else begin
        x = [x, a]
        y = [y, b]
      endelse
      np = np + 1
    endif
  endrep until eof(LUN)
  x = reform(x, np, 1)
  y = reform(y, np, 1)
endelse

free_LUN, LUN
if keyword_set(type) and keyword_set(yunit) then yunit = type + '[' + yunit + ']'
return, {x:x, y:y, xunit:xunit, yunit:yunit, n_points: np, n_curves: nc}
exception: return, 0
end

function ReadCsFile, filename
;Nacteni  dat ze souboru *.cs?
;Vraci data ze souboru jako strukturovanou promennou
;Parametr:
;jmeno souboru (vcetne pripony)
;Polozky navracene struktury:
;x = nezavisle promenna
;y = zavisle promenna
;xunit = nazev jednotky nezavisle promenne veliciny (nevyuzito)
;yunit = nazev jednotky zavisle promenne veliciny (nevyuzito)
;n_points = pocet bodu jedne krivky
;n_curves = pocet krivek
;Pole x, y jsou dvourozmerna. Prvni index oznacuje bod v ramci krivky, druhy krivku

on_ioerror, exception
openr, LUN, filename, /get_LUN
line = ''
;Pocitani krivek
nc = -1
np = 0
repeat begin
  line = readln(LUN)
  if(nc GE 0) and not (EmptyStr(line) or ContainsStr(line, 'END')) then nc = nc + 1
  if ContainsStr(line, 'BEGIN') then nc = 0
endrep until ContainsStr(line, 'END') or eof(LUN)
if nc LE 0 then goto, exception
;CTENI KRIVEK
for i = 0, nc - 1 do begin
  if eof(LUN) then goto, exception
  while not ContainsStr(line, 'BEGIN') do line = readln(LUN)
  j = 0
  repeat begin
    line = readln(LUN)
    if not (EmptyStr(line) or ContainsStr(line, 'END')) then begin
      reads, line, a, b
      if i EQ 0 then begin
        if np EQ 0 then begin
          x1 = [a]
          y1 = [b]
        endif else begin
          x1 = [x1, a]
          y1 = [y1, b]
        endelse
        np = np + 1
      endif else begin
         if j LT np then begin
           x[j, i] = a
           y[j, i] = b
         endif
      endelse
      j = j+ 1
    endif
  endrep until ContainsStr(line, 'END')
  if i EQ 0 then begin
    x = fltarr(np, nc)
    y = fltarr(np, nc)
    x[*, 0] = x1
    y[*, 0] = y1
  endif
endfor
free_LUN, LUN

;Cteni popisku  osam z *.par souboru
xunit = ''
yunit = ''
coef = 1.0
if strpos(filename,'.') GE 0 then begin
  parfile = strmid(filename, 0, strpos(filename, '.', /reverse_search)) + '.par'
endif else begin
  parfile = filename + '.par'
endelse
case strupcase(!VERSION.OS_FAMILY) of
  'UNIX': sep = '/'
  'WINDOWS': sep = '\'
  else: sep = ':'
endcase                                                                       
if strpos(filename, sep) GE 0 then filename = strmid(filename, strpos(filename, sep, /reverse_search) + 1)
on_ioerror, continue
catch, Err
if keyword_set(Err) then retur
openr, LUN, parfile, /get_LUN
catch, /cancel
while not eof(LUN) do begin
  line = strcompress(readln(LUN)); Type
  if ContainsStr(line, 'Spectroscopy Channel') then begin
    if strpos(line, ':') GE 0 then line = strmid(line, strpos(line, ':') + 1) $
    else line = strmid(line, strpos(line, 'Spectroscopy Channel') + 1)
    if strpos(line, ';') GE 0 then line = strmid(line, 0, strpos(line, ';'))
    type = strtrim(strcompress(line),2)
    line = readln(LUN); Parameter
    if strpos(line, ';') GE 0 then line = strmid(line, 0, strpos(line, ';'))
    param = strtrim(strcompress(line),2)
    line = readln(LUN); Direction
    line = readln(LUN); Minimum raw value
    line = readln(LUN); Maximum raw value
    line = readln(LUN); Minimum value in physical unit
    line = readln(LUN); Maximum value in physical unit
    line = readln(LUN); Resolution
    resolution = 1.0
    reads, line, resolution
    line = readln(LUN); Physical unit
    if strpos(line, ';') GE 0 then line = strmid(line, 0, strpos(line, ';'))
    unit = strtrim(strcompress(line),2)
    line = readln(LUN); Number of spectroscopy points
    line = readln(LUN); Start point spectroscopy
    line = readln(LUN); End point spectroscopy
    line = readln(LUN); Increment point spectroscopy
    line = readln(LUN); Acquisition time per spectroscopy point
    line = readln(LUN); Delay time per spectroscopy point
    line = readln(LUN); Feedback On/Off
    line = readln(LUN); Filename
    if strpos(line, ';') GE 0 then line = strmid(line, 0, strpos(line, ';'))
    file = strtrim(strcompress(line),2) 
    line = readln(LUN); Displayname
    if strpos(line, ';') GE 0 then line = strmid(line, 0, strpos(line, ';'))
    display = strtrim(strcompress(line),2)
    if filename EQ file then begin
      xunit = param
      if keyword_set(display) then yunit = display + '[' + unit+ ']' else yunit = unit
      coef = resolution
    endif
  endif
continue:
endwhile

finish:
free_LUN, LUN
return, {x:x, y:y*coef, xunit:xunit, yunit:yunit, n_points: np, n_curves: nc}
exception: 
free_LUN, LUN
return, 0
end


;Uzivatelske prostredi

function GetOperation, TLB
;Funkce vraci strukturu popisujici prave nastaveny typ operace
;TLB = vrchol hiearchie widgetu
;OperationName = polozka struktury obsahujici oznaceni operace
;MethodName = polozka struktury obsahujici oznaceni numericke metody
;Pripadne dalsi polozky obsahuji parametry metody

omenu = widget_info(TLB, find_by_uname = 'OperationMenu')
widget_control, omenu, get_uvalue = OperationList
OperationName = OperationList[widget_info(omenu, /droplist_select)]
case OperationName of
  'Original': return, {OperationName: OperationName}
  'Derivative': begin
    method = widget_info(TLB, find_by_uname = 'DerivMethod')
    widget_control, method, get_uvalue = ListOfMethods
    MethodName = ListOfMethods[widget_info(method, /droplist_select)]
    field1 = widget_info(TLB, find_by_uname = 'DerivParam1')
    field2 = widget_info(TLB, find_by_uname = 'DerivParam2')
    widget_control, field1, get_value = param1
    widget_control, field2, get_value = param2
    return, {OperationName: OperationName, MethodName: MethodName, Param1:param1, Param2:param2}
  end
  'LogDeriv': begin
    method = widget_info(TLB, find_by_uname = 'DerivMethod')
    widget_control, method, get_uvalue = ListOfMethods
    MethodName = ListOfMethods[widget_info(method, /droplist_select)]
    field1 = widget_info(TLB, find_by_uname = 'DerivParam1')
    field2 = widget_info(TLB, find_by_uname = 'DerivParam2')
    widget_control, field1, get_value = param1
    widget_control, field2, get_value = param2
    return, {OperationName: OperationName, MethodName: MethodName, Param1:param1, Param2:param2}
  end
  'hoptest': begin
    return, {OperationName: OperationName}
  end

endcase
end

pro Add, ev
widget_control, ev.id, get_uvalue = type
case type of
  'crv': filter = '*.crv'
  'cs?': filter = '*cs*'
endcase
filenames = dialog_pickfile(filter = filter, /multiple_files, /read, /must_exist, $
  title = 'Select file(s) to be added to the list', dialog_parent = ev.top, get_path=directory)
if n_elements(filenames) EQ 1 then if ([filenames])[0] EQ '' then return
if keyword_set(directory) then cd, directory
list = widget_info(ev.top, find_by_uname = 'ListOfChannels')
if n_elements(filenames) EQ 1 then filenames = [filenames]
widget_control, list, get_uvalue = ListDescr, update = 0
for i = 0, n_elements(filenames) - 1 do begin
  case type of
    'crv': cont = ReadCrvFile(filenames[i])
    'cs?': cont = ReadCsFile(filenames[i])
  endcase
  if n_tags(cont) EQ 0 then BEGIN
    resp = dialog_message('Wrong format of a file: ' + filenames[i], /error, dialog_parent = ev.top)
  endif else begin
    ListDescr.n = ListDescr.n + cont.n_curves
    for j = 1, cont.n_curves do begin
      x = reform(cont.x[*, j-1])
      y = reform(cont.y[*, j-1])
      xunit = cont.xunit
      yunit = cont.yunit
      name = filenames[i]
      if cont.n_curves GT 1 then name = name + ' (' + string(j, $
        format = "(I2)") + ')'
      newitem = widget_button(list, value = name, uname = name, uvalue = $
        {x:ptr_new(x), y:ptr_new(y), xo:ptr_new(x), yo:ptr_new(y), xunit:xunit, yunit:yunit, $
        xou:xunit, you:yunit, select:0, task: ptr_new(GetOperation(ev.top)), $
        PointSel: intarr(n_elements(x)), PointStatus: intarr(n_elements(x))})
      ;Struktura popisujici polozku
      ;yo(xo) = puvodni (prectene) spektrum (xo, yo jsou ukazatele)
      ;y(x)  =  spektrum ke zobrazeni (po pripadne transformaci) (x, y jsou ukazatele)
      ;xunit, yunit = oznaceni jednotek na osach x, y
      ;xou, you = oznaceni jedotek na osach xo, yo
      ;select: indikuje vyber polozky
      ;task = ukazatel na popis operace provadene s polozkou
      ;PointSel = booleovske pole, urcujici, zda je odpovidajici bod spektra oznacen
      ;PointStatus = pole stavovych kodu pro jednotlive body spektra:
      ; 0 = bod zobrazovan normalne
      ; 1 = bod odstranen (nezobrazovan)
      ; 2 = bod zobrazovan jako prumer sousednich hodnot

    endfor
  endelse
endfor
widget_control, list, set_uvalue = ListDescr, /update
end

pro Remove, ev
dialog = widget_base(title = 'Select items to be removed from the list', /modal, $
  group_leader = ev.top, /column, event_pro = 'Removing', uvalue = ev.top)
id = widget_info(ev.top, find_by_uname = 'ListOfChannels')
id = widget_info(id, /child)
list =  widget_base(dialog, /nonexclusive, uname = 'List')
while id GT 0 do begin
  widget_control, id, get_value = name
  item = widget_button(list, value = name, uvalue = 0, uname = 'AnItem')
  id = widget_info(id, /sibling)
endwhile
buttons = widget_base(dialog, /row)
ok = widget_button(buttons, value = 'OK', uname = 'OK')
cancel = widget_button(buttons, value = 'Cancel', uname = 'Cancel')
widget_control, dialog, /realize
end

pro Removing, ev
if widget_info(ev.id, /name) EQ 'BUTTON' then begin
  uname = widget_info(ev.id, /uname)
  if uname EQ 'AnItem' then widget_control, ev.id, set_uvalue = ev.select
  if uname EQ 'OK' then begin
    n = 0; pocitadlo vsech zrusenych polozek
    s = 0; pocitadlo zrusenych polozek, ktere byly oznaceny jako zobrazovane
    widget_control, ev.handler, get_uvalue = top
    widget_control, top, update = 0
    id = widget_info(ev.handler, find_by_uname = 'List')
    id = widget_info(id, /child)
    while id NE 0 do begin; do for all items
      widget_control, id, get_uvalue = select, get_value = name
      if select then begin
        n = n + 1
        item = widget_info(top, find_by_uname = name)
        widget_control, item, get_uvalue = ItemDescr
        if ItemDescr.select then s = s + 1
        ptr_free, ItemDescr.x
        ptr_free, ItemDescr.y
        ptr_free, ItemDescr.xo
        ptr_free, ItemDescr.yo
        ptr_free, ItemDescr.task
        widget_control, item, /destroy
      endif
      id = widget_info(id, /sibling)
    endwhile
    list = widget_info(top, find_by_uname = 'ListOfChannels')
    widget_control, list, get_uvalue = ListDescr
    Listdescr.n = Listdescr.n - n
    Listdescr.sel = Listdescr.sel - s
    widget_control, list, set_uvalue = Listdescr
    call_procedure, 'Refresh', top
    widget_control, top, /update
  endif
  if (uname EQ 'OK') or (uname EQ 'Cancel') then widget_control, ev.handler, /destroy
endif
end

pro RemoveAll, ev
resp = dialog_message('All items of the list will be removed. Are you sure you want this?', /question)
if resp EQ 'Yes' then begin
  list = widget_info(ev.top, find_by_uname = 'ListOfChannels')
  widget_control, list, get_uvalue = ListDescr
  ListDescr.n = 0
  ListDescr.sel = 0
  widget_control, list, set_uvalue = ListDescr
  widget_control, ev.top, update = 0
  id = widget_info(list, /child)
  while id NE 0 do begin; do for all items
    next = widget_info(id, /sibling)
    widget_control, id, /destroy
    id = next
  endwhile
  ptr_free, ptr_valid()
  call_procedure, 'Refresh', ev.top
  widget_control, ev.top, /update
endif
end

pro Save, ev
list = widget_info(ev.top, find_by_uname = 'ListOfChannels')
widget_control, list, get_uvalue = ListDescr
if ListDescr.sel EQ 0 then begin
  resp = dialog_message("There's nothing to save", /information, dialog_parent = ev.top)
  return
endif
filename = dialog_pickfile(/write, filter = '*.dat', dialog_parent = ev.top, get_path = directory)
if filename EQ '' then return
if keyword_set(directory) then cd, directory
on_ioerror, fail
catch, Err
if keyword_set(Err) then goto, fail
openw, LUN, filename, /get_LUN, /append
catch, /cancel
printf, LUN, 'Data File Created by the Program "MONOSPEC.PRO"'

list = widget_info(ev.top, find_by_uname = 'ListOfChannels')
widget_control, list, get_uvalue = ListDescr
id = widget_info(list, /child)
widget_control, id, get_uvalue = ItemDescr
task = *(ItemDescr.task)
case task.OperationName of
  'Original': printf, LUN, 'Operation: ' + 'None'
  'hoptest': printf, LUN, 'Operation: ' + 'Martanova vychytavka :=:-)'
  'Derivative': case task.MethodName of
    'PolynomialFilter': begin
      printf, LUN, 'Operation: ' +  'Derivative (using Polynomial Filtering)'
      printf, LUN, 'Order (Degree of Polynomials) :' + string(task.Param1)
      printf, LUN, 'Width of the Filter in Points :' + string(task.Param2)
      end
    'BinomialFilter': begin
      printf, LUN, 'Operation: ' + 'Derivative (using Binomial Filtered Differences)'
      printf, LUN, 'Width of the Filter in Points :' + string(task.Param2)
    end
  endcase
  'LogDeriv': case task.MethodName of
    'PolynomialFilter': begin
      printf, LUN, 'Operation: ' +  'Logarithmic Derivative (Polynomial Filtered)'
      printf, LUN, 'Order (Degree of Polynomials) :' + string(task.Param1)
      printf, LUN, 'Width of the Filter in Points :' + string(task.Param2)
      end
    'BinomialFilter': begin
      printf, LUN, 'Operation: ' + 'Logarithmic Derivative (Binomial Filtered)'
      printf, LUN, 'Width of the Filter in Points :' + string(task.Param2)
    end
  endcase
endcase

printf, LUN, 'Number of Curves :', ListDescr.sel
count = 0; pocitadlo ukladanych krivek
while id NE 0 do begin
  widget_control, id, get_uvalue = ItemDescr, get_value = name
  if ItemDescr.select then begin
    count = count + 1
    x = *(ItemDescr.x)
    y = *(ItemDescr.y)
    printf, LUN
    printf, LUN, 'Curve            : ' + string(count)
    printf, LUN, 'Source           : ' + name
    printf, LUN, 'X Unit           : ' + ItemDescr.xunit
    printf, LUN, 'Y Unit           : ' + ItemDescr.yunit
    printf, LUN, 'Number of Points : ' + string(n_elements(x))
    printf, LUN, 'Data :'
    for i = 0, n_elements(x)-1 do printf, LUN, x[i], y[i]
  endif
  id = widget_info(id, /sibling)
endwhile
free_LUN, LUN
return
fail: resp = dialog_message('Writing to file "' + filename + '" failed.', /error, $
  dialog_parent = ev.top)
end

pro SaveTiff, ev
filename = dialog_pickfile(/write, filter = '*.tiff', dialog_parent = ev.top, get_path = directory)
if filename EQ '' then return
if keyword_set(directory) then cd, directory
widget_control, widget_info(ev.top, find_by_uname = 'Win'), get_value = win
wset, win
window, xsize = !D.X_SIZE, ysize = !D.Y_SIZE, /pixmap
w = !D.WINDOW
call_procedure, 'Refresh', ev.top, win = w
wset, w
write_tiff, filename, tvrd(/order, true=1), 1
if w NE win then wdelete, w
wset, win
end

pro SaveEPS, ev
filename = dialog_pickfile(/write, filter = '*.eps', dialog_parent = ev.top, get_pat = directory)
if filename EQ '' then return
if keyword_set(directory) then cd, directory
widget_control, widget_info(ev.top, find_by_uname = 'Win'), get_value = win
wset, win
windevice = !D.NAME
set_plot, 'PS'
on_ioerror, fail
catch, Err
if keyword_set(Err) then goto, fail
device, filename = filename, /encapsulated, /color
catch, /cancel
call_procedure, 'Refresh', ev.top, /ps
device, /close_file
set_plot, windevice
wset, win
return
fail:
set_plot, windevice
wset, win
resp = dialog_message('Writing to file "' + filename + '"failed.', /error, $
  dialog_parent = ev.top)
end

pro ChangeDir, ev
dirname = dialog_pickfile(/directory, dialog_parent = ev.top, title = 'Please Select a Directory')
catch, error
if error NE 0 then goto, fail
if dirname NE '' then cd, dirname
return
fail: resp = dialog_message('No such directory exists.', /error, dialog_parent = ev.top)
end

pro Quit, ev
resp = dialog_message('Do you really want to quit the application?', /question, dialog_parent = ev.top)
if resp EQ 'Yes' then begin
  ;dealokace dynamickych promennych
  list = widget_info(ev.top, find_by_uname = 'ListOfChannels')
  id = widget_info(list, /child)
  while id NE 0 do begin
    widget_control, id, get_uvalue = ItemDescr
    ptr_free, ItemDescr.x
    ptr_free, ItemDescr.y
    ptr_free, ItemDescr.xo
    ptr_free, ItemDescr.yo
    ptr_free, ItemDescr.task
    id = widget_info(id, /sibling)
  endwhile    
  widget_control, ev.top, /destroy
endif
end

pro RemovePoints, ev
;Odstrani oznacene body
list = widget_info(ev.top, find_by_uname = 'ListOfChannels')
id = widget_info(list, /child)
while id NE 0 do begin
  widget_control, id, get_uvalue = ItemDescr
  if ItemDescr.select then begin
    ind = where(ItemDescr.PointSel, count); indexy oznacenych bodu
    if (count GT 0) then begin
      ItemDescr.PointStatus[ind] = 1; odstrani body
    endif
    widget_control, id, set_uvalue = ItemDescr
  endif
  id = widget_info(id, /sibling)
endwhile
call_procedure, 'Refresh', ev.top
end

pro RestorePoints, ev
;Obnovi vsechny odstranene body
list = widget_info(ev.top, find_by_uname = 'ListOfChannels')
id = widget_info(list, /child)
while id NE 0 do begin
  widget_control, id, get_uvalue = ItemDescr
  if ItemDescr.select then begin
    ind = where(ItemDescr.PointStatus  EQ 1, count); indexy odstranenych bodu
    if (count GT 0) then begin
      ItemDescr.PointStatus[ind] = 0; obnovi body
    endif
    widget_control, id, set_uvalue = ItemDescr
  endif
  id = widget_info(id, /sibling)
endwhile
call_procedure, 'Refresh', ev.top
end

pro SubstitutePoints, ev
;Presune oznacene body ve smeru y do prumeru jejich sousedu
list = widget_info(ev.top, find_by_uname = 'ListOfChannels')
id = widget_info(list, /child)
while id NE 0 do begin
  widget_control, id, get_uvalue = ItemDescr
  if ItemDescr.select then begin
    ind = where(ItemDescr.PointSel and (ItemDescr.PointStatus NE 1), count)
      ;indexy oznacenych bodu
    if (count GT 0) then begin
      ItemDescr.PointStatus[ind] = 2; pozadavek na presun
    endif
    widget_control, id, set_uvalue = ItemDescr
  endif
  id = widget_info(id, /sibling)
endwhile
call_procedure, 'Refresh', ev.top
end

pro OriginalPoints, ev
list = widget_info(ev.top, find_by_uname = 'ListOfChannels')
id = widget_info(list, /child)
while id NE 0 do begin
  widget_control, id, get_uvalue = ItemDescr
  if ItemDescr.select then begin
    ind = where(ItemDescr.PointSel and (ItemDescr.PointStatus NE 1), count)
      ;indexy oznacenych bodu
    if (count GT 0) then begin
      ItemDescr.PointStatus[ind] = 0; zobrazeni v puvodni poloze
    endif
    widget_control, id, set_uvalue = ItemDescr
  endif
  id = widget_info(id, /sibling)
endwhile
call_procedure, 'Refresh', ev.top
end

pro SelectSubstituted, ev
;oznaci vsechny body, presunute z puvodni polohy do prumeru svych sousedu
list = widget_info(ev.top, find_by_uname = 'ListOfChannels')
id = widget_info(list, /child)
while id NE 0 do begin
  widget_control, id, get_uvalue = ItemDescr
  if ItemDescr.select then begin
    ind = where(ItemDescr.PointStatus EQ 2, count)
      ;indexy presunutych bodu
    if (count GT 0) then begin
      ItemDescr.PointSel[ind] = 1; oznaceni bodu
    endif
    widget_control, id, set_uvalue = ItemDescr
  endif
  id = widget_info(id, /sibling)
endwhile
call_procedure, 'Refresh', ev.top
end


function ItemSelect, ev
widget_control, ev.id, get_uvalue = ItemDescr
widget_control, ev.handler, get_uvalue = ListDescr
ItemDescr.select = ev.select
ListDescr.sel = ListDescr.sel + 2 * ev.select - 1; matematicka finta (-:
;Kontrola jednotek
if ev.select then if (ListDescr.sel EQ 1) then begin
  ListDescr.xunit = ItemDescr.xou; xou = Original X-Axis Unit for the Item
  ListDescr.yunit = ItemDescr.you; you = Original Y-Axis Unit for the Item
endif else if (ListDescr.xunit NE ItemDescr.xou) or (ListDescr.yunit NE ItemDescr.you) $
then begin; nesouhlasi jednotky
  resp = dialog_message( $
    'The last selected graph has different units than the others.', $
    /error, dialog_parent = ev.top)
  widget_control, ev.id, set_button = 0
  ItemDescr.select = 0
  ListDescr.sel = Listdescr.sel - 1
endif

widget_control, ev.handler, set_uvalue = ListDescr
widget_control, ev.id, set_uvalue = ItemDescr
ev.id = ev.handler
return, ev
end

function DefineOperation, ev

;Incializace promennych urcujicich viditelnost a citlivost specialnich widgetu
DerivVis = 0
PointsMenuSens = 0

widget_control, ev.id, get_uvalue = OperationList
OperationName = OperationList[ev.index]
list = widget_info(ev.top, find_by_uname = 'ListOfChannels')
widget_control, list, get_uvalue = ListDescr
case OperationName of
  'Original': PointsMenuSens = 1
  'hoptest': PointsMenuSens = 1
  'Derivative': DerivVis = 1
  'LogDeriv': DerivVis = 1
endcase
widget_control, list, set_uvalue = ListDescr

;Realizace viditelnosti a citlivosti
widget_control, widget_info(ev.top, find_by_uname = 'DerivBase1'), map = DerivVis
widget_control, widget_info(ev.top, find_by_uname = 'DerivBase2'), map = DerivVis
widget_control, widget_info(ev.top, find_by_uname = 'PointsMenu'), $
  sensitive = PointsMenuSens

return, ev
end

function DefineDerMethod, ev
widget_control, ev.id, get_uvalue = ListOfMethods
MethodName = ListOfMethods[ev.index]
field1 = widget_info(ev.top, find_by_uname = 'DerivParam1')
field2 = widget_info(ev.top, find_by_uname = 'DerivParam2')

case MethodName of
  'PolynomialFilter': begin
    widget_control, field1, /map
    widget_control, field2, /map
    end
  'BinomialFilter': begin
    widget_control, field1, map=0
    widget_control, field2, /map
  end
endcase
end

function ClickAtWin, ev
;Osetreni udalosti, vyvolane mysi v okne.
;Typ udalosti posilane vyse je oznacen v ev.type jako retezec.
;Stisknuti tlacitka mysi se posle vyse jako typ "Pressed".
;Pri uvolneni tlacitka se rozhodne, jestli uvolneni tvori
;spolu s predchozim stisknutim obycejne kliknuti (typ "Click")
;nebo oznaceni oblasti (typ "Region").
;Souradnice poklepani se zapisi v hardwarovem systemu souradnic
;a souradnice vyberu oblasti v datovem systemu

case ev.type of
  0: begin; tlacitko stisknuto

    ;Priprava k vyberu obdelnikove oblasti
    widget_control, ev.id, get_value = win, set_uvalue = $
      {x1:ev.x, y1:ev.y, x2:ev.x, y2:ev.y, selecting:1}
      ;informace o obdelniku vymezujicim vybranou oblast
    widget_control, ev.id, /draw_motion_events

    ;Predani udalosti vyse
    xy = convert_coord(ev.x, ev.y, /device, /to_data)
    type = 'Pressed'
    return, {id:ev.id, top:ev.top, handler:0L, x:xy[0], y:xy[1], type:type}
  end

  1: begin; tlacitko uvolneno

    ;Uonceni vyberu obdelnikove oblasti a mazani posledniho obdelnika
    widget_control, ev.id, draw_motion_events = 0
    widget_control, ev.id, get_uvalue = rect, get_value = win
    rect.selecting = 0
    if (rect.x2 NE rect.x1) or (rect.y2 NE rect.y1) then begin
      wset, win
      device, set_graphics_function = 6
      plots, [rect.x1, rect.x2, rect.x2, rect.x1, rect.x1], $
             [rect.y1, rect.y1, rect.y2, rect.y2, rect.y1], /device
      device, set_graphics_function = 3
    endif
    widget_control, ev.id, set_uvalue = rect

    ;Predani udalost vyse
    if (abs(rect.x2 - rect.x1) GT 4) or (abs(rect.y1 - rect.y2) GT 4) then begin
      ;byla vybrana oblast
      p1 = convert_coord(rect.x1, rect.y1, /device, /to_data)
      p2 = convert_coord(rect.x2, rect.y2, /device, /to_data)
      type = 'Region'
      return, {id:ev.id, top:ev.top, handler:0L, x1:p1[0], y1:p1[1], x2:p2[0], y2:p2[1], type:type}
    endif else begin
      ;kliknuti na jedno misto
      xy = [rect.x1, rect.y1]
      type = 'Click'
      return, {id:ev.id, top:ev.top, handler:0L, x:xy[0], y:xy[1], type:type}
    endelse
  end

  2: begin; pohyb mysi
    widget_control, ev.id, get_uvalue = rect, get_value = win
    if rect.selecting then begin
      wset, win
      device, set_graphics_function = 6; nastaveni XOR grafiky
      if (rect.x2 NE rect.x1) or (rect.y2 NE rect.y1) then plots, $
        [rect.x1, rect.x2, rect.x2, rect.x1, rect.x1], $
        [rect.y1, rect.y1, rect.y2, rect.y2, rect.y1], /device
        ;mazani stareho obdelnika
      if (ev.x NE rect.x1) or (ev.y NE rect.y1) then plots, $
        [rect.x1, ev.x, ev.x, rect.x1, rect.x1], $
        [rect.y1, rect.y1, ev.y, ev.y, rect.y1], /device
        ;vykresleni noveho obdelnika
      rect.x2 = ev.x
      rect.y2 = ev.y
      widget_control, ev.id, set_uvalue = rect
      device, set_graphics_function = 3; obnoveni prekreslovaci grafiky
    endif
    return, 0
  end
endcase
end

pro PointSelection, TLB, x, y
;Zajisti oznaceni nebo zrusi oznaceni bodu spekter
;Vstupem je ID vrcholoveho widgetu a misto, kde bylo kliknuto,
;zadane v hardwarovych souradnicih

list = widget_info(TLB, find_by_uname = 'ListOfChannels')
id = widget_info(list, /child)
while id NE 0 do begin
  widget_control, id, get_uvalue = ItemDescr
  if ItemDescr.select then begin
    p = convert_coord(*(ItemDescr.x), *(ItemDescr.y), /data, /to_device)
    XDist = abs(p[0,*] - x); vzdalenost mezi kliknutim a body spektra ve smeru x
    YDist = abs(p[1,*] - y); vzdalenost mezi kliknutim a body spektra ve smeru y
    NotDel = ItemDescr.PointStatus NE 1; booleovske pole, urcujici neodstranene body
    ind = where((XDist LE 4) and (YDist LE 4) and NotDel, count)
      ;indexy bodu, na ktere bylo kliknuto
    if count GT 0 then ItemDescr.PointSel[ind] = 1 - ItemDescr.PointSel[ind]
    widget_control, id, set_uvalue = ItemDescr
  endif
  id = widget_info(id, /sibling)
endwhile
end


pro Refresh, TLB, win = win, ps = ps
;Prepocitani a prekresleni gafu
;TLB = ID widgetu na vrcholu hiearchie
;win = cislo okna pro vystup - pouzito jen pri presmerovani vystupu mimo okno programu
;ps = zapis do souboru (postskriptoveho) namisto do okna

list = widget_info(TLB, find_by_uname = 'ListOfChannels')
widget_control, list, get_uvalue = ListDescr
widget_control, TLB, get_uvalue = Status

;Urceni operace a numericke metody
task = GetOperation(TLB)

;Stanoveni jednotek
case task.OperationName of
  'Original': begin
     xunit = ListDescr.xunit
     yunit = ListDescr.yunit
  end
   'hoptest': begin
     xunit = 'Time [a. u.]'
     yunit = 'I [nA]'
  end
  'Derivative': begin
     xunit = ListDescr.xunit
     if ListDescr.yunit NE '' then yunit = ListDescr.yunit + ' / ' + ListDescr.xunit $
     else yunit = ''
  end
  'LogDeriv': begin
    xunit = 'Energy [eV]'
    yunit = 'dln(I)/dln(V)'
  end
endcase

;Vypocet nove podoby jednotlivych grafu
;a stanoveni meznich hodnot pro osy grafu
id = widget_info(list, /child)
s = 0; pocitalo zpracovanych polozek
while id NE 0 do begin
  widget_control, id, get_uvalue = ItemDescr
  if ItemDescr.select then begin
  ;Polozka je vybrana ke zobrazeni a je treba ji prepocitat
  OK = 1

  ;Vypocet
  xo = *(ItemDescr.xo)
  yo = *(ItemDescr.yo)
  if total(ItemDescr.PointStatus) GT 0 then begin
    ;Nektere body odstraneny nebo nahrazeny prumerem sousedu
    ind = where(ItemDescr.PointStatus NE 1, count); indexy neodstranenych bodu
    if count EQ 0 then begin
      ;pokus o odstraneni vsech bodu spektra - nepovoleno
      resp = dialog_message("You can't delete all points of a spectrum", /error, $
        dialog_parent = TLB)
      ItemDescr.PointStatus[*] = 0
      ItemDescr.PointSel[*] = 1
      ind = indgen(n_elements(xo))
    endif
    xo = xo[ind]; odstraneni
    yo = yo[ind]; odstraneni
    ind = where (ItemDescr.PointStatus EQ 2, count); indexy nahrazovanych bodu
    n = n_elements(xo)
    if (count GT 0) and (n GT 1) then begin
      NewY = 0.5 * ([yo[1:n-1],yo[n-2]] + [yo[1],yo[0:n-2]])[ind]
      yo[ind] = NewY; nahrazovani
    endif
  endif

  case task.OperationName of
     'Original': begin
      x = xo
      y = yo
      end
    'hoptest': begin
      ;x = indgen(n_elements(yo))
      ;y = yo;100000*(abs(FFT(yo)))+1.
      ;y=y(0:n_elements(y)/2)
      ;x=x(0:n_elements(yo)/2)
      end
    'Derivative': if n_elements(xo) EQ 1 then begin
      OK = 0
      errortext = 'Cannot evaluate the derivative from a single point'
    endif else case task.MethodName of
      'PolynomialFilter': begin
        order = task.Param1
        npoints = task.Param2
        if npoints mod 2 EQ 1 then x = xo else x = 0.5 * (xo + shift(xo, +1))[1:*]
        y = PolynomDeriv(xo, yo, degree = order, width = npoints, OK = OK, errortext = errortext)
        end
      'BinomialFilter': begin
        npoints = task.Param2
        x = 0.5 * (xo + shift(xo, +1))[1:*]
        y = BinomFilter(SimpleDeriv(xo, yo), width = npoints)
      end
    endcase
    'LogDeriv': if n_elements(xo) EQ 1 then begin
      OK = 0
      errortext = 'Cannot evaluate the derivative from a single point'
    endif else begin
      x = 0.5 * (xo + shift(xo, +1))[1:*]
      y = LogDeriv(xo, yo)
      case task.methodName of
        'PolynomialFilter': begin
        order = task.Param1
        npoints = task.Param2
        y = PolynomFilter(x, y, degree = order, width = npoints, OK = OK, errortext = errortext)
        if (npoints mod 2 EQ 0) then x = 0.5 * (xo + shift(xo, +1))[1:*]
        end
       'BinomialFilter': begin
        npoints = task.Param2
        y = BinomFilter(y, width = npoints)
        end
      endcase
    end
  endcase
  if not OK then begin
    resp = dialog_message(errortext, /error, dialog_parent = TLB)
    return
  endif

  ;Kopirovani vysledku
  *(ItemDescr.x) = x
  *(ItemDescr.y) = y
  ItemDescr.xunit = xunit
  ItemDescr.yunit = yunit
  *(ItemDescr.task) = task
  widget_control, id, set_uvalue = ItemDescr

  ;Stanoveni mezi
  if not Status.zoom then if s EQ 0 then begin
    minx = min(x)
    maxx = max(x)
    miny = min(y)
    maxy = max(y)
  endif else begin
    minx = minx < min(x)
    maxx = maxx > max(x)
    miny = miny < min(y)
    maxy = maxy > max(y)
  endelse
  s = s + 1

  endif
  id = widget_info(id, /sibling)
endwhile

;Stanoveni mezi grafu pri zobrazeni vyrezu
if Status.zoom then begin
  minx = Status.rect[0] < Status.rect[2]
  miny = Status.rect[1] < Status.rect[3]
  maxx = Status.rect[0] > Status.rect[2]
  maxy = Status.rect[1] > Status.rect[3]
endif

;Vyber typu grafu
grtype = widget_info(TLB, find_by_uname = 'GraphTypeMenu')
widget_control, grtype, get_uvalue = GrTypeList
GraphType = GrTypeList[widget_info(grtype, /droplist_select)]

;Nastaveni okna
if not keyword_set(ps) then begin
  if n_elements(win) EQ 0 then widget_control, widget_info(TLB, find_by_uname = 'Win'), get_value = win
  wset, win
  device, decomposed=0
endif
loadct,38

;vlastni kresleni
if ListDescr.sel EQ 0 then erase else begin
  
plot, [0], [0], /nodata, xrange = [minx, maxx], yrange = [miny, maxy], $
  xtitle = xunit, ytitle = yunit
  

symbol=1
  id = widget_info(list, /child)
  while id NE 0 do begin
    widget_control, id, get_uvalue = ItemDescr
    if ItemDescr.select then begin
      x = *(ItemDescr.x)
      y = *(ItemDescr.y)
      if (GraphType EQ 'Spline') and  (n_elements(x) GT 1) then begin
        nx = n_elements(x); pocet bodu na ose x puvodne
        mx = ((250 / (nx-1)) > 1) * (nx-1) + 1; poced bodu po zjemneni
        x = x[0] + (x[nx-1] - x[0]) / (mx-1) * indgen(mx)
        y = spline( *(ItemDescr.x), *(ItemDescr.y), x)
      endif
      if GraphType EQ 'Scatter' then psym = symbol else psym = 0

      oplot, x, y, psym = psym, color=abs(symbol*16)+6

      ;Vykresleni oznacenych bodu
      if (task.OperationName EQ 'Original') then begin
        x = *(ItemDescr.x)
        y = *(ItemDescr.y)
        ind = where((ItemDescr.PointSel EQ 1) and (ItemDescr.PointStatus NE 1), $
          count); indexy oznacenych bodu
        if count GT 0 then oplot,x[ind], y[ind], psym = symbol, color=abs(symbol*16)+6
      endif

    endif
    symbol= 1 + (symbol mod 7)
    id = widget_info(id, /sibling)
  endwhile
endelse
end

pro At_TLB_ev, ev
uname = widget_info(ev.id, /uname)
case uname of
  'ListOfChannels': update = 1
  'Win': case ev.type of
    'Pressed': update = 0
    'Region': begin
      update = 1
      widget_control, ev.handler, get_uvalue = Status
      Status.zoom = 1
      Status.rect = [ev.x1, ev.y1, ev.x2, ev.y2]
      widget_control, ev.handler, set_uvalue = Status
      if widget_info(ev.handler, find_by_uname = 'EntireScopeButton') EQ 0 then begin
        control = widget_info(ev.handler, find_by_uname = 'ControlArea')
        revertbutton = widget_button(control, value = 'Show the Whole Range', uname = $
          'EntireScopeButton')
      endif
    end
    'Click': begin
      update = 1
      if (GetOperation(ev.handler)).OperationName EQ 'Original' then $
        PointSelection, ev.handler, ev.x, ev.y
    end
  endcase
  'EntireScopeButton': begin
    update = 1
    widget_control, ev.handler, get_uvalue = Status
    Status.zoom = 0
    widget_control, ev.handler, set_uvalue = Status
    widget_control, ev.id, /destroy
  end
  'Main': begin
     update = 0
     case tag_names(ev, /structure_name) of
       'WIDGET_KILL_REQUEST': Quit, ev
       else: ;ignore
     endcase
   end
  'DerivParam1': update = 1
  'DerivParam2': update = 1
  'GraphTypeMenu': update = 1
  'OperationMenu': update = 1
  else: update = 0
endcase
if update then Refresh, ev.handler
end


pro MonoSpec
;Procedura slouzici jako hlavni program
;Umoznuje zobrazeni spekterze souboru typu *.crv (jednotliva spektra) a praci s temito spektry

loadct,12
device, decomposed = 1
main = widget_base(title = 'Analyses of single STS spectra', app_mbar = menubar, $
  /row, /tlb_kill_request_events, uname = 'Main', uvalue = {zoom:0, rect:fltarr(4)})
  ;zoom = indikuje zobrazovani vyrezu z grafu
  ;rect = souradnice vyrezu (po rade x1, y1, x2, y2)
file = widget_button(menubar, value = 'File', /menu)
add = widget_button(file, value = 'Open/Add *.crv', event_pro = 'Add', uvalue = 'crv')
addcs = widget_button(file, value = 'Open/Add *.cs', event_pro = 'Add', uvalue = 'cs?')
save = widget_button(file, value = 'Save', event_pro = 'Save')
savetiff = widget_button(file, value = 'SaveTiff', event_pro = 'SaveTiff')
saveps = widget_button(file, value = 'SaveEPS', event_pro = 'SaveEPS')
changedir = widget_button(file, value = 'Directory', event_pro = 'ChangeDir')
remove = widget_button(file, value = 'Remove', event_pro = 'Remove')
removeall = widget_button(file, value = 'RemoveAll', event_pro = 'RemoveAll')
quit = widget_button(file, value = 'Quit', /separator, event_pro = 'Quit')
points = widget_button(menubar, value = 'Points', /menu, uname = 'PointsMenu')
rm = widget_button(points, value = 'RemoveSelected', $
  event_pro = 'RemovePoints')
rest = widget_button(points, value = 'RestoreRemoved', $
  event_pro = 'RestorePoints')
subst = widget_button(points, value = 'MeanOfNeighbours', $
  event_pro = 'SubstitutePoints', /separator)
orig = widget_button(points, value = 'OriginalValues', $
  event_pro = 'OriginalPoints')
sm = widget_button(points, value = 'SelectMoved', $
  event_pro = 'SelectSubstituted')
leftside = widget_base(main, /column, frame=0)
rightside = widget_base(main, /column, frame=0)
win = widget_draw(leftside, xsize = 600, ysize = 400, uname = 'Win', /button_events, $
  event_func = 'ClickAtWin', uvalue = {x1:0, y1:0, x2:0, y2:0, selecting:0})
control = widget_base(leftside, /row, uname = 'ControlArea')
menus = widget_base(control, /column)
OperationList = ['Original', 'Derivative', 'LogDeriv','hoptest']
omenu = widget_droplist(menus, title = 'Display', /dynamic_resize, $
  event_func = 'DefineOperation', uname = 'OperationMenu', $
  value = OperationList, uvalue = OperationList)
GraphTypeList = ['Scatter', 'Line', 'Spline']
grtype = widget_droplist(menus, title = 'Graph  ', /dynamic_resize, $
  value = GraphTypelist, uvalue = GraphTypeList, uname = 'GraphTypeMenu')

;Definice specialnich widgetu, viditelnych jen v nekterych pripadech
derivbase1 = widget_base(menus, /column, uname = 'DerivBase1', map = 0)
derivbase2 = widget_base(control, /column, uname = 'DerivBase2', map = 0)
ListOfMethods = ['PolynomialFilter', 'BinomialFilter']
derivmethod = widget_droplist(derivbase1, title = 'Method', /dynamic_resize, $
  value = ListOfMethods, uvalue = ListOfMethods, $
  event_func = 'DefineDerMethod', uname = 'DerivMethod')
derivfield1 = CW_field(derivbase2, title = 'Method Order:', /column, /integer, $
  value = 1, /return_events, uname = 'DerivParam1')
derivfield2 = CW_field(derivbase2, title = 'Filter Width in Points:', /column, /integer, $
  value = 3, /return_events, uname = 'DerivParam2')

;Seznam souboru (kanalu)
listheader = widget_label(rightside, value = 'List of files:')
ListDescr = {n:0, sel:0, xunit:'', yunit:''}
  ;n = pocet vsech polozek seznamu
  ;sel = pocet oznacenych polozek
  ;xunit = oznaceni jednotky na ose x
  ;yunit = oznaceni jednotky na ose y
list = widget_base(rightside, /nonexclusive, uvalue = ListDescr, $
  uname = 'ListOfChannels', event_func = 'ItemSelect')

widget_control, main, /realize
xmanager, 'MonoSpec', main, event_handler = 'At_TLB_ev'
end
