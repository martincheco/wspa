function toat_exp
t=xsf_read('/home/martin/tmp/TOAT/EXP/CO_cube.mat.xsf')
help,t,/st
t=t.data(*,*,*)
s=size(t)
t=congrid(t,s(1),s(2)*2,s(3)*2)
expb=t
expb=toat_df2f(t,fit=67,/noconv)
return,expb(0:3,*,*)

end

function toat_zscale,th
s=size(th)
return,congrid(th,s(1)*2./7.,s(2),s(3))
end


function toat_th,at=at,dirnm=dirnm,subset=subset
ang=0.
zm=1.
drs=getfiles('/home/martin/tmp/TOAT/TH/Xe-flat/',/dirs)
if keyword_set(subset) then drs=drs(subset)
n=n_elements(drs)

dirnm=drs
thp=ptrarr(n)
print,drs
for i=0,n-1 do begin
	th=xsf_read(drs(i)+'OutFz.xsf')
	help,th,/st
	th=th.data(*,0:-20,*)
	s=size(th)
	th=giessibl(reverse(1.60217*1e-9*th,1),n=50,dz=2e-12,k=1800.,f0=25634,/ext)
	th=toat_zscale(th(0:100,*,*))
;	th=th(12:32,*,*)
;	th=repstack(th,6,2)
;	th=repstack(th,5,3)
;	th=rot3d(th,ang);64.2121
;	th=register_zoom(th,zm);0.667
;	help,th
;	th=reverse(th,2)
;	if i eq 0 then $
;		ht=ptcda_crop({a:th,b:th,r:0,vect:0,mhat:0},coords=[0,-1,203,-97,66,-51],at=at) 
;	th=th(*,203:-97,66:-51)
	thp(i)=ptr_new(th)
end


return,thp
end

function toat_regis,exp,th,step=step,at=at,init=init
n=n_elements(th)
cors=dblarr(n)
zs=cors
ccs=cors
thn=ptrarr(n)
;if not(keyword_set(init)) then init=[1,-83.6,0.,6.,11.]
;if not(keyword_set(step)) then step=[0.1,0.5,0.,0.,0.]

for i=0,n-1 do begin
	thx=*th(i)
	res=register_iter(thx,exp,init(0),init(1),init(2),init(3),init(4),/vis,step=step,/norot)
	thn(i)=ptr_new(res)

end

if keyword_set(at) then begin
	th0=*th(0)
	res0=*thn(0)
	s=size(th0)
	resv=res0.vect
	pxl=abs(vector(at.e,at.x,at.y))/s(2)
	;help,resv
	xd=fix(resv(3))
	yd=fix(resv(4))
	at.xy=at.xy+pxl*complex(xd,yd)

end

return,thn
end

function toat_eval,thr,dump=dump,xsf=xsf,at=at,dirnm=dirnm
n=n_elements(thr)
cors=dblarr(n)
zs=cors
ccs=cors
s=size((*thr(0)).a)
ovlps=dblarr(n,s(1))
thn=ptrarr(n)
window,0,xs=500,ys=500
for i=0,n-1 do begin
	res=*thr(i)
	if keyword_set(dirnm) then dr=file_basename(dirnm(i)) else dr=strtrim(string(i,format='(I04)'),2)
	file_mkdir,dr
	cd,dr
	if keyword_set(dump) then register_dump,res
	cors(i)=res.r
	zs(i)=res.vect(2)
	w=where(finite(res.a*res.b))
	ccs(i)=total(res.a(w)*res.b(w),/double)/total(res.a(w)^2,/double)
	register_corr,res,cc=cc,reg=reg,ovlp=ovlp,dep=dump
	pearson=correlate(res.a(w),res.b(w),/double)
;	help,ovlp
;	ovlps(i,*)=ovlp
	a=tvrd(0,true=1)
	write_png,'a_overview.png',reverse(a,3)
;	wc=where(finite(cc))
;	if wc(0) ne -1 then begin
;		plot,wc,cc(wc),psym=1,xrange=[min((wc))-0.5,max((wc))+0.5],xtitle="Slice",ytitle="Correlation",back=255,color=0
;		a=tvrd(0,true=1)
;		write_png,'a_correlation.png',reverse(a,3)
;		plot,wc,reg(0,wc),psym=1,xrange=[min((wc))-0.5,max((wc))+0.5],xtitle="Slice",ytitle="Offset",back=255,color=0

;		a=tvrd(0,true=1)
;		write_png,'a_offset.png',reverse(a,3)
;		plot,wc,reg(1,wc),psym=1,xrange=[min((wc))-0.5,max((wc))+0.5],xtitle="Slice",ytitle="Slope",back=255,color=0

