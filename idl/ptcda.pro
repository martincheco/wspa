function ptcda_exp2
lo=process_all(dir="/home/martin/sync/data/Ag111_PTCDA_Xe/processed/data_charged/lorange/",/fold)
sh=process_all(dir="/home/martin/sync/data/Ag111_PTCDA_Xe/processed/data_charged/shrange/",/fold,/rmshift,/rmdelay)
lo=reform(lo(*,2,14:242,10:204))
sh=reform(sh(*,2,27:-27,60:-62))
help,lo
help,sh
return,[sh,lo]
end

function ptcda_exp
exp=process_all(dir="/home/martin/sync/data/Ag111_PTCDA_Xe/processed/data_uncharged/",/rmshift,/rmdelay,/fold,oversample=2)
exp=reform(exp(*,2,*,*))
s=size(exp)
exp=congrid(exp,s(1),s(2)/2,s(3)/2,/interp)

exp=exp(*,20:-20,10:-10)
return,exp;[exp,exp(0:5,*,*)*(-0./0.)]
end


function ptcda_deform,df,y
;deforms a bit as needed in y direction
s=size(df)
ndf=dblarr(s(1),s(2),y)
for i=0,s(1)-1 do $
	ndf(i,*,*)=congrid(reform(df(i,*,*)),s(2),y,/interp)
return,ndf
end

function ptcda_th,at=at,dirnm=dirnm,subset=subset
resolve_routine,'genslice'
at=read_bas('/home/martin/sync/data/Ag111_PTCDA_Xe/processed/PTCDA_model.bas')
;at=repeat_c(at,6,5)
;at=scale_c(at,0.667)
ang=-64.4121+0.5
zm=0.680
;print,at.xy(5)
at=repeat_c(at,5,6)
at.xy=at.xy-(vector(at.e,at.x,at.y)+vector(at.f,at.x,at.y))/2.
cell=at ;store the lattice vectors
at=rot_c(at,-ang)
at=mirror_c(at,/x)
at.xy=at.xy+(vector(cell.e,cell.x,cell.y)+vector(cell.f,cell.x,cell.y))/2.
at.x=cell.x
at.y=cell.y
drs=getfiles('/home/martin/sync/data/Ag111_PTCDA_Xe/processed/registration_ultimate/PTCDA_Ag/newnew',/dirs)
if keyword_set(subset) then drs=drs(subset)
n=n_elements(drs)

dirnm=drs
thp=ptrarr(n)
;print,drs
for i=0,n-1 do begin
	print,'Reading:',drs(i)+'OutFz.xsf'
	th=xsf_read(drs(i)+'OutFz.xsf')
	s=size(th)
	help,th,/st
	th=giessibl(reverse(1.60217*1e-9*th.data,1),n=14,dz=5e-12,k=1e6,f0=1e6,/ext)
	th=th(0:*,*,*)
	th=repstack(th,6,2)
	th=repstack(th,5,3)
	th=rot3d(th,ang);64.2121
	th=register_zoom(th,zm);0.667
	help,th
	th=reverse(th,2)
	if i eq 0 then $
		tht=ptcda_crop({a:th,b:th,r:0,vect:0,mhat:0},coords=[0,-1,200,-200,70,-70],at=at) 
	th=th(*,200:-200,70:-70)
	thp(i)=ptr_new(th)
end


return,thp
end

function ptcda_regis,exp,th,step=step,at=at,init=init
n=n_elements(th)
cors=dblarr(n)
zs=cors
ccs=cors
thn=ptrarr(n)
if not(keyword_set(init)) then init=[1.,0.,0.,50,-4,0,0]
for i=0,n-1 do begin
	thx=*th(i)
	res=register_iter(thx(0:20,*,*),exp,init(0),init(1),init(2),init(3),init(4),init(5),init(6),/vis,step=step,/norot)
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

function ptcda_eval,thr,dump=dump,xsf=xsf,at=at,dirnm=dirnm
n=n_elements(thr)
cors=dblarr(n)
zs=cors
ccs=cors
s=size((*thr(0)).a)
ovlps=dblarr(n,s(1))
thn=ptrarr(n)
window,0,xs=600,ys=600
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
	pearson=correlate(res.a(w),res.b(w),/double)
	register_corr,res,cc=cc,reg=reg,ovlp=ovlp
;	help,ovlp
;	ovlps(i,*)=ovlp
	a=tvrd(0,true=1)
	;write_png,'a_overview.png',reverse(a,3)
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
	printf,1,'Proportionality: ',ccs(i)
	printf,1,'Pearson: ',pearson

	printf,1,'Zoom, Rot, dz, dx, dy:',res.vect
	close,1
	if keyword_set(xsf) then begin
		xsf_write,'df_th.xsf',res.a,at=at
		xsf_write,'df_exp.xsf',res.b,at=at
	end
cd,'..'
end
return,{zs:zs,ccs:ccs,cors:cors,ovlps:ovlps}
end

pro ptcda_funct,x,a,f
	f=a(0)-a(1)/((a(2)*x-a(3))^2)

end

function ptcda_funct,x,a
	ptcda_funct,x,a,f
return,f
end

function ptcda_integrate,st,dz
;integrates the force
if not(keyword_set(dz)) then dz=1.
stn=st*0.
s=size(st)
for i=s(1)-2,0,-1 do stn(i,*,*)=stn(i+1,*,*)+st(i,*,*)
return,stn*dz
end

function ptcda_diff_x,st,dx
fx=(st-shift(st,0,-1,0))/dx
fx(*,-1,*)=fx(*,-2,*)
return,fx
end

function ptcda_diff_y,st,dy
fy=(st-shift(st,0,0,-1))/dy
fy(*,*,-1)=fy(*,*,-2)
return,fy
end

