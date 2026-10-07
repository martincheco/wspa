
;Vyhlazovaci filtry pro obrazky i spektra
;a dalsi numericke procedury a funkce


function sgn,x
return, abs(x)/x
end

function Dispersion, x
;vypocet disperze prvku pole
n = n_elements(x)
;print,'Using: Dispersion'
return, total((x - total(x) / n)^2) / n
end


function PseudoInverse, A
;provede (pseudo)inverzi matice metodou singularni dekomozice
SVDC, A, w, U, V
eps = (abs(max(w)) > abs(min(w))) * 1E-7 > 1E-37
n = n_elements(w)
SV = fltarr(n, n)
for i = 0, n - 1 do SV[i, i] = (w[i] GE eps)? (1.0 / w[i]): 0

;print,'Using: PseudoInverse'
return, V ## SV ## transpose(U)
end


function SimpleDeriv, y, OK = OK, x = x
;Vypocet numericke derivace pomoci prostych diferenci
;y(x) = puvodni funkce
;Bod vysledku o indexu 0 odpovida bodu uprostred mezi indexy 0 a 1 v zadani
;Celkem je vysledny vektor o jeden bod kratsi nez vektor vstupni
;Lze take zadat jen hodnoty y, hodnoty nezavisle promene pak budou zvoleny x = [0, 1, 2,...]

n = n_elements(y) - 1
if not keyword_set(x) then x = indgen(n+1)
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
d = float((shift(y, -1) - y)[0:n-1])

;print,'Using: SimpleDeriv'
return, d / ((shift(x, -1) - x)[0:n-1])
end


function LogDeriv, x, y, OK = OK
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


function Grad, img, edge_truncate = edge_truncate
;vypocet gradientu dvourozmerneho pole
;/edge_truncate = derivace na njkrajnejsich bodech pole se nepocitaji,
;zkopiruji se hodnoty sousedni

if size(img, /n_dimensions) NE 2 then begin
  message, 'The parameter must be a 2D-array', /continue
  return, img
endif
xs = (size(img))[1]
ys = (size(img))[2]
if (xs LT 2 ) or (ys LT 2) then begin
  message, "The array's size must be at least 2 in both dimensions", /continue
  return, img
endif
gx = (shift(img, -1, 0) - shift(img, +1, 0)) / 2.0
gy = (shift(img, 0, -1) - shift(img, +1, 0)) / 2.0
if not keyword_set(edge_truncate) then begin
  gx[0, *] = (img[1, *] - img[0, *]) / 1.0
  gx[xs-1, *] = (img[xs-1, *] - img[xs-2, *]) / 1.0
  gy[*, 0] = (img[*, 1] - img[*, 0]) / 1.0
  gy[*, ys-1] = (img[*, ys-1] - img[*, ys-2]) / 1.0
endif else begin
  gx[0, *] = gx[1, *]
  gx[xs-1, *] = gx[xs-2, *]
  gy[0, *] = gy[1, *]
  gy[*, ys-1] = gy[*, ys-2]
endelse

;print,'Using: Grad'
return, sqrt(gx^2 + gy^2)
end


function SubtractPlane, img, const = const, slopex = slopex, slopey = slopey
;Prolozi obrazkem rovinu a vraci obrazek vznikly po odecteni teto roviny
;img = puvodni data (obrazek)
;const = konstantni slozka (prumerna hodnota pres cely obrazek)
;slopex = sklon ve smeru osy x
;slopey = sklon ve smeru osy y
;Jsou-li zadany perametry odecitane roviny pomoci pojmenovanych parametru const, slopex, slopey
;rovina se odecte okamzite, jinak se parametry pocitaji
;a pripadne ulozi do promennych prirazenych pojmenovanym parametrum

m=(size(img))[1]
n=(size(img))[2]
stairsx=(indgen(m)-float(m-1)/2) # replicate(1,n)
stairsy=(indgen(n)-float(n-1)/2) ## replicate(1,m)
if not keyword_set(const) then const = total(img)/(m*n)
if not keyword_set(slopex) then slopex = total((img-const)*stairsx) / ((1/12.0)*n*m*(m-1)*(m+1))
if not keyword_set(slopey) then slopey = total((img-const)*stairsy) / ((1/12.0)*m*n*(n-1)*(n+1))

;print,'Using: SubtractPlane'
return, img - const - stairsx*slopex - stairsy*slopey
end


function SubtractShifts, img
;Pokud obrazek sestava z pasovych nebo ctvercovych oblasti,
;oddelenych navzajem urovnovymi skoky, 
;funkce tyto oblasti najde a potlaci je 
;odectenim ruznych konstant od ruznych oblasti. 
;Vraci upraveny obrazek

