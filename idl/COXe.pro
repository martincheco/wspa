function integ,x,y
n=n_elements(y)
dz=(max(x)-min(x))/n
iy=reverse(y)

for i=1,n-1 do iy(i)+=iy(i-1)

return,reverse(iy*dz*6.241506363e+18/0.043); kcal/mol
end

function sch,f,frag
w=where(strmatch(f,frag))
return,w(0)
end

function adds,df,z,a,b,f
	ap=sch(f,'*'+a+'*')
	bp=sch(f,'*'+b+'*')
	print,f(ap),f(bp)
	x1=*z(ap)
	y1=*df(ap)
	srt=sort(x1)
	if b eq '' then return,{x:x1(srt),y:y1(srt)}
	x2=*z(bp)
	y2=*df(bp)
	nc=combine(x1,y1,x2,y2,/excl,/resample)
return,nc	
end

function island3

cd,'/home/martin/sync/data/CO_Xe_tips/CO_Xe_island3/z_sp'
f=getfiles()
w=where(strmatch(f,'*Z_spectro*.dat',/fold) eq 1)
f=f(w)
n=n_elements(f)

df=ptrarr(n)
z=ptrarr(n)
x=dblarr(n)
y=dblarr(n)
zof=dblarr(n)

;reading
for i=0,n-1 do begin
	tmp=(loadnanonis_sts(f(i)))
	dfch=where(strmatch(tmp.chans,'*freq*',/fold))
	df(i)=ptr_new(reform(tmp.data(dfch(0),*)+tmp.data(dfch(1),*))/2.)
	zch=where(strmatch(tmp.chans,'*rel*',/fold))
	z(i)=ptr_new(reform(tmp.data(zch(0),*))+tmp.p.z)
	zof(i)=tmp.p.z
	x(i)=tmp.p.x
	y(i)=tmp.p.y
end

;matching+adding
;manual part!!
nm=15

ndf=ptrarr(nm)

;background
ndf(0)=ptr_new(adds(df,z,'072','071',f))
ndf(1)=ptr_new(adds(df,z,'069','070',f))
ndf(2)=ptr_new(adds(df,z,'068','070',f))
ndf(3)=ptr_new(adds(df,z,'067','066',f))
ndf(4)=ptr_new(adds(df,z,'064','065',f))
ndf(5)=ptr_new(adds(df,z,'063','062',f))
ndf(6)=ptr_new(adds(df,z,'060','061',f))
ndf(7)=ptr_new(adds(df,z,'059','058',f))
ndf(8)=ptr_new(adds(df,z,'056','057',f))
ndf(9)=ptr_new(adds(df,z,'055','054',f))
ndf(10)=ptr_new(adds(df,z,'052','053',f))
ndf(11)=ptr_new(adds(df,z,'051','050',f))
ndf(12)=ptr_new(adds(df,z,'048','049',f))
ndf(13)=ptr_new(adds(df,z,'047','046',f))
ndf(14)=ptr_new(adds(df,z,'044','045',f))

fdf=ptrarr(nm)

;filtering and resampling
	help,(*ndf(0)).y
	bny=varwidthfilt((*ndf(0)).y,1,500,/edge)
;	plot,(*ndf(0)).x(0:-200),bny(0:-200),color=200,thick=3
	plot,(*ndf(0)).x,(*ndf(0)).y,psym=3,xst=1

xtmp=0.

for i=0,nm-1 do begin
	oplot,(*ndf(i)).x,(*ndf(i)).y,psym=3
	ny=varwidthfilt((*ndf(i)).y,5,500,/edge)
        rny=resample((*ndf(i)).x,ny,256,(*ndf(i)).x)	
	tmp=(add((*ndf(i)).x(10:-400),rny(10:-400),(*ndf(0)).x(10:-400),bny(10:-400),/sub))
	if i eq 1 then begin 
		xtmp=min(tmp.x)
		(*fdf(0)).x-=xtmp
	end
	tmp.x=tmp.x-xtmp
	nx=n_elements(tmp.x)/7
	tx=tmp.x(findgen(nx)*7)
	ty=resample(tmp.x,tmp.y,256,tx)
	tuy=resample(tmp.x,rny(10:-400),256,tx)
	
	fdf(i)=ptr_new({x:tx,y:ty,uy:tuy})
	oplot,(*ndf(i)).x,ny,color=200
