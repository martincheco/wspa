function ReadLine, LUN
;precte prvni neprazdny radek ze souboru s cislem LUN
;ignoruje nadbytecne mezery (na zacatku, na konci a vicenasobne)
;ignoruje komentar, t.j. cast radku za strednikem
;radek obsahujici pouze komentar se povazuje za prazdny
;navratovou hodnotou funkce je precteny radek
;jsou-li do konce souboru vsechny radky prazdne, vraci prazdny retezec

line = ''
repeat begin
  c = 0B
  while (not eof(LUN)) and (c NE 10) and (c NE 13) do begin
    readu, LUN, c
    if (c NE 10) and (c NE 13) then line = line + string(c)
  endwhile

;this is a tweak to get the matrix id number into the comment
  mtxpos = strpos(line, '; Original run/scan cycle identification:')
  if mtxpos GE 0 then line = strmid(line, 2)
  if mtxpos GE 0 then print,"matrix id found!"
  semicol = strpos(line, ';')
  if semicol GE 0 then line = strmid(line, 0, semicol)
  line = strcompress(strtrim(line, 2))
endrep until (eof(LUN)) or (strlen(line) GT 0)
return, line
end
