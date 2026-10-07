function PolynomApprox, x, y, xo = xo, degree = degree, OK = OK
;Provede polynomialni aproximaci n-tice bodu [x, y] (x, y jsou n-tice cisel)
;a vraci koeficienty a[k] aproximujiciho polynomu.
;Cleny polynomu se predpokladaji ve tvaru a[k]*(x-xo)^k
;Neni-li xo zadano, predpoklada se nulove
;degree = stupen approximujiciho polynomu (nejvyssi)

OK = 1
if not n_elements(x) EQ n_elements(y) then begin
  OK = 0
  print, 'WARNING: Vectors x and y should have the same size.'
  if (n_elements(x) LT n_elements(y)) then begin
    n = n_elements(x)
    y = y[0:n-1]
    print, 'Vector x truncated to ',n,' elements to comply with y.'
    print
  endif else begin
    n = n_elements(y)
    x = x[0:n-1]
    print, 'Vector y truncated to ',n,' elements to comply with x.'
    print
  endelse
endif else begin
  n = n_elements(x)
endelse
if not keyword_set(xo) then xo = 0.0
if n_elements(degree) EQ 0 then degree = n - 1 else begin
  degree = abs(fix(degree))
  if degree GE n then begin
    OK = 0
    print, 'WARNING: The degree of polynomial should be smaller than the number of points.'
    degree = n - 1
    print, 'Degree reduced to',n,'.'  
    print
  endif
endelse
if degree EQ 0 then return, total(y) / n
;generovani matice soustavy
A = fltarr(degree + 1, n)
for i = 0, degree do A[i, *] = (x - xo)^i
SVDC, A, W, U, V
koef = SVSol(U, W, V, y)
return, koef
end