nx = (size(img, /dimensions))[0]
ny = (size(img, /dimensions))[1]

if nx GT 1 then begin
  profx = (total(img, 2)) / ny
  difx = (profx - shift(profx, 1))[1:*]; skoky ve smeru x
  stepsx = intarr(nx-1); indikator vyznamneho skoku ve smeru x
  ;Hledani vyznamnych skoku ve smeru x
  sqrerr = (difx - mean(difx))^2
  msqr = mean(sqrerr)
  ind = where(sqrerr GT (4 * msqr), count)
  if count GT 0 then stepsx[ind] = 1
  corrx = [0, total(stepsx * difx, /cumulative)]
endif

if ny GT 1 then begin
  profy = (total(img, 1)) / nx
  dify = (profy - shift(profy, 1))[1:*]; skoky ve smeru y
  stepsy = intarr(ny-1); indikator vyznamneho skoku ve smeru y
  ;Hledani vyznamnych skoku ve smeru y
  sqrerr = (dify - mean(dify))^2
  msqr = mean(sqrerr)
  ind = where(sqrerr GT (4 * msqr), count)
  if count GT 0 then stepsy[ind] = 1
  corry = [0, total(stepsy * dify, /cumulative)]
endif

res = img - corrx # replicate(1, ny) - replicate(1, nx) # corry

;print,'Using: SubtractShifts'
return, res - mean(res)
end


function Norm, x, y, eps = eps
;Normuje zadanou funkci y(x) tak, ze
;1. Pokud je soucasti definicniho oboru x = 0, pricte k funkci konstantu tak, aby nova funkce prochazela pocatkem
;2. Vydeli funkci kladnou konstantou tak, aby stredni kvadraticky rozptyl funkcnich hodnot byl jednotkovy

;Nejsou-li zadany hodnoty {x}, zvoli se x = 0, 1, ...
;eps = minimalni hodnota stredni kvadraticke odchylky, pri ktere se jeste provadi normovani

n = n_elements(x)
if n_elements(y) EQ 0 then begin
  y = x
  x = indgen(n)
endif else if n_elements(x) NE n_elements(y) then begin
  message, 'Vectors x and y must have the same size', /continue
  return, 0
endif 

;Posunuti
if (min(x) LT 0) and (max(x) GT 0) then begin
  ind = sort(abs(x))
  a = ind[0]
  b = ind[1]
  y0 = (y[a] * x[b] - y[b] * x[a]) / float(x[b] - x[a])
endif else y0 = 0.0
;Disperze
ampl = sqrt(Dispersion(y))
if keyword_set(eps) then if ampl LT abs(eps) then ampl = 1.0

;print,'Using: Norm'
return, (y - y0) / ampl
end

;Funkce pro filtraci a derivaci provedenou v jedinem bode spktra, 
;zato vsak pro cele dvourozmerne pole spekter
;(pro vypocet tzv. spektralnich map)


function SpMap_BDerivative, y, i, width = width, OK = OK
;Binomialne vyhlazena derivace spekter pro spektralni mapy
;y = pole puvodnich spekter (trojrozmerne pole, prvni dva indexy udavaji spektrum, treti oznacuje spektralni bod ve spektru)
;i = index spektralniho bodu, v nemz se ma provest vypocet
;width = sirka filtru
;OK = indikator bezchybneho prubehu

if not keyword_set(width) then width= 3 else width = abs(fix(width))
if size(y, /n_dimensions) NE 3 then begin
  OK = 0
  message, 'Wrong number of dimensions of the input array, 3D-array recquired', /continue
  return, 0
endif
nx = (size(y))[1]
ny = (size(y))[2]
n = (size(y))[3]
if (i LT 0) or (i GE n - 1 + (width mod 2)) then begin
  OK = 0
  message, 'Index' + strcompress(string(i)) + ' is out of range', /continue
  return, total(y, 3)
endif else if (width LT 2) or (n LT 2) then begin
  OK = 0
  message, 'At least 2 points needed to evaluate the derivative', /continue
  return, 0
endif
OK = 1
;generovani binomialni masky
ker = fltarr(width)
ker[0] = 1
for j = 2, width - 1 do ker = (ker + shift(ker, 1)) / 2
ker = shift(ker, 1) - ker
;konvoluce dat a masky
dy = fltarr(nx, ny)
for j = 0, width - 1 do begin
  ind = 0 > (i - (width-1) / 2 + j) < (n-1)
  dy = dy + ker[j] * y[*, *, ind]
