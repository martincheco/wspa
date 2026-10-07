function ExtremesExcluded, y, crit = crit
;Orizne hodnoty ve vektoru (poli) y tak, aby jejich odchylka od prumeru
;nebyla vetsi, nez zadany faktor (crit) krat standardni odchylka
;y = vektor (pole) puvodnich hodnot
;crit = faktor pred standardni odchylkou (implicitne 2)
;print,"Using: ExtremesExcluded.pro:b!'

n = n_elements(y)
if n GT 1 then begin
  if not keyword_set(crit) then crit = 2 else crit = abs(crit)
  c2 = crit^2
  used = replicate(1, n)
  ny = n; pocet hodnot pouzivanych ke statistice 
  repeat begin
    my = total(y * used) / ny; prumer
    d2 = ((y - my) * used)^2; ctverece odchylek
    s2 = total(d2) / (ny - 1); ctverec standardni odchylky
    fits = (d2 LE (c2 * s2)) mod 2
    used = used * fits
    ny0 = ny
    ny = total(used)
  endrep until (ny EQ ny0) or  (ny LE 1)
  if ny EQ 1 then begin
    my = total(y * used)
    s2 = 0.0
  endif
  y1 = y
  s = sqrt(s2)
  upmost = my + crit * s
  downmost = my - crit * s
  over = where(y GT upmost, count)
  if count GT 0 then y1[over] = upmost
  under = where(y LT downmost, count)
  if count GT 0 then y1[under] = downmost
  return, y1
endif else return, y
end
