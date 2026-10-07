function PolynomFilter, y, degree = degree, width = width, x = x, OK = OK
;Provede polynomialni filtraci navzorkovane zavislosti y(x)
;degree = rad aproximujicich polynomu
;width = sirka filtru (pocet bodu, z nichz se vypocitava aproximujici polynom)
;OK = vypocet probehl bezchybne
;Pokud je pocet bodu pro vypocet polynomu lichy, vraci funkce hodnoty derivace v bodech x,
;je-li sudy, vraci hodnoty v bodech lezicih vzdy mezi x[i] a x[i+1], techto bodu je vzdy o jeden mene nez bodu x
;Lze take zadat jen hodnoty y, hodnoty nezavisle promene pak budou zvoleny x = [0, 1, 2,...]

;Pouze pro jednorozmerna data!

OK = 1
if not keyword_set(y) then begin
  OK = 0
  return, 0
endif
n = n_elements(y)
if not keyword_set(x) then x = indgen(n)
if n_elements(x) NE n_elements(y) then begin
  OK = 0
  print, 'WARNING: Vectors x and y should have the same size.'
  if n_elements(x) GT n_elements(y) then begin
    x = x[0:n-1]
    print, 'Vector x truncated to ',n,' elements.'
    print
  endif else begin
    n = n_elements(x)
    y = y[0:n-1]
    print, 'Vector y truncated to ',n,' elements.'
    print
  endelse
endif
if not keyword_set(degree) then degree = 0 else degree = fix(abs(degree))
if not keyword_set(width) then width = degree + 1 else width = fix(abs(width))
if (width GT n) then begin
  OK = 0
  print, 'WARNING: Filter width should not exceed the total number of points.'
  width = n
  print, 'Width reduced to ',width,'.'
  print
endif
if degree GE width then  begin
  OK = 0
  print, 'WARNING: The degree should be smmaller than the filter width.'
  degree = width - 1
  print, 'Degree reduced to ',degree,' to avoid underdetermined problem.'
  print
endif

if (width mod 2) EQ 1 then begin
  fy = fltarr(n)
  for i = 0, n - 1 do begin
    leftmost = ((i - width / 2) > 0 ) < (n - width)
    rightmost = leftmost + width -1
    fy[i] = (PolynomApprox(x[leftmost:rightmost], y[leftmost:rightmost], $
      xo = x[i], degree = degree))[0]
  endfor
endif else begin
  fy = fltarr(n-1)
  for i = 0, n - 2 do begin
    leftmost = ((i + 1 - width / 2) > 0) < (n - width)
    rightmost = leftmost + width - 1
      fy[i] = (PolynomApprox(x[leftmost:rightmost], y[leftmost:rightmost], $
      xo = (x[i]+x[i+1])/2.0, degree = degree))[0]
  endfor
endelse
return, fy
end
