function antibunch,nn,n,t0,t1,t2,jitter,sav=sav
device,decomposed=0
loadct,0
window,1,xs=640,ys=320
n=long(n)


stp=fix(1000./n^0.5)
htot=0L

for j=0,nn-1 do begin

	pt1=-alog(randomu(seed,n,/double))*t1
	pt0=-alog(randomu(seed,n,/double))*t0
	pt2=-alog(randomu(seed,n,/double))*t2
	pt3=(randomn(seed,n,/double))*jitter

	T=dblarr(n)

	for i=0L,n-1 do begin
		T(i)=T(i-1)+pt0(i-1)+pt3(i-1)+pt1(i-1)+pt2(i-1)
			
	end

	ta=mreplicate(T,n)
	dt=ta-transpose(ta)

	for i=0,n-1 do dt(i,i)=99999.

	h=histogram(dt,min=-5.,max=5.,nbins=202.)

;	h=histogram(pt1+pt2+pt3,max=10.,nbins=100,locations=loc)

	if j gt 0 then ht=ht+h else ht=h
	htot+=total(h)
	if j mod stp eq 0 then begin
		plot,0.05*(findgen(202)-100.),ht,xst=1,yst=1,background=255,color=0,yrange=[0,max(ht)]
		print,j,htot

	end

end


	plot,0.05*(findgen(202)-100.),ht,xst=1,yst=1,background=255,color=0,yrange=[0,max(ht)],/nodata
	oplot,0.05*(findgen(202)-100.),ht,color=50,thick=2.0

	if keyword_set(sav) then begin
		a=tvrd(0)
		t0s=string(t0,format='(F08.3)')
		t1s=string(t1,format='(F08.3)')
		t2s=string(t2,format='(F08.3)')
		jits=string(jitter,format='(F08.3)')
		write_png,'g2_'+t0s+'_'+t1s+'_'+t2s+'_'+jits+'.png',a
	end

return,ht

end