;		a=tvrd(0,true=1)
;		write_png,'a_slope.png',reverse(a,3)
;	end
	openw,1,'params.txt'
	printf,1,'Similarity factor: ',res.r
	printf,1,'Pearson:',pearson
	printf,1,'Zoom, Rot, dz, dx, dy:',res.vect
	close,1
	if keyword_set(xsf) then begin
		xsf_write,'df_th.xsf',res.a
		xsf_write,'df_exp.xsf',res.b
	end
cd,'..'
end
return,{zs:zs,ccs:ccs,cors:cors,ovlps:ovlps}
end

pro toat_funct,x,a,f
	f=a(0)-a(1)/((a(2)*x-a(3))^2)

end

function toat_funct,x,a
	toat_funct,x,a,f
return,f
end

function toat_df2f,exx,noconv=noconv,fit=fit,filt=filt,c=c
;fits and subtracts background
;converts to F if not banned by noconv
;filt filters the stack
;
s=size(exx)

if not(keyword_set(fit)) then fit=0
nyb=total(total(exx,3),2)/s(2)/s(3)
nxb=dindgen(n_elements(nyb))

if not(keyword_set(c)) then begin
	c=[0.1,200.,.02,-20.]
	yfit=curvefit(nxb(fit:-1),nyb(fit:-1),undef,c,function_name='toat_funct',/noderivative,/double,status=status)
;print,status
	plot,nxb,nyb
	print,c
end
plnm=toat_funct(nxb,c)
oplot,nxb,plnm

if keyword_set(filt) then ex=stackfilt(exx,10) else ex=exx

nexp=exx

if keyword_set(fit) then begin
	nexp=nexp-mreplicate(mreplicate(plnm,s(2)),s(3))
end
;f2f
if keyword_set(noconv) then res=nexp else res=giessibl(nexp,n=14,dz=5e-12,k=5e5,f0=1e6)

return,res
end



function toat_crop,reg,at=at,coords=coords
nreg=register_autocrop(reg,coords=coords)
;print,'coords:',coords
if keyword_set(at) then begin
	s=(size(reg.a))
	;print,s
	x1=double((coords(2)+0.5)/s(2)*abs(vector(at.e,at.x,at.y)))
	x2=double((coords(3)+0.5)/s(2)*abs(vector(at.e,at.x,at.y)))
	y1=double((coords(4)+0.5)/s(3)*abs(vector(at.f,at.x,at.y)))
	y2=double((coords(5)+0.5)/s(3)*abs(vector(at.f,at.x,at.y)))
	;print,x1,x2,y1,y2
	at=crop_c(at,x1,x2,y1,y2)
	at.zz=s(1)*0.05
end
return,nreg	
end


function toat_crop_all,rega,coords=coords,at=at
n=n_elements(rega)
nreg=ptrarr(n)
nreg(0)=ptr_new(toat_crop(*rega(0),at=at,coords=coords))
if n gt 1 then for i=1,n-1 do begin
	reg=*rega(i)
	nreg(i)=ptr_new(toat_crop(reg,coords=coords))
end
return,nreg
end

function toat_cut,reg,x1,x2,y1,y2
n=n_elements(reg)
nreg=ptrarr(n)
for i=0,n-1 do begin
	rg=*reg(i)
	a=rg.a
	b=rg.b
	a=a(*,x1:x1+x2,y1:y1+y2)
	b=b(*,x1:x1+x2,y1:y1+y2)
	nreg(i)=ptr_new({a:a,b:b,vect:rg.vect,r:rg.r})
end

return, nreg
end

function toat_all,dump=dump,xsf=xsf,th=th,dirnm=dirnm,subset=subset,init=init
;dump dumps all the pictures
;xsf writes xsf files with the atomic structure
;th stores/restores the theoretical data (convenient because it takes long to load and make the basic transform)
;subset determines which  
resolve_routine,"register.pro"
df=toat_exp()
if not(keyword_set(th)) then th=toat_th(dirnm=dirnm,subset=subset)
ndf=df
if not(keyword_set(subset)) then subset=indgen(n_elements(th)) 
if not(keyword_set(init)) then init=[1.065,-85,17.,5.,2.]
reg=toat_regis(ndf,th(subset),step=[0,0,0,0,0],init=init)
nreg=toat_crop_all(reg)
ptr_free,reg(indgen(n_elements(reg)))
evl=toat_eval(nreg,dump=dump,xsf=xsf,dirnm=dirnm(subset))

ptr_free,nreg(indgen(n_elements(nreg)))
return,evl
end
