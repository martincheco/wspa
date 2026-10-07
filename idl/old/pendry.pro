function pendry,en,x,y,width=width, splines=splines,show=show

;x,y are input vectors to calculate pendry R-factor, 
;vectors have to be positive, above one
;ref: G. Ertl, J. Kueppers - Low Energy Electrons and Surface Chemistry 
;ISBN 3-527-26056-0, equation 9.68
;vectors can be smoothed first, if these parameters of the filter are set:
;fwidth=width of the sav.-gol. filter
;splines=number of points to use for the resampling
;the filter uses savitzky-golay filter, interpolation by splines 
;and finally resampling

x=reform(x)
y=reform(y)

nx=n_elements(x)
ny=n_elements(y)
nen=n_elements(en)

;print,nx,ny,nen

;sanity check
if (nx ne ny or nen ne nx or ny ne nen) or (min(x) le 1) or (min(y) le 1) then begin
;print, "vectors do not fit the input conditions"
return, -1
end

;derivating
fx=double(x)
fy=double(y)
if keyword_set(width) then begin

if keyword_set(splines) then begin
fx=dezofilter(en, fx, width=width, splines=splines)>2
fy=dezofilter(en, fy, width=width, splines=splines)>2
end else begin
print,'only savgol'
fx=dezofilter(en, fx, width=width,/savg)>2
fy=dezofilter(en, fy, width=width,/savg)>2
end


end

dlnIx=double(Simplederiv(en,alog(fx)))
dlnIy=double(Simplederiv(en,alog(fy)))

;help,dlnIx
;help,dlnIy

;plot,dlnIx
;oplot,dlnIy,color=150

if keyword_set(show) then begin
plot,en,x,psym=7
oplot,en,y,psym=7,color=150
oplot,en,fx,thick=2
oplot,en,fy,color=150,thick=2
end

;upper integral
ru=total((dlnIx-dlnIy)^2)
;lower integral
rl=total(dlnIx^2+dlnIy^2)

;help,rl
;help,ru

return, ru/rl
end