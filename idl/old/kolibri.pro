function read_frq,f,refoff=refoff
dt=read_ascii(f,data_start=12)
help,dt.(0)(*,0:10),/struct
if keyword_set(refoff) then $
return,{f:dt.(0)(0,*),a:dt.(0)(2,*),ph:dt.(0)(3,*),ref:dt.(0)(1,*)} $
else $
return,{f:dt.(0)(0,*)+dt.(0)(1,*),a:dt.(0)(2,*),ph:dt.(0)(3,*),ref:dt.(0)(1,*)}
end

pro multiplot,yrng=yrng,xrng=xrng,fref=fref
device,decomposed=0
loadct,12
f=dialog_pickfile(/must_exist,/multi)
sp0=read_frq(f(0),/refoff)
print,sp0.ref(0)
plot,sp0.f,sp0.ph,xst=3,yst=3,color=255,xrange=xrng,yrang=yrng

for i=1,n_elements(f)-1 do begin
	sp=read_frq(f(i),/refoff)
	if keyword_set(fref) then oplot,sp.f+sp.ref-sp0.ref,sp.ph,color=i*16*2+10 $
	else $
	oplot,sp.f,sp.a,color=i*16*2+10
	print,sp.ref(0)
end
tt=tvrd(0,true=1)
t=dialog_pickfile()
write_png,t,tt
end
