function Truncate, img, k, avr = useavr
;V zadanem dvourozmernem poli orizne ty hodnoty, jejichz odchylka od prumeru
;osmi sousednich hodnot previsuje k-nasobek stredni kvadraticke odchylky techto
;osmi hodnot od sveho prumeru.
;Funkce vraci pole s oriznutymi hodnotami
;k = parametr urcujici kriterium oriznuti (bere se 3 pokud neuveden)
;img =zadane pole
;/avr = hodnoty urcene k oriznuti se namisto prosteho oriznuti nahradi prumerem sousednich hodnot
;print,'Using: truncate.pro'
if not keyword_set(k) then k = 3 else k = abs(k)
mask = [[1, 1, 1], [1, 0, 1], [1, 1, 1]]
n = total(mask)
  ;maska, ktera po konvoluci s polem dava soucet osmi nejblizsich sousedu kazdeno prvku
arr = float(img)
avr = convol(arr, mask, /edge_truncate) / n
disp = convol(arr^2, mask, /edge_truncate) / n - avr^2
dif = (arr - avr)^2
w = where(dif GT k * disp, count)
if count GT 0 then begin
  if keyword_set(useavr) then begin
    arr[w] = avr[w]
  endif else begin
    maxdif = sqrt(k * disp[w])
    arr[w] = (avr[w] - maxdif) >  arr[w] < (avr[w] + maxdif)
  endelse
endif
return, arr
end