endfor

;print,'Using: SpMap_BDerivative'
return, dy
end


function SpMap_BFilter, y, i, width = width, OK = OK
;Binomialni filtr pro spektralni mapy
;y = pole puvodnich spekter (trojrozmerne pole, prvni dva indexy udavaji spektrum, treti oznacuje spektralni bod ve spektru)
;i = index spektralniho bodu, v nemz se ma provest vypocet
;width = sirka filtru
;OK = indikator bezchybneho prubehu

if not keyword_set(width) then width= 3 else width = abs(fix(width))
if size(y, /n_dimensions) NE 3 then begin
  OK = 0
  message, 'Wrong number of dimensions of the input array, 3D-array recquired', /continue
  return, 0
endif
nx = (size(y))[1]
ny = (size(y))[2]
n = (size(y))[3]
if (i LT 0) or (i GE n - 1 + (width mod 2)) then begin
  OK = 0
  message, 'Index' + strcompress(string(i)) + ' is out of range', /continue
  return, total(y, 3)
endif
OK = 1
;generovani binomialni masky
ker = fltarr(width)
ker[0] = 1
for j = 2, width do ker = (ker + shift(ker, 1)) / 2
;konvoluce dat a masky
fy = fltarr(nx, ny)
for j = 0, width - 1 do begin
  ind = 0 > (i - (width-1) / 2 + j) < (n-1)
  fy = fy + ker[j] * y[*, *, ind]
endfor

;print,'Using: SpMap_BFilter'
return, fy
end


function SpMap_PDerivative, y, i, degree = degree, width = width, x = x, OK = OK
;Derivace pro spektralni mapy pomoci aproximujicich poynomu
;x = vektor nezavisle promenne
;y = pole funkcnich hodnot (zavislost na tretim indexu odpovida zavislosti na x)
;i = index spektralniho bodu, v nemz se ma provest vypocet
;degree = rad aproximujicich polynomu
;width = pocet bodu, z nichz se vypocitavaji polynomy
;OK = vypocet probehl bezchybne

if (size(y, /n_dimensions) NE 3) then begin
  OK = 0
  message, 'Wrong number of dimensions of the input array, 3D-array recquired', /continue
  return, 0
endif
nx = (size(y))[1]
ny = (size(y))[2]
n = (size(y))[3]
if not keyword_set(x) then x = indgen(n)
if not n_elements(x) EQ n then begin
  OK = 0
  message, 'The sizes of x and y are uncompatible', /continue
  return, 0
endif
if not keyword_set(degree) then degree = 1 else degree = fix(degree)
if not keyword_set(width) then width = degree + 1 else width = fix(abs(width))
if (i LT 0) or (i GE n - 1 + (width mod 2)) then begin
  OK = 0
  message, 'Index' + strcompress(string(i)) + ' is out of range', /continue
  return, total(y, 3)
endif
if degree LT 1 then begin
  OK = 0
  errortext = 'Polynomial degree must be at least 1'
  message, errortext, /continue
  return, 0
endif
if degree GE width then  begin
  OK = 0
  errortext = 'The degree of a polynomial must be lesser than the number of used points'
  message, errortext, /continue
  return, 0
endif
if (width LT 2) or (n LT width) then begin
  OK = 0
  errortext = 'Not enough points used to do the computation'
  message, errortext, /continue
  return, 0
endif
OK = 1
;generovani derivujici masky
leftmost = 0 > (i - (width-1) / 2) < (n - width)
rightmost = leftmost + width - 1
if (width mod 2) EQ 1 then xo = x[i] else xo = (x[i]+x[i+1])/2.0
A = fltarr(degree + 1, width)
for j = 0, degree do A[j, *] = (x[leftmost:rightmost] - xo)^j
ker = (PseudoInverse(A))[*, 1]
;konvoluce s maskou
dy = fltarr(nx, ny)
for j = 0, width - 1 do begin
  ind = 0 > (i - (width-1) / 2 + j) < (n-1)
  dy = dy + ker[j] * y[*, *, ind]
endfor

;print,'Using: SpMap_PDerivative'
return, dy
end


function SpMap_PFilter, y, i, degree = degree, width = width, x = x, OK = OK
;Polynomialni filtr pro spektralni mapy
;x = vektor nezavisle promenne
;y = pole funkcnich hodnot (zavislost na tretim indexu odpovida zavislosti na x)
;i = index spektralniho bodu, v nemz se ma provest vypocet
;degree = rad aproximujicich polynomu
;width = pocet bodu, z nichz se vypocitavaji polynomy
;OK = vypocet probehl bezchybne