;	if i eq 1 then plot,(*fdf(i)).x,(*fdf(i)).y else oplot,(*fdf(i)).x,(*fdf(i)).y

	wait,1.
end

;df to F
amp=40e-12
ff=ptrarr(nm)
for i=0,nm-1 do begin
	df=(*fdf(i)).y
	help,df
	nndf=n_elements(df)
	df=df(0:nndf/2)
	z=(*fdf(i)).x
	z=z(0:nndf/2)
	dz=(max(z)-min(z))/n_elements(z)
	an=amp/dz
help,i
	fff=giessibl(df-mmean(df(-30:-1)),k=1e6,f0=1e6,n=an,dz=dz,/rev,/ext)
;	help,fff
	e=integ(z,fff)
	ff(i)=ptr_new({x:z*1e12,y:fff*1e12,iy:e})

	if i eq 1 then plot,(*ff(i)).x,(*ff(i)).y,xst=1,yrange=[-60,10] else oplot,(*ff(i)).x,(*ff(i)).y,color=255L*i/nm,thick=3
end

;writing Force and Energy
for i=0,nm-1 do begin
	df=(*ff(i)).y
	z=(*ff(i)).x
	e=(*ff(i)).iy
	
	w=where(df eq min(df))
	ww=where(e eq min(e))
	
	dfms=strtrim(string((df(w(0))),format='(I04)'),2)
	zms=strtrim(string((z(ww(0))),format='(I04)'),2)
	ems=strtrim(string((e(ww(0)))),2)

	fnm='F'+strtrim(string(i,format='(I02)'),2)+'_'+dfms+'_'+zms+'_'+ems+'.dat'	
	openw,1,fnm
	for j=0,n_elements(z)-1 do printf,1,z(j),df(j),e(j)
	close,1
end


;writing df
for i=0,nm-1 do begin
	df=(*fdf(i)).uy
	z=(*fdf(i)).x*1D12
	
	w=where(df eq min(df))
	
	dfms=strtrim(string((df(w(0))),format='(I04)'),2)
	zms=strtrim(string((z(w(0))),format='(I04)'),2)

	fnm='df'+strtrim(string(i,format='(I02)'),2)+'_'+dfms+'_'+zms+'.dat'	
	openw,1,fnm
	for j=0,n_elements(z)-1 do printf,1,z(j),df(j)
	close,1
end



return,ff
end


function COCO

cd,'/home/martin/sync/data/CO_Xe_tips/CO_CO2/z_sp'
f=getfiles()
w=where(strmatch(f,'*Z_spectro*.dat',/fold) eq 1)
f=f(w)
n=n_elements(f)

df=ptrarr(n)
z=ptrarr(n)
x=dblarr(n)
y=dblarr(n)
zof=dblarr(n)

;reading
for i=0,n-1 do begin
	tmp=(loadnanonis_sts(f(i)))
	dfch=where(strmatch(tmp.chans,'*freq*',/fold))
	df(i)=ptr_new(reform(tmp.data(dfch(0),*)+tmp.data(dfch(1),*))/2.)
	zch=where(strmatch(tmp.chans,'*rel*',/fold))
	z(i)=ptr_new(reform(tmp.data(zch(0),*))+tmp.p.z)
	zof(i)=tmp.p.z
	x(i)=tmp.p.x
	y(i)=tmp.p.y
end

;matching+adding
;manual part!!
nm=9

ndf=ptrarr(nm)

;background
ndf(0)=ptr_new(adds(df,z,'041','040',f))
ndf(1)=ptr_new(adds(df,z,'038','039',f))
ndf(2)=ptr_new(adds(df,z,'037','036',f))
ndf(3)=ptr_new(adds(df,z,'035','034',f))
ndf(4)=ptr_new(adds(df,z,'033','032',f))
ndf(5)=ptr_new(adds(df,z,'030','031',f))
ndf(6)=ptr_new(adds(df,z,'029','028',f))
ndf(7)=ptr_new(adds(df,z,'026','027',f))
ndf(8)=ptr_new(adds(df,z,'025','024',f))

