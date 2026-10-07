function resmpl,pfl,pts,xrange=xrange
;resamples a XY curve using number of points (pts) and step (stp)
;xrange rescales x also

s=sort(pfl.r)
x=pfl.r(s)
y=pfl.z(s)

;mnx=x(0)
;mxx=x(n_elements(x))

;newx=(mxx-mnx)*findgen(pts)/pts+mnx

newx=INTERPOL(x,pts)
newy=INTERPOL(y,pts)

if keyword_set(xrange) then begin
;	newx=newx-min(newx)
	newx=newx*xrange/(max(newx)-min(newx))
print,max(newx),min(newx)
end

return,{r:newx,z:newy}
end

pro resmpl,pts,xrange=xrange
f=dialog_pickfile(/must_exist)
pfl=read_profile(f)
plot,pfl.r,pfl.z,psym=-1
npfl=resmpl(pfl,pts,xrange=xrange)
oplot,npfl.r,npfl.z,psym=-1,color=128
save_profile,f+'.r',npfl
end