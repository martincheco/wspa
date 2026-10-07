function curv_mread
f=dialog_pickfile(/multi)
n=n_elements(f) 
ptar=ptrarr(n)
for i=0,n-1 do ptar(i)=ptr_new(curv_load(f(i)))

return,ptar
end

function curv_sub_multi,ptar,bkg

a=(*ptar(0))
b=(*ptar(1))

nptar=ptrarr(n_elements(ptar))

help,a,/st
for i=0,n_elements(ptar)-1 do begin
tmp=(*ptar(i))
nptar(i)=ptr_new(add2(tmp.x,tmp.y,bkg.x,-bkg.y))
end

return,nptar
end

pro curv_sav,f,t
help,t,/st
openw,1,f
for i=0,n_elements(t.x)-1 do printf,1,t.x(i),t.y(i)
close,1
end

function curv_add_multi,ptar

a=(*ptar(0))
b=(*ptar(1))

help,a,/st
res=add2(a.x,a.y,b.x,b.y)
for i=2,n_elements(ptar)-1 do begin
tmp=(*ptar(i))
res=add2(res.x,res.y,tmp.x,tmp.y)
end

return,{x:res.x,y:res.y/double(n_elements(ptar))}
end

function curv_load,f
a=read_ascii(f)
x=reform((a.(0))(0,*))
y=reform((a.(0))(1,*))

return,{x:x,y:y}
end

function curv_integ,x,y
n=n_elements(y)
dz=(max(x)-min(x))/n
iy=reverse(y)

for i=1,n-1 do iy(i)+=iy(i-1)

return,reverse(iy*dz*6.241506363e+18/0.043363); kcal/mol
end

function curv_sch,f,frag
w=where(strmatch(f,frag))
return,w(0)
end

function curv_adds,df,z,a,b,f,fls=fls
	ap=curv_sch(f,'*'+a+'*')
	bp=curv_sch(f,'*'+b+'*')
	print,f(ap),f(bp)
	if keyword_set(fls) then fls=[f(ap),f(bp)]
	x1=*z(ap)
	y1=*df(ap)
	srt=sort(x1)
	if b eq '' then return,{x:x1(srt),y:y1(srt)}
	x2=*z(bp)
	y2=*df(bp)
	nc=combine(x1,y1,x2,y2,/excl,/resample)
return,nc	
end

function curv_convert,lr,bk,hr=hr,bkhr=bkhr,dir=dir,mask=mask,w1=w1,w2=w2,decim=decim,amp=amp,k=k,f0=f0,wtime=wtime,dfonly=dfonly
;lr - strarr of low-res(or normal res) curve numbers
;hr - optional high-res inserts into the low-res curves
;bk - background curve nymber
;bkhr - hi-res background curve number
;mask - mask for the Z-spectroscopy filenames
;dir - working dir
;w1,w2 - filter widths for the variable width filterdfonly
;splines - number of splines for the resampling
;decim - decimation factor for the 
;amp,f0,k - parameters of the sensor
;dfonly - skips the giessibl part and the background subtraction

if not(keyword_set(dir)) then dir='.'
if not(keyword_set(mask)) then mask='*Z*.dat'
if not(keyword_set(hr)) then hr=strarr(n_elements(lr))
if not(keyword_set(bkhr)) then bkhr=strarr(n_elements(bk))
if not(keyword_set(w1)) then w1=5
if not(keyword_set(w2)) then w2=400
;if not(keyword_set(spl)) then spl=256
if not(keyword_set(decim)) then decim=7
if not(keyword_set(amp)) then amp=40e-12
if not(keyword_set(k)) then k=1080000D
if not(keyword_set(f0)) then f0=990791D
if not(keyword_set(wtime)) then wtime=0.1

lst=[bk,lr]
hlst=[bkhr,hr]
nm=n_elements(lst)

cd,dir,current=odir
f=getfiles()


w=where(strmatch(f,mask,/fold) eq 1)
f=f(w)
n=n_elements(f)

df=ptrarr(n)
z=ptrarr(n)
x=dblarr(n)
y=dblarr(n)
zof=dblarr(n)

;reading
for i=0,n-1 do begin
	print,'Reading ',f(i)
	tmp=(loadnanonis_sts(f(i)))
	dfch=where(strmatch(tmp.chans,'*freq*',/fold))
	df(i)=ptr_new(reform(tmp.data(dfch(0),*)+tmp.data(dfch(1),*))/2.)
	zch=where(strmatch(tmp.chans,'*rel*',/fold))
	z(i)=ptr_new(reform(tmp.data(zch(0),*))+tmp.p.z)
	zof(i)=tmp.p.z
	x(i)=tmp.p.x
	y(i)=tmp.p.y
end

print,'Done reading.'
;matching+adding
;manual part!!

ndf=ptrarr(nm)
nfilesa=strarr(nm)
nfilesb=strarr(nm)

