function Content, files, OK=OK, directory=directory, compress=compress, ParentID=ParentID
;Vraci obsah textoveho souboru jako pole retezcovych promennych
;Kazda polozka pole predstavuje jeden radek
;file = jmeno textoveho souboru
;OK = priznak bezchybneho (OK=1) otevreni souboru
;/compress = vynechavat prazdne radky a pocatecni a koncove mezery radku
;ParentID = identifikacni cislo volajiciho widgetu, je-li funkce pouzita ve widgetove aplikaci

if not keyword_set(files) then $
  files = dialog_pickfile(/read, /must_exist, path=directory, get_path=directory, $
  dialog_parent=ParentID, /multiple)
if (size(files, /n_dimensions) EQ 0) then files = [files]
if not keyword_set(files[0]) then begin
  OK = 0
  return, ''
endif

s = ''
c = 0B
line = ''
nl = 0
nc = 0
OK = 1
eoln = -1
for i = 0, n_elements(files)-1 do begin

  ;Opening file
  file = files[i]
  catch, ErrOpen
  if keyword_set(ErrOpen) then begin
    OK = 0
    message, 'Cannot open file "', file, '".', /continue
  endif else begin
    openr, LUN, file, /get_lun
  endelse
  catch, /cancel

  while not eof(LUN) do begin
    readu, LUN, c
    if (eoln LT 0) then if (c EQ 13) or (c EQ 10) then eoln = c
    if (c EQ eoln) then begin
      ;End of line reached
      if keyword_set(compress) then line = strcompress(strtrim(line, 2))
      if keyword_set(line) or (not keyword_set(compress)) then begin
        if (nl EQ 0) then s = [line] else s = [s, line]
        nl = nl + 1
        line = ''
      endif
    endif else if (c NE 13) and (c NE 10) then begin
      ;A character read
      line = line + string(c)
      nc = nc + 1
    endif
  endwhile

  if keyword_set(line) then begin
    ;Last line in a file
    if (nl EQ 0) then s = [line] else s = [s, line]
    nl = nl + 1
    line = ''
  endif

  free_LUN, LUN
endfor
return, s
end
