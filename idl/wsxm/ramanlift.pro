function ramanlift_stitch,spa,spb,wva,wvb,index,lamb=lamb
;stiches spectra from 2 together in a map

if mean(wva) lt mean(wvb) then begin
wv1=wva
wv2=wvb
sp1=spa
sp2=spb
end else begin
wv2=wva
wv1=wvb
sp2=spa
sp1=spb
end

wv=wv1(index)

d=abs(wv2-wv)

w=where(d eq min(d))

ii=w(0)

help,ii

sp=[sp1(0:index-1),sp2(ii:-1)]
lamb=[wv1(0:index-1),wv2(ii:-1)]

return,sp
end




function medfilter,m,dry=dry,tol=tol
mm=m
s=size(mm)

if keyword_Set(dry) then coef=0. else coef=1.
if not(keyword_Set(tol)) then tol=.5

for i=0,s(2)-1 do begin

	med=min(mm(*,i))
	w=where(mm(*,i)-med gt (tol)*med)
	if w(0) ne -1 then begin
		mm(w,i)=0.
		avg=total(mm(*,i),/double)/(s(1)-n_elements(w))
		mm(w,i)=coef*avg
	end
end

return,mm
end


function ramanlift_read,f,didv=didv,ivmask=ivmask,fmask=fmask,stitch=stitch
;reads series of Raman maps and didvs according to the mask, gets other channels as well
;fmask - if specified, finds files according to the mask
;didv - try to read didvs
;ivmask - if specified, finds files according to the mask
;stitch - stitch two spectra used to make one, number specifies the index of wavelength of the 1st spectrum where to join the spectra

if not(keyword_set(stitch)) then nstitch=1 else  nstitch=2

print,"Raman spectra filenames:" 
if keyword_set(fmask) then f=getfiles(mask=fmask) else if not(keyword_set(f)) then f=dialog_pickfile(/multi,/must_exist)
print,"dI/dV spectra filenames:"
if keyword_set(didv) then if keyword_set(ivmask) then fi=getfiles(mask=ivmask) else fi=dialog_pickfile(/multi,/must_exist)
n=n_elements(f)

if keyword_set(didv) then begin 
	ni=n_elements(fi)
	if n ne ni*nstitch then begin
		print,'Number of spectra not matching'
		return,-1
	end
end else begin
	didv=-1
	bias=-1
end



z=dblarr(n)
v=z ;bias
ii=z ;current
l=z ;laser power


a=loadnanonis_sts(f(0))
m=n_elements(a.data(0,*))
ncols=n_elements(a.data(*,0))
map=fltarr(n,m)
wv=map

for i=0,n-1 do begin
	a=loadnanonis_sts(f(i))
	
	mmap=a.data(2:-1,*)
	mmap=medfilter(mmap,tol=0.5) 
	map(i,*)=reform(total(mmap,1,/double)/ncols)
	wv(i,*)=reform(a.data(0,*))
	z(i)=a.p.z
	v(i)=a.p.bias
	curr=getval(a.p.par,'Current avg.')
	curr=strsplit(curr,/extract)
	ii(i)=double(curr(1))
	laser=getval(a.p.par,'Laser pow')
	laser=strsplit(laser,/extract)
	l(i)=double(laser(1))

end


if keyword_set(stitch) then begin
	i=0
	sp=ramanlift_stitch(map(i*2,*),map(i*2+1,*),wv(i*2,*),wv(i*2+1,*),stitch,lamb=lamb)
	nmap=dblarr(n/2,n_elements(sp))
	lmb=nmap
	for i=0,n/2-1 do lmb(i,*)=lamb

	for i=0,n/2-1 do nmap(i,*)=ramanlift_stitch(map(i*2,*),map(i*2+1,*),wv(i*2,*),wv(i*2+1,*),stitch,lamb=lamb)

	wv=lmb
	ii=ii(indgen(n/2)*2)
	z=z(indgen(n/2)*2)
	v=v(indgen(n/2)*2)
	l=l(indgen(n/2)*2)
end else nmap=map


if didv ne -1 then begin
	b=loadnanonis_sts(fi(0))
	
	ax=b.data(where(b.chans eq 'Bias (V)'))
	bias=reform(b.data(ax,*))
	sig=(where(b.chans eq 'LI Demod 1 Y (A)'))
	nn=n_elements(b.data(sig,*))

	didv=dblarr(ni,nn)

	for i=0,ni-1 do begin
		b=loadnanonis_sts(fi(i))
		;plot,b.data(sig,*)
		didv(i,*)=b.data(sig,*)
	end


end	


return,{map:nmap,wv:wv,didv:didv,z:z,ii:ii,v:v,l:l,f:f,bias:bias}
end




