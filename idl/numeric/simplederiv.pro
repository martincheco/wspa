function simplederiv, x, y, OK = OK
;vypocet derivace
;y(x) = puvodni funkce
;Bod vysledku o indexu 0 odpovida bodu uprostred mezi indexy 0 a 1 v zadani
;Celkem je vysledny vektor o jeden bod kratsi nez vektor vstupni
;Lze take zadat jen hodnoty y, hodnoty nezavisle promene pak budou zvoleny x = [0, 1, 2,...]
;help,x
;help,y

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