fdf=ptrarr(nm)

;filtering and resampling
	bny=varwidthfilt((*ndf(0)).y,1,500,edge=2)
;	plot,(*ndf(0)).x(0:-200),bny(0:-200),color=200,thick=3
xtmp=0.
for i=0,nm-1 do begin
	plot,(*ndf(i)).x,(*ndf(i)).y,psym=3,xst=1
	ny=varwidthfilt((*ndf(i)).y,10,500,edge=200)
        rny=resample((*ndf(i)).x,ny,256,(*ndf(i)).x)	
	tmp=(add((*ndf(i)).x(10:-400),rny(10:-400),(*ndf(0)).x(10:-400),bny(10:-400),/sub))
	if i eq 1 then begin 
		xtmp=min(tmp.x)
		(*fdf(0)).x-=xtmp
	end
	tmp.x=tmp.x-xtmp
	nx=n_elements(tmp.x)/7
	tx=tmp.x(findgen(nx)*7)
	ty=resample(tmp.x,tmp.y,256,tx)
	fdf(i)=ptr_new({x:tx,y:ty})
	oplot,(*ndf(i)).x,ny,color=200
;	if i eq 1 then plot,(*fdf(i)).x,(*fdf(i)).y else oplot,(*fdf(i)).x,(*fdf(i)).y

	wait,1.
end

;df to F
amp=40e-12
ff=ptrarr(nm)
for i=0,nm-1 do begin
	df=(*fdf(i)).y
	help,df
	nndf=n_elements(df)
	df=df(0:nndf/2)
	z=(*fdf(i)).x
	z=z(0:nndf/2)
	dz=(max(z)-min(z))/n_elements(z)
	an=amp/dz
	fff=giessibl(df-mmean(df(-30:-1)),k=1e6,f0=1e6,n=an,dz=dz,/rev,/ext)
;	help,fff
	e=integ(z,fff)
	ff(i)=ptr_new({x:z*1e12,y:fff*1e12,iy:e})

	if i eq 1 then plot,(*ff(i)).x,(*ff(i)).y,xst=1,yrange=[-25,50] else oplot,(*ff(i)).x,(*ff(i)).y,color=255L*i/nm,thick=3
end

;writing
for i=0,nm-1 do begin
	df=(*ff(i)).y
	z=(*ff(i)).x
	
	w=where(df eq min(df))
	
	dfms=strtrim(string((df(w(0))),format='(I04)'),2)
	zms=strtrim(string((z(w(0))),format='(I04)'),2)

	fnm='df'+strtrim(string(i,format='(I02)'),2)+'_'+dfms+'_'+zms+'.dat'	
	openw,1,fnm
	for j=0,n_elements(z)-1 do printf,1,z(j),df(j),e(j)
	close,1
end


return,ff
end


function flower2

cd,'/home/martin/sync/data/CO_Xe_tips/CO_Xe_flower2/z_sp'
f=getfiles()
w=where(strmatch(f,'*Z_spectro*.dat',/fold) eq 1)
f=f(w)
n=n_elements(f)

df=ptrarr(n)
z=ptrarr(n)
x=dblarr(n)
y=dblarr(n)
zof=dblarr(n)

;reading
for i=0,n-1 do begin
	tmp=(loadnanonis_sts(f(i)))
	dfch=where(strmatch(tmp.chans,'*freq*',/fold))
	df(i)=ptr_new(reform(tmp.data(dfch(0),*)+tmp.data(dfch(1),*))/2.)
	zch=where(strmatch(tmp.chans,'*rel*',/fold))
	z(i)=ptr_new(reform(tmp.data(zch(0),*))+tmp.p.z)
	zof(i)=tmp.p.z
	x(i)=tmp.p.x
	y(i)=tmp.p.y
end

;matching+adding
;manual part!!
nm=8

ndf=ptrarr(nm)

