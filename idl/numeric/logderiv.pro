function logderiv, x, y, OK = OK
;Vypocet logaritmicke derivace pomoci prostych diferenci
;Puvodni funkce se automaticky vertikalne posouva tak, aby prochazela pocatkem
;Velikost nutneho posuvu je vyuzita jako numericka konstanta, modifikujici vzorec
;pro derivaci tak, aby nedochazelo k divergenci
;Bod vysledku o indexu 0 odpovida bodu uprostred mezi indexy 0 a 1 v zadani
;Celkem je vysledny vektor o jeden bod kratsi nez vektor vstupni
;y(x) = puvodni funkce

n = n_elements(x) - 1
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

;print,'Using: LogDeriv'
return, ly
end
