function LoadTopo, filename, xsize, ysize, OK = OK
;Funkce LoadTopo precte obrazek z topografickeho souboru
;filename = jmeno souboru vcetne pripony
;xsize = pocet bodu ve smeru X (pocet bodu na radek)
;ysize = pocet bodu ve smeru Y (pocet radku)
;OK = pri cteni nedoslo k zadne chybe

img = intarr(xsize, ysize)
if filename EQ '' then begin
  OK = 0
  return, img
endif
catch, ErrOpening
if keyword_set(ErrOpening) then begin
  OK = 0
  print, !ERROR_STATE.MSG_PREFIX + 'loadtopo: Unable to open file "' + filename + '"'
  return, img
endif
openr, LUN, filename, /swap_if_little_endian, /get_LUN
catch, /cancel
OK = 1
on_ioerror, failed
readu, LUN, img
free_LUN, LUN
return, img
failed: OK = 0
print, !ERROR_STATE.MSG_PREFIX + 'Unsuccessful attempt to read an image'
if keyword_set(LUN) then free_LUN, LUN
return, img
end