pro ramanlift_vis,rr,nlev=nlev,gm=gm,didv=didv,rng=rng,bias=bias
;indow,0,xs=960,ys=960
r=rr
if keyword_set(rng) then begin

	
map=rr.map(rng(0):rng(1),*)
wv=rr.wv(rng(0):rng(1),*)
z=rr.z(rng(0):rng(1))
ii=rr.ii(rng(0):rng(1))
v=rr.v(rng(0):rng(1))
l=rr.l(rng(0):rng(1))
if rr.didv(0) ne -1 then didv=rr.didv(rng(0):rng(1),*) else didv=-1

r={map:map,wv:wv,didv:didv,z:z,ii:ii,v:v,l:l,f:rr.f,bias:rr.bias}
end

help,r

s=size(r.map)
m=s(1)
n=s(2)
if not(keyword_set(gm)) then gm=1.

;loadct,1

;mmap=r.map-smooth(r.map,10,/edge_wrap)
mmap=(r.map-min(r.map))
!p.charsize=1.0
!p.multi=[0,1,2]
!p.color=0
!p.background=255

tck=REPLICATE(' ', N)

mmap=(1.01*max(mmap)-mmap)^gm

contour,(mmap),indgen(m),-1e7/reform(r.wv(0,*))+1e7/632.8,/fill,nlevels=nlev,xst=1,yst=1,ytit='Wavenumber [1/cm]',xmargin=[8,1],ymargin=[0,1],xtickname=tck,title='Raman intensity map'

!p.multi=[4,1,8]
!p.charsize=1.25/0.6
!p.symsize=0.5


goldpalette,/pure
help,r.didv
if r.didv(0) ne -1 then begin
	didv=double(r.didv)
	didv=max(didv)-didv
	contour,(((didv^(1./gm)))),indgen(m),1e3*r.bias,/fill,nlevels=nlev,xst=1,yst=1,ytit='Bias [mV]',xmargin=[8,1],ymargin=[0,1],xtickname=tck,title='dI/dV map'


	for i=0,m-1 do didv(i,*)=bytscl(r.didv(i,*))+1;-min(r.didv(i,*))

	;didv=didv-median(didv)
	didv=266-didv
	contour,(((didv^(1.)))),indgen(m),1e3*r.bias,/fill,nlevels=nlev,xst=1,yst=1,ytit='Bias [mV]',xmargin=[8,1],ymargin=[0,1],xtickname=tck,title='dI/dV Normalized map'

end else begin
	plot,r.v*1000,yst=1,xst=1,ytit='V [mV]',xmargin=[8,1],ymargin=[0,1],xtickname=tck,psym=-3,title='Applied bias voltage'
	oplot,r.v*1000,psym=4,color=100
end



loadct,1


plot,r.ii*1e9,yst=1,xst=1,ytit='Current [nA]',xmargin=[8,1],ymargin=[0,1],xtickname=tck,psym=-3,title='Tunneling current at low bias'
oplot,r.ii*1e9,psym=4,color=100

plot,(r.z-min(r.z))*1e12,yst=1,xst=1,ytit='Z_rel [pm]',xmargin=[8,1],ymargin=[0,1],xtickname=tck,psym=-3,title='Lifting height'
oplot,(r.z-min(r.z))*1e12,psym=4,color=100



;plot,r.l*1e6,yst=1,xst=1,ytit='Laser [a.u.]',xmargin=[8,1],ymargin=[2,0],psym=-3
;oplot,r.l*1e6,color=100,psym=4




!P.Multi = 0
   !P.Charsize = 0


end


pro ramanlift_vis_eps,rr,nlev=nlev,gm=gm,didv=didv,rng=rng
r=rr

 set_plot,'ps'
    device,/encapsul,/color,filename='overview.eps',xsize=13,ysize=30

;window,0,xs=960,ys=960

if keyword_set(rng) then begin

	
map=rr.map(rng(0):rng(1),*)
wv=rr.wv(rng(0):rng(1),*)
z=rr.z(rng(0):rng(1))
ii=rr.ii(rng(0):rng(1))
v=rr.v(rng(0):rng(1))
l=rr.l(rng(0):rng(1))
if rr.didv(0) ne -1 then didv=rr.didv(rng(0):rng(1),*) else didv=-1

r={map:map,wv:wv,didv:didv,z:z,ii:ii,v:v,l:l,f:rr.f,bias:rr.bias}
end

help,r

s=size(r.map)
m=s(1)
n=s(2)
if not(keyword_set(gm)) then gm=1.

loadct,1

;mmap=r.map-smooth(r.map,10,/edge_wrap)
mmap=(r.map-min(r.map))
!p.charsize=1.0
!p.multi=[0,1,2]
!p.color=0
!p.background=255

tck=REPLICATE(' ', N)

mmap=(1.01*max(mmap)-mmap)^gm

contour,(mmap),indgen(m),-1e7/reform(r.wv(0,*))+1e7/632.8,/fill,nlevels=nlev,xst=1,yst=1,ytit='Wavenumber [1/cm]',xmargin=[8,1],ymargin=[0,1],xtickname=tck,title='Raman intensity map'

