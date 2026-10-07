pro afm_iter,parset,y,v
F=-parset.k*y
a=F/parset.m
v+=a*parset.dt
;v=v*(1D - parset.dmp*parset.dt)
y+=v*parset.dt
end


pro afm,iters,overlap

parset={m:1D,k:1D,dt:1D-3,dmp:0.1D}
y=0D
v=1D/1D
yy=dblarr(iters)
yy(0)=y
ph=dblarr(iters)
for i=1L,(iters)-1 do begin
	
	if y lt overlap then begin
		parset.k=2D
		tr=1D 
	end else begin
		parset.k=1D 
		tr=0D
	end
	yd=y
	afm_iter,parset,y,v
	yy(i)=y
	ph(i)=tr
end



plot,parset.dt*dindgen(iters)/2/!PI,yy,yrange=[-1,1]
oplot,parset.dt*dindgen(iters)/2/!PI,ph/4


end


pro afm_stepsim
for i=0,100 do begin
	over=(2*double(i)/100D)-1
	print,over
	afm,50000L,over
end
end