if (size(y, /n_dimensions) NE 3) then begin
  OK = 0
  message, 'Wrong number of dimensions of the input array, 3D-array recquired', /continue
  return, 0
endif
nx = (size(y))[1]
ny = (size(y))[2]
n = (size(y))[3]
if not keyword_set(x) then x = indgen(n)
if not n_elements(x) EQ n then begin
  OK = 0
  message, 'The sizes of x and y are uncompatible', /continue
  return, 0
endif
if not keyword_set(degree) then degree = 0 else degree = fix(degree)
if not keyword_set(width) then width = degree + 1 else width = fix(abs(width))
if (i LT 0) or (i GE n - 1 + (width mod 2)) then begin
  OK = 0
  message, 'Index' + strcompress(string(i)) + ' is out of range', /continue
  return, total(y, 3)
endif
if degree LT 0 then begin
  OK = 0
  errortext = 'Polynomial degree must be positive'
  message, errortext, /continue
  return, 0
endif
if degree GE width then  begin
  OK = 0
  errortext = 'The degree of a polynomial must be lesser than the number of used points'
  message, errortext, /continue
  return, 0
endif
if (width LT 1) or (n LT width) then begin
  OK = 0
  errortext = 'Not enough points used to do the computation'
  message, errortext, /continue
  return, 0
endif
OK = 1
if width EQ 1 then return, y[*, *, i]
;generovani vyhlazujici masky
leftmost = 0 > (i - (width-1) / 2) < (n - width)
rightmost = leftmost + width - 1
if (width mod 2) EQ 1 then xo = x[i] else xo = (x[i]+x[i+1])/2.0
A = fltarr(degree + 1, width)
for j = 0, degree do A[j, *] = (x[leftmost:rightmost] - xo)^j
ker = (PseudoInverse(A))[*, 0]
;konvoluce s maskou
fy = fltarr(nx, ny)
for j = 0, width - 1 do begin
  ind = 0 > (i - (width-1) / 2 + j) < (n-1)
  fy = fy + ker[j] * y[*, *, ind]
endfor
return, fy
end


function GetRegion, condition, x, y

cond = abs(condition) mod 2
if size(condition, /n_dimensions) NE 2 then begin
  message, 'The first parameter must be a 2D boolean array', /continue
  return, cond
endif
xsize = (size(condition))[1]
ysize = (size(condition))[2]
if (x LT 0) or (y LT 0) or (x GE xsize) or (y GE ysize) then begin
  message, 'Coordinates out of range', /continue
  return, cond
endif
result = intarr(xsize, ysize)
if cond[x, y] EQ 1 then begin
 indices = search2D(cond, x, y, 1, 1)
 result[indices] = 1
endif

;print,'Using: SpMap_PFilter'
return, result
end


;Rozvrzeni barevne skaly

pro TvScale, img, mincolor = mincolor, maxcolor = maxcolor, win = win
;nakresli obrazek tak, aby byla plne vyuzita zadana skala barev
;mincolor = nejmensi dovolene cislo barvy
;maxcolor = nejvetsi dovolene cislo barvy
;win = cislo okna, do ktereho se bude kreslit

if not keyword_set(mincolor) then mincolor = 0
if not keyword_set(maxcolor) then maxcolor = !D.table_size-1
if keyword_set(win) then wset, win
minvalue = float(min(img, max = maxvalue))
maxvalue = float(maxvalue)
if minvalue EQ maxvalue then tv, int2B(img * 0) else $
tv, int2B((mincolor*(maxvalue-img) + maxcolor*(img-minvalue)) / (maxvalue-minvalue))

;print,'Using: TvScale'
end


function TvScaled, img, mincolor = mincolor, maxcolor = maxcolor
;preskaluje barvy v zadanem obrazku stejne jako procedura TvScale
;na rozdil od TvScale obrazek nekresli, ale vraci jako funkcni hodnotu
;mincolor = nejmensi dovolene cislo barvy
;maxcolor = nejvetsi dovolene cislo barvy

if not keyword_set(mincolor) then mincolor = 0
if not keyword_set(maxcolor) then maxcolor = !D.table_size-1
minvalue = float(min(img, max = maxvalue))
maxvalue = float(maxvalue)
if minvalue EQ maxvalue then return, int2B(img * 0)
return, int2B((mincolor*(maxvalue-img) + maxcolor*(img-minvalue)) / (maxvalue-minvalue))

;print,'Using: TvScaled:numeric.pro'
end