function ptcda_df2f,exp,bkg,noconv=noconv,fit=fit,full=full,filt=filt
if not(keyword_set(fit)) then lim=80 else lim=fit

xb=bkg.data(0,*)
yb=bkg.data(9,*)
;sorting
is=sort(xb)
xb=xb(is)
yb=yb(is)
;resampling
n=round((max(xb)-min(xb))/5e-12)
newxs=findgen(n)*5e-12;+35e-12
help,n
nyb=dezofilter(xb,yb,/savg);,newxs=newxs,w=5)
;nyb=nyb(indgen(n))
wi=dindgen(n)/double(n)*double(n_elements(xb))
;plot,xb,yb
;oplot,xb(wi(37:*)),nyb(wi(37:*)),color=255,psym=1
nyb=(nyb((wi(41:*))))

npn=n_elements(nyb)
;polyfit,dindgen(npn)+41.,nyb,7,c,sig,yfit
nxb=dindgen(npn)+41.
c=[0.1,200.,.02,-20.]
;yfit=curvefit(nxb(60:*),nyb(60:*),undef,c,function_name='ptcda_funct',/noderivative,/double,status=status)
yfit=curvefit(nxb(lim:-2),nyb(lim:-2),undef,c,function_name='ptcda_funct',/noderivative,/double,status=status)
;print,status
plot,nxb,nyb
;print,c
oplot,nxb,ptcda_funct(nxb,c)

nyb=smooth(nyb,5)

if keyword_set(filt) then ex=stackfilt(exp,10) else ex=exp
;ex=exp

;adding to the 3d bulk
s=size(ex)
ss=size(nyb)
ix=dindgen(s(1)+ss(1))
;print,c
plnm=ptcda_funct(ix,c)
plot,ix,plnm
oplot,dindgen(npn)+41.,nyb,color=255

nexp=dblarr(s(1)+ss(1),s(2),s(3))
help,nexp
nexp(0:s(1)-1,*,*)=ex
nexp(s(1):*,*,*)=mreplicate(mreplicate(nyb,s(2)),s(3))
help,nexp
if keyword_set(fit) then begin

	nexp=nexp-mreplicate(mreplicate(plnm,s(2)),s(3))
	nexp(41.+49.:*,*,*)=0.
end
;plot,nexp(*,100,100)
help,nexp
;f2f
if keyword_set(full) then ncalc=nexp else ncalc=nexp(0:100,*,*)
if keyword_set(noconv) then res=ncalc else res=giessibl(ncalc,n=14,dz=5e-12,k=5e5,f0=1e6)

return,res
end



function ptcda_crop,reg,at=at,coords=coords
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


function ptcda_crop_all,rega,coords=coords,at=at
n=n_elements(rega)
nreg=ptrarr(n)
nreg(0)=ptr_new(ptcda_crop(*rega(0),at=at,coords=coords))
if n gt 1 then for i=1,n-1 do begin
	reg=*rega(i)
	nreg(i)=ptr_new(ptcda_crop(reg,coords=coords))
end
return,nreg
end

function ptcda_cut,reg,x1,x2,y1,y2
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

function ptcda_all,df,dump=dump,xsf=xsf,th=th,dirnm=dirnm,subset=subset,init=init,atb=atb
;dump dumps all the pictures
;xsf writes xsf files with the atomic structure
;th stores/restores the theoretical data (convenient because it takes long to load and make the basic transform)
;subset determines which  
help,th
help,dirnm
if not(keyword_set(th)) then th=ptcda_th(at=at,dirnm=dirnm,subset=subset)
ndf=ptcda_deform(df,255)
if not(keyword_set(subset)) then subset=indgen(n_elements(th)) 
reg=ptcda_regis(ndf,th(subset),at=at,step=[0.,0,0.,0.,0.,0.,0.],init=init)
nreg=ptcda_crop_all(reg,at=at)
ptr_free,reg(indgen(n_elements(reg)))
if keyword_set(atb) then at=atb
evl=ptcda_eval(nreg,dump=dump,xsf=xsf,at=at,dirnm=dirnm(subset))
ptr_free,nreg(indgen(n_elements(nreg)))
if not(keyword_set(atb)) then atb=at
return,evl
end


function ptcda_graph

d=getfiles(/dirs)
n=n_elements(d)
q=dblarr(n)
k=q
p=q
im=ptrarr(n)

for i=0,n-1 do begin
	kq=strsplit(file_basename(d(i)),'Q|-K',/regex,/extract)
	k(i)=kq(0)
	q(i)=kq(1)
	
	img=read_png(d(i)+'/a_overview.png')
	im(i)=ptr_new(img)
	pars=read_file(d(i)+'/params.txt',/array)
	help,pars
	p(i)=getval(pars,'Pearson:','flt')

end
help,p
q=[q(0:15),(q(15)+q(16))/2,q(16:-1)]
k=[k(0:15),(k(15)+k(16))/2,k(16:-1)]
p=[p(0:15),(p(15)+p(16))/2,p(16:-1)]

help,q(15)
help,q(16)
help,k(15)
help,k(16)

p(7)=(p(6)+p(8))/2
;p(18)=(p(18-3)+p(18+3))/2.

q=reform(q,3,9)
q(*,0:3)=reverse(q(*,0:3),2)
k=reform(k,3,9)
k(*,0:3)=reverse(k(*,0:3),2)
p=reform(p,3,9)
p(*,0:3)=reverse(p(*,0:3),2)


openw,1,'gplt.dat'
for i=0,2 do begin
	for j=0,8 do printf,1,k(i,j),q(i,j),p(i,j)
	printf,1,''
end
close,1

return,{k:q,q:k,p:p,im:img}
end