;all curves combine
for i=0,nm-1 do begin
    fls=1
    ndf(i)=ptr_new(curv_adds(df,z,lst(i),hlst(i),f,fls=fls))
    nfilesa(i)=fls(0)
    nfilesb(i)=fls(1)
end

fdf=ptrarr(nm)

;filtering the background
	;help,(*ndf(0)).y
	bny=varwidthfilt((*ndf(0)).y,w1,w2)
;	plot,(*ndf(0)).x(0:-200),bny(0:-200),color=200,thick=3
	plot,(*ndf(0)).x,(*ndf(0)).y,psym=3,yst=1
print,'plotted background'
wait,wtime
xtmp=0.



for i=0,nm-1 do begin
	oplot,(*ndf(i)).x,(*ndf(i)).y,psym=3
	;filter
	ny=varwidthfilt((*ndf(i)).y,w1,w2)
        ;ny=(*ndf(i)).y
	;rny=ny
	rny=resample((*ndf(i)).x,ny,n_elements(ny)/decim,(*ndf(i)).x)	
	;background
	tmp=(add2((*ndf(i)).x(w1*2:-w2),rny(w1*2:-w2),(*ndf(0)).x(w1*2:-w2),bny(w1*2:-w2),/sub))
	if i eq 1 then begin 
		xtmp=min(tmp.x)
		(*fdf(0)).x-=xtmp
	end
	tmp.x=tmp.x-xtmp
	;decimate and resample
	nx=n_elements(tmp.x)/decim
	tx=tmp.x(findgen(nx)*decim)
	spl=nx
	ty=resample(tmp.x,tmp.y,spl,tx)
	;tuy=resample(tmp.x,rny(w1*2:-w1),spl,tx)
	tuy=resample(tmp.x,rny(w1*2:-w2),spl,tx)
	
	fdf(i)=ptr_new({x:tx,y:ty,uy:tuy})
	oplot,(*ndf(i)).x,ny,color=200
;	if i eq 1 then plot,(*fdf(i)).x,(*fdf(i)).y else oplot,(*fdf(i)).x,(*fdf(i)).y
	print,'plotting curve',i
	wait,wtime
end

if not(keyword_set(dfonly)) then begin

;df to F
ff=ptrarr(nm)
for i=0,nm-1 do begin
	df=(*fdf(i)).y
	;help,df
	nndf=n_elements(df)
	df=df(0:nndf/2)
	z=(*fdf(i)).x
	z=z(0:nndf/2)
	ddz=(z-shift(z,1))
	dz=ddz(1)
print,min(ddz(1:*))
print,max(ddz(1:*))

;	dz=double(max(z)-min(z))/n_elements(z)
	an=amp/dz
;help,i
	fff=giessibl(df-mmean(df(-10:-1)),k=k,f0=f0,n=an,dz=dz,/rev,/ext)
;	help,fff
	e=curv_integ(z,fff)
	ff(i)=ptr_new({x:z*1e12,y:fff*1e12,iy:e})

	if i eq 1 then plot,(*ff(i)).x,(*ff(i)).y,xst=1 else oplot,(*ff(i)).x,(*ff(i)).y,color=255L*i/nm,thick=3
end

;writing Force and Energy
for i=0,nm-1 do begin
	df=(*ff(i)).y
	z=(*ff(i)).x
	e=(*ff(i)).iy
	
	w=where(df eq min(df))
	ww=where(e eq min(e))
	;help,df
	dfms=strtrim(string(((df)(w(0))),format='(I04)'),2)
	zms=strtrim(string((z(ww(0))),format='(I04)'),2)
	ems=strtrim(string((e(ww(0)))),2)

	fnm='F'+strtrim(string((lst(i)),format='(I03)'),2)+'_'+dfms+'_'+zms+'_'+ems+'.dat'	
	openw,1,fnm
	for j=0,n_elements(z)-1 do printf,1,z(j),(df)(j),e(j)
	close,1
end

end

;writing df
zoffs=min((*ndf(0)).x*1D12)
for i=0,nm-1 do begin
	df=(*ndf(i)).y
	z=(*ndf(i)).x*1D12-zoffs
	
;	w=where(df eq min(df))
	
	dfms=strtrim(string(((df)(w(0))),format='(I04)'),2)
	zms=strtrim(string((z(w(0))),format='(I04)'),2)
	if keyword_set(dfonly) then dfstr='df' else dfstr='dfsub'
	fnm=dfstr+strtrim(string((lst(i)),format='(I03)'),2)+'.dat'	
	print,'Saving: ',fnm
	openw,1,fnm
	for j=0,n_elements(z)-1 do printf,1,z(j),(df)(j)
	close,1
end

openw,1,'filenames.txt'
for i=0,nm-1 do printf,1,nfilesa(i),'&',nfilesb(i)
close,1

cd,odir

if (keyword_set(dfonly)) then ff=df


return,{df:df,z:z}
end


