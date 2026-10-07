pro mltplot3d,basei=basei,alti=alti,rng=rng


whch=[1,8,5,6,7]

g=getfiles(mask='Bias*.dat')
a=loadnanonis_sts(g(0))
tt=sts_toarea(g)

t=tt
;window,1,xsize=600,ysize=1024
n=n_elements(whch)


s=size(t)
if not(keyword_set(basei)) then basei=0
if not(keyword_set(alti)) then alti=3
if not(keyword_set(rng)) then rng=[0,s(2)-1]
help,rng
rng=indgen(rng(1)-rng(0)+1)+rng(0)

print,s
xx=reform(t(basei,*,*))
;xx=findgen(s(1))

un=getunit(a.chans(basei))
xx=axred(xx,un)
xttl=replunit(a.chans(basei),un)

zz=reform(t(alti,*,*))

zun=getunit(a.chans(alti))
zz=(zz-min(zz))
print,max(zz),min(zz)
zz=axred(zz,zun)
zttl=replunit(a.chans(alti),zun)


for i=0,n-1 do begin

	set_plot,'ps'
	Device, DECOMPOSED=0, COLOR=1, BITS_PER_PIXEL=8
	device, filename='test_plot_3d'+string(i,format='(I02)')+'.ps'
	device,XSIZE=4, YSIZE=3, /INCHES
	device,/encapsulated
	device,xoffset=0


	yun=getunit(a.chans(whch(i)))
	yy=reform(axred(t(whch(i),*,*),yun))
	yttl=replunit(a.chans(whch(i)),yun)



	xmx=max(xx(rng,*))
	xmn=min(xx(rng,*))
	ymn=min(yy(rng,*))
	ymx=max(yy(rng,*))
	zmn=min(zz(rng,*))
	zmx=max(zz(rng,*))
	loadct,0
	surface,dist(10),xtit=xttl,ytit=zttl,ztit=yttl,$
		xst=1,yst=1,xrange=[xmn,xmx],yrange=[zmn,zmx],zrange=[ymn,ymx],charsize=1.2,color=0,/nodata,/save,az=180-30,ax=20,zst=3,xmargin=[12,3],ymargin=[12,3],zmargin=[12,3]
	loadct,13
	for j=rng(0),rng(-1)-1 do begin
		plots,xx(j,*),zz(j,*),yy(j,*),color=255*j/s(2),/t3d
	end

	device,/close
end
set_plot,'x'
end


pro mltplot3d_2,rng=rng


whch=[1,8,5,6,7]

g=getfiles(mask='*.dat')
a=loadnanonis_sts(g(0))
tt=sts_toarea(g)
help,tt
t=tt
;window,1,xsize=600,ysize=1024
n=n_elements(whch)


s=size(t)

if not(keyword_set(rng)) then rng=[0,s(3)-1]
rng=indgen(rng(1)-rng(0)+1)+rng(0)

print,s
;xx=reform(t(basei,*,*))
x=-2.*findgen(s(2))/s(2)+1.
xx=mreplicate(x,s(3))
un='V';getunit(a.chans(basei))
;xx=axred(xx,un)
xttl='Bias (V)'

zz=reform(t(0,*,*))

zun=getunit(a.chans(3))
zz=axred(zz,zun)
zttl=replunit(a.chans(3),zun)
zz=(zz-min(zz))



for i=0,n-1 do begin

	set_plot,'ps'
	Device, DECOMPOSED=0, COLOR=1, BITS_PER_PIXEL=8
	device, filename='test_plot_3d'+string(i,format='(I02)')+'.ps'
	device,XSIZE=4, YSIZE=3, /INCHES
	device,/encapsulated
	device,xoffset=0


	yun=getunit(a.chans(whch(i)))
	yy=reform(axred(t(whch(i),*,*),yun))
	yttl=replunit(a.chans(whch(i)),yun)

help,xx
help,yy
help,zz

	xmx=max(xx(*,rng))
	xmn=min(xx(*,rng))
	ymn=min(yy(*,rng))
	ymx=max(yy(*,rng))
	zmn=min(zz(*,rng))
	zmx=max(zz(*,rng))
	loadct,0
	surface,dist(10),xtit=xttl,ytit=zttl,ztit=yttl,$
		xst=1,yst=1,xrange=[xmn,xmx],yrange=[zmn,zmx],zrange=[ymn,ymx],charsize=1.2,color=0,/nodata,/save,az=180-30,ax=20,zst=3,xmargin=[12,3],ymargin=[12,3],zmargin=[12,3]
	loadct,13
	for j=0,s(2)-1 do begin
		plots,reform(xx(j,rng)),reform(zz(j,rng)),reform(yy(j,rng)),color=255*j/s(2),/t3d
	end

	device,/close
end
set_plot,'x'
end
