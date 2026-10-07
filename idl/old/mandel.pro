pro mandel,xRange,yRange,RESULT=res

;device,PSEUDO_COLOR=8,DECOMPOSED=0

if n_elements( xRange) eq 0 then xRange = [ -1.0, 2.3]
if n_elements( yRange) eq 0 then yRange = [ -1.3, 1.3]

iter = 255

xS = 16000
yS = 12000

xD = float(xRange[1]-xRange[0])
yD = float(yRange[1]-yRange[0])

xStep = xD / xS
yStep = yD / yS

xStartVec = lindgen( xS) * xStep + xRange[0]
yStartVec = lindgen( yS) * yStep + yRange[0]

constArr = complex( rebin( xStartVec, xS, yS),$
rebin( transpose(yStartVec), xS, yS))

valArr = complexarr( xS, yS)

res = intarr( xS, yS)

oriIndex = lindgen( long(xS) * yS)

for i = 0, iter-1 do begin

print,i

valArr = valArr^2 - constArr

whereIn = where( abs( valArr) le 4.0d, COMPLEMENT=whereOut)

if whereIn[0] eq -1 then break

valArr = valArr[ whereIn]
constArr = constArr[ whereIn]

if whereOut[0] ne -1 then begin

res[ oriIndex[ whereOut]] = i+1

oriIndex = oriIndex[ whereIn]
endif
endfor

loadct,15

tv,res

end
