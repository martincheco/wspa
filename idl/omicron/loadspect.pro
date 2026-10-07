function LoadSpect, filename, xsize, ysize, points, OK = OK
;Funkce LoadSpect precte pole spekter ze spektroskopickeho souboru
;filename = jmeno souboru vcetne pripony
;xsize = pocet spekter na radek
;ysize = pocet radku se spektry
;points = pocet bodu ve spektru
;OK = pri cteni nedoslo k zadne chybe

spc = intarr(xsize, ysize, points)
if filename EQ '' then begin
  OK = 0
  return, spc
endif
catch, ErrOpening
if keyword_set(ErrOpening) then begin
  OK = 0
  print, !ERROR_STATE.MSG_PREFIX + 'In loadspect: Unable to open file "' + filename + '"'
  return, spc
endif
openr, LUN, filename, /swap_if_little_endian, /get_LUN
catch, /cancel
OK = 1
on_ioerror, failed
readu, LUN, spc
free_LUN, LUN
return, spc
failed: OK = 0
print, !ERROR_STATE.MSG_PREFIX + 'In loadspect: Unsuccessful attempt to read spectra'
if keyword_set(LUN) then free_LUN, LUN
return, spc
end