;background
ndf(0)=ptr_new(adds(df,z,'016','015',f))
ndf(1)=ptr_new(adds(df,z,'001','002',f))
ndf(2)=ptr_new(adds(df,z,'004','003',f))
ndf(3)=ptr_new(adds(df,z,'005','006',f))
ndf(4)=ptr_new(adds(df,z,'008','007',f))
ndf(5)=ptr_new(adds(df,z,'009','010',f))
ndf(6)=ptr_new(adds(df,z,'012','011',f))
ndf(7)=ptr_new(adds(df,z,'013','014',f))

fdf=ptrarr(nm)

;filtering and resampling
	help,(*ndf(0)).y
	bny=varwidthfilt((*ndf(0)).y,1,500,/edge)
;	plot,(*ndf(0)).x(0:-200),bny(0:-200),color=200,thick=3
	plot,(*ndf(0)).x,(*ndf(0)).y,psym=3,xst=1

xtmp=0.

for i=0,nm-1 do begin
	oplot,(*ndf(i)).x,(*ndf(i)).y,psym=3
	ny=varwidthfilt((*ndf(i)).y,5,500,/edge)
        rny=resample((*ndf(i)).x,ny,256,(*ndf(i)).x)	
	tmp=(add((*ndf(i)).x(10:-400),rny(10:-400),(*ndf(0)).x(10:-400),bny(10:-400),/sub))
	if i eq 1 then begin 
		xtmp=min(tmp.x)
		(*fdf(0)).x-=xtmp
	end
	tmp.x=tmp.x-xtmp
	nx=n_elements(tmp.x)/7
	tx=tmp.x(findgen(nx)*7)
	ty=resample(tmp.x,tmp.y,256,tx)
	tuy=resample(tmp.x,rny(10:-400),256,tx)
	
	fdf(i)=ptr_new({x:tx,y:ty,uy:tuy})
	oplot,(*ndf(i)).x,ny,color=200
;	if i eq 1 then plot,(*fdf(i)).x,(*fdf(i)).y else oplot,(*fdf(i)).x,(*fdf(i)).y

	wait,2.
end

;df to F
amp=40e-12
ff=ptrarr(nm)
for i=0,nm-1 do begin
	df=(*fdf(i)).y
	help,df
	nndf=n_elements(df)
	df=df(0:nndf/2)
	z=(*fdf(i)).x
	z=z(0:nndf/2)
	dz=(max(z)-min(z))/n_elements(z)
	an=amp/dz
help,i
	fff=giessibl(df-mmean(df(-30:-1)),k=1e6,f0=1e6,n=an,dz=dz,/rev,/ext)
;	help,fff
	e=integ(z,fff)
	ff(i)=ptr_new({x:z*1e12,y:fff*1e12,iy:e})

	if i eq 1 then plot,(*ff(i)).x,(*ff(i)).y,xst=1,yrange=[-60,10] else oplot,(*ff(i)).x,(*ff(i)).y,color=255L*i/nm,thick=3
end

;writing Force and Energy
for i=0,nm-1 do begin
	df=(*ff(i)).y
	z=(*ff(i)).x
	e=(*ff(i)).iy
	
	w=where(df eq min(df))
	ww=where(e eq min(e))
	
	dfms=strtrim(string((df(w(0))),format='(I04)'),2)
	zms=strtrim(string((z(ww(0))),format='(I04)'),2)
	ems=strtrim(string((e(ww(0)))),2)

	fnm='F'+strtrim(string(i,format='(I02)'),2)+'_'+dfms+'_'+zms+'_'+ems+'.dat'	
	openw,1,fnm
	for j=0,n_elements(z)-1 do printf,1,z(j),df(j),e(j)
	close,1
end


;writing df
for i=0,nm-1 do begin
	df=(*fdf(i)).uy
	z=(*fdf(i)).x*1D12
	
	w=where(df eq min(df))
	
	dfms=strtrim(string((df(w(0))),format='(I04)'),2)
	zms=strtrim(string((z(w(0))),format='(I04)'),2)

	fnm='df'+strtrim(string(i,format='(I02)'),2)+'_'+dfms+'_'+zms+'.dat'	
	openw,1,fnm
	for j=0,n_elements(z)-1 do printf,1,z(j),df(j)
	close,1
end



return,ff
end


