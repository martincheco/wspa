function dezofilter,x,y, width = width, splines=splines,savg=savg,newxs=newxs
;splines = number of splines used in the approximation
;returns data smoothed by Savitzky-Golay, resampled and reconstructed by cubic splines
;width = filter carrier width
;/savg = switches off the splines and resampling
;newxs = defines points for resampling

x=reform(x)
y=reform(y)

if not keyword_set(splines) then splines = 20 else splines=fix(splines)

if not keyword_set(width) then width = 30 else width = fix(width)
;print,"width",width
width=abs(width)
if width gt n_elements(x) then message, 'Filter width should be smaller than the no. of data points', /continue
;filter generation
filter = savgol(width,width,0,2)
;help,filter
;help,x
;help,y
;filtr vytvoren
n = n_elements(x)
yf = convol(y, filter, /edge_truncate)

if keyword_set(savg) then begin
;print,"Savgol filter only"
return,yf
end

xf=x

nn=n_elements(xf)
xh=xf(round(findgen(splines)*nn/splines))
yh=yf(round(findgen(splines)*nn/splines))

y2 = SPL_INIT(xh, yh)
if keyword_set(newxs) then xx=newxs else xx=x
ys=SPL_INTERP(xh,yh,y2,xx)

return, ys
end
