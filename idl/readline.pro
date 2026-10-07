function ReadLine, LUN, comment=comment
;precte prvni neprazdny radek ze souboru s cislem LUN
;ignoruje nadbytecne mezery (na zacatku, na konci a vicenasobne)
;ignoruje komentar, t.j. cast radku za strednikem, pokud neni pritomen prepinac comment
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
  semicol = strpos(line, ';')
  if not(keyword_set(comment)) then if semicol GE 0 then line = strmid(line, 0, semicol)
  line = strcompress(strtrim(line, 2))
endrep until (eof(LUN)) or (strlen(line) GT 0)
return, line
end
