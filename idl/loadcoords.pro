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


function loadcoords, filename, OK = OK
;nacita ze souboru typu *.cs0 souradnice krivek
;vraci pole x=FLTARR(i,2), i je pocet krivek
;x(k,0) je Xova souradnice krivky k
;y(k,1) je Yova souradnice krivky k

x=fltarr(100,2)

;otevirani souboru s detekci chyby
catch, error
if keyword_set (error) then begin
  OK = 0
  print, !ERROR_STATE.MSG_PREFIX + 'loadcoords: Unable to open file "' + filename + '"'
  return, 0
endif
openr, LUN, filename, /get_LUN
catch, /cancel

line = ''
i=0
while not(ContainsStr(line, 'BEGIN COORD') or eof(LUN)) do line = readln(LUN)
while not(ContainsStr(line, 'END COORD') or eof(LUN)) do begin    
line = readln(LUN)
if not (EmptyStr(line) or ContainsStr(line, 'END COORD')) then $ 
  begin
    reads, line, a, b
    x[i, 0] = a
    x[i, 1] = b
    i=i+1
  endif
endwhile

y=0
if i ne 0 then $
  begin
  y=fltarr(i,2)
  y(0:i-1,*)=x(0:i-1,*)
  OK = 1
end $
  else OK = 0
free_LUN, LUN
return, y
end
