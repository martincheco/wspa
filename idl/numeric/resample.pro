function resample,x,y,splines,newxs
;provides sampling a curve and resampling again using spline interpolation
;x,y - coordinates (can be in principle irregularly distributed)
;splines - number of splines
;newxs - coordinates for resampling


xf=x
yf=y

a=sort(xf)
xf=xf(a)
yf=yf(a)

nn=n_elements(xf)
xh=xf(round(findgen(splines)*nn/splines))
yh=yf(round(findgen(splines)*nn/splines))

y2 = SPL_INIT(xh, yh)
if keyword_set(newxs) then xx=newxs else xx=x
ys=SPL_INTERP(xh,yh,y2,xx)

return, ys
end