!p.multi=[4,1,8]
!p.charsize=1.25/0.6
!p.symsize=0.5


goldpalette,/pure
help,r.didv
help,r.bias
if r.didv(0) ne -1 and r.bias(0) ne -1 then begin
	didv=double(r.didv)
	didv=max(didv)-didv
	contour,(((didv^(1./gm)))),indgen(m),1e3*r.bias,/fill,nlevels=nlev,xst=1,yst=1,ytit='Bias [mV]',xmargin=[8,1],ymargin=[0,1],xtickname=tck,title='dI/dV map'


	for i=0,m-1 do didv(i,*)=bytscl(r.didv(i,*))+1;-min(r.didv(i,*))

	;didv=didv-median(didv)
	didv=266-didv
	contour,(((didv^(1.)))),indgen(m),1e3*r.bias,/fill,nlevels=nlev,xst=1,yst=1,ytit='Bias [mV]',xmargin=[8,1],ymargin=[0,1],xtickname=tck,title='dI/dV Normalized map'

end else begin
	plot,r.v*1000,yst=1,xst=1,ytit='V [mV]',xmargin=[8,1],ymargin=[0,1],xtickname=tck,psym=-3,title='Applied bias voltage'
	oplot,r.v*1000,psym=4,color=100
end


loadct,1


plot,r.ii*1e9,yst=1,xst=1,ytit='Current [nA]',xmargin=[8,1],ymargin=[0,1],xtickname=tck,psym=-3,title='Tunneling current at low bias'
oplot,r.ii*1e9,psym=4,color=100

plot,(r.z-min(r.z))*1e12,yst=1,xst=1,ytit='Z_rel [pm]',xmargin=[8,1],ymargin=[0,1],xtickname=tck,psym=-3,title='Lifting height'
oplot,(r.z-min(r.z))*1e12,psym=4,color=100



;plot,r.l*1e6,yst=1,xst=1,ytit='Laser [a.u.]',xmargin=[8,1],ymargin=[2,0],psym=-3
;oplot,r.l*1e6,color=100,psym=4




!P.Multi = 0
   !P.Charsize = 0

    device,/close
    set_plot,'X'

end




pro ramanlift_vis_plot,rr,rng=rng,offs=offs,skip=skip,xrng=xrng

r=rr
if not(keyword_set(offs)) then offs=0.
if not(keyword_set(skip)) then skip=1L
if keyword_set(rng) then begin
	map=rr.map(rng(0):rng(1),*)
	wv=rr.wv(rng(0):rng(1),*)
	z=rr.z(rng(0):rng(1))
	ii=rr.ii(rng(0):rng(1))
	if r.v(0) ne -1 then v=rr.v(rng(0):rng(1))
	if r.l(0) ne -1 then l=rr.l(rng(0):rng(1))
	if r.didv(0) ne -1 then didv=rr.didv(rng(0):rng(1),*)
	r={map:map,wv:wv,didv:didv,z:z,ii:ii,v:v,l:l,f:rr.f,bias:rr.bias}
end

if keyword_set(xrng) then begin
	
	d1=abs(nm2cm(r.wv(0,*),exc=632.8) - xrng(0))
	d2=abs(nm2cm(r.wv(0,*),exc=632.8) - xrng(1))
	w1=where(d1 eq min(d1))
	w2=where(d2 eq min(d2))
	help,w1
	help,w2
	print,w1(0),w2(0)
	ar=(w1(0))
	br=(w2(0))
	help,ar
	help,br

	map=r.map(*,ar:br)
	wv=r.wv(*,ar:br)
	r={map:map,wv:wv,didv:r.didv,z:r.z,ii:r.ii,v:r.v,l:r.l,f:r.f,bias:r.bias}
end



help,r

s=size(r.map)
m=s(1)
n=s(2)

mmap=(r.map-min(r.map))
!p.charsize=1.0
!p.color=0
!p.background=255
mx=max(mmap)
mn=min(mmap)


plot,1e7/632.8-1e7/r.wv(0,*),mmap(0,*),xst=1,psym=-3,yrange=[-0.1*mx,mx+((m)/skip)*offs],/nodata,xtit='Raman shift [1/cm]',YTICKFORMAT="(A1)",xmargin=[1,1],yst=1,yticks=1,yminor=1,xticklen=0.008,xtickinterval=20,xminor=4
for i=0,m-1,skip do oplot,1e7/632.8-1e7/r.wv(i,*),mmap(i,*)+float(i/skip)*offs
for i=0,m-1,skip do oplot,1e7/632.8-1e7/r.wv(i,*),mean(mmap(i,0:10))+0*mmap(i,*)+float(i/skip)*offs





;plot,r.l*1e6,yst=1,xst=1,ytit='Laser [a.u.]',xmargin=[8,1],ymargin=[2,0],psym=-3
;oplot,r.l*1e6,color=100,psym=4




!P.Multi = 0
   !P.Charsize = 0


end


