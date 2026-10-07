;set of routines that load, process and fit the data of a kondo peak

function getind,x,val
;finds an index of the value nearest to val
dis=abs(x-val)
w=where(dis eq min(dis))
if w(0) ne -1 then ind=w(0) else ind=0
return,ind
end

pro lorentz,x,a,f
;order of parameters: w
w=a(1)
y0=a(0)
amp=a(2)
;slope=a(3)
x0=-0.3
e=(x-x0)/w
f=y0+amp/(1+e^2);+slope*e
end

pro frota,x,a,f
;order of parameters: w
w=a(2)
y0=a(0)
amp=a(1)
phase=0
slope=0;a(3)
x0=a(3);-0.45;a(4)
e=(x-x0)
ii=complex(0,1)
f=slope*e+y0+amp*imaginary(-ii*exp(phase*ii)*(ii*w/(ii*w+e))^0.5)
end

pro frota_m,x,a,f
;order of parameters: w
w=a(2)
y0=a(0)
amp=a(1)
x0=-0.39
phase=1.5;a(4)
e=(x-x0)
ii=complex(0,1)
pk1=exp(ii*phase)*(ii*w/(ii*w+e))^0.5
f=amp*Imaginary((pk1))+y0
end

pro frota_m1,x,a,f
;order of parameters: w
w=a(3);a(5)
y0=a(0)
amp=a(1)
slope=0;a(3)
x0=-0.39;
phase=1.;a(4)
e=(x-x0)
sp=a(2)
ii=complex(0,1)
pk1=ii*exp(ii*phase)*(ii*w/(ii*w+e-sp))^0.5
;pk2=ii*exp(ii*phase)*(ii*w/(ii*w-e-sp))^0.5
f=amp*Imaginary((pk1))+y0;slope*e
end

pro frota_m2,x,a,f
;order of parameters: w
w=0.35;a(5)
y0=a(0)
amp=a(1)
slope=a(3)
x0=0;-0.39;
phase=1.;a(4)
e=(x-x0)
sp=a(2)
ii=complex(0,1)
pk1=ii*exp(ii*phase)*(ii*w/(ii*w-e-sp))^0.5
;pk2=ii*exp(ii*phase)*(ii*w/(ii*w-e-sp))^0.5
f=amp*Imaginary((pk1))+y0+slope*e
end


function kondo,x,y,a,rng=rng
if not(keyword_set(a)) then a=[0.,1.,0.1,0.];,0.]
a=abs(a)<[1.0,2.,2.,0.]
if not(keyword_set(rng)) then rang=indgen(n_elements(x)) else rang=indgen(rng(1)-rng(0)+1)+rng(0)
yfit=curvefit(x(rang),y(rang),1./y(rang),a,function_name='frota',/noderivative,/double,itmax=1000,status=status,tol=1E-4)
return,{x:x,y:y,yfit:yfit,a:a,stat:status}
end

function fit_area,slice,x,z,wtime=wtime,rng=rng,plt=plt
;fits line by line using 2nd index
;wtime adds extra wait time between fits for better visualisation
;rng if set, defines fitting ranges for each index separately
s=size(slice)
fslice=slice*0
par=dblarr(4,s(2)) ;for the parameters
if not(keyword_set(z)) then z=indgen(s(2))

for i=0,s(2)-1 do begin
    y=slice(*,i)
    yf=kondo(x,y,a,rng=rng)
    if keyword_set(plt) then begin
	plot,x,y
;	xyouts,50,50,string(i),/dev
	xyouts,50,50,string(z(i)),/dev
	oplot,x(rng(0):rng(1)),yf.yfit,color=128,thick=2.
;	frota_m1,x(rng(0):rng(1)),a,altf
;	oplot,x(rng(0):rng(1)),altf,color=64,thick=2.
;	frota_m2,x(rng(0):rng(1)),a,altf
;	oplot,x(rng(0):rng(1)),altf,color=64,thick=2.

    end
    if keyword_set(wtime) then wait,wtime
    if yf.stat eq 0 then begin
	if keyword_set(rng) then fslice(rng(0):rng(1),i)=yf.yfit else fslice(*,i)=yf.yfit
	par(*,i)=yf.a
    end else begin
	print,"Error ",yf.stat," at i = ",i
	par(*,i)=1/0.
    end
end
return,{data:slice,fit:fslice,par:par,x:x,z:z}
end

function fit_stack,st,chan,x,z,wtime=wtime,smth=smth,ranges=ranges,plt=plt
;fit_area on a stack(index,chan,column,row)
;fits rows, according to x
s=size(st)
;help,st
;print,s
stack=reform(st(*,chan,*,*),s(1),s(3),s(4))
s=size(stack)
;print,s
if not(keyword_set(ranges)) then ranges=mreplicate([0,s(2)-1],s(1))
data=stack
fit=stack/0.
if not(keyword_set(x)) then x=findgen(s(2))
if not(keyword_set(z)) then z=findgen(s(3))
print,'Fitting slice:',string(0)
f=fit_area(reform(stack(0,*,*)),x,z,wtime=wtime,rng=reform(ranges(*,0)),plt=plt)
sp=size(f.par)
par=dblarr(s(1),sp(1),s(3))
par(0,*,*)=f.par
fit(0,*,*)=f.fit

for i=1,s(1)-1 do begin
    print,"Fitting slice:",i
    f=fit_area(reform(stack(i,*,*)),x,z,wtime=wtime,rng=reform(ranges(*,i)),plt=plt)
    par(i,*,*)=f.par
    fit(i,*,*)=f.fit
end

return,{data:data,fit:fit,par:par,x:x,z:z}
end

function fold_stack,stack
;averages channels, assumes even number of channels plus one Z or V as the first one
s=size(stack)
n=(s(2)-1)/2
nstack=stack(*,0:n,*,*)
;help,nstack
nstack(*,1:*,*,*)=(stack(*,1:n,*,*)+stack(*,n+1:s(2)-1,*,*))/2

return,nstack
end


pro draw_fit_par,fit,par,rng=rng,abs=abs,smth=smth
s=size(fit.par)
if not(keyword_set(rng)) then rng=indgen(s(3))
if keyword_set(abs) then ppar=abs(fit.par) else ppar=fit.par
sppar=ppar
;help,sppar
if keyword_set(smth) then begin
    smth=(smth>2)<10
    for i=0,s(1)-1 do sppar(i,par,*)=smooth(reform(sppar(i,par,*)),smth)
end

tvlct,r,g,b,/get
;loadct,0
plot,fit.z(rng),ppar(0,par,rng),yrange=[0,max(ppar(*,par,rng),/nan)],yst=1,xst=1,psym=3,charsize=2.0,color=0,background=255
tvlct,r,g,b
incr=256/(s(1)+1)
for i=0,s(1)-1 do begin
oplot,fit.z(rng),ppar(i,par,rng),color=255-incr*(i+1),psym=1
end
for i=0,s(1)-1 do begin
oplot,fit.z(rng),sppar(i,par,rng),color=255-incr*(i+1),psym=-3,thick=3.
end

;a=indgen(256)
;m=mreplicate(a,10)
;tvscl,m
end


pro draw_profiles,stack,chan,col,x,z,rng=rng,fixy=fixy,quant=quant
names=strarr(20)
names[0]='Z [pm]'
if keyword_set(quant) then names[1]='I [G0]' else names[1]='I [nA]'
names[2]='dI/dV [a.u.]'
names[3]='Energy [eV]'
names[5]='df [Hz]'
names[6]='Exc [eV]'


st=reform(stack(*,chan,col,*))
s=size(stack)
if not(keyword_set(rng)) then rng=indgen(s(2))

if keyword_set(fixy) then yrng=[min(stack(*,chan,*,rng),/nan),max(stack(*,chan,*,rng),/nan)] else yrng=[min(stack(*,chan,col,rng),/nan),max(stack(*,chan,col,rng),/nan)]
;help,yrng
;print,yrng
tvlct,r,g,b,/get
loadct,0,/silent
plot,z,st(0,rng),yrange=yrng,yst=1,xst=1,psym=-3,charsize=2.0,background=255,color=0,ytitle=names[chan],xtitle=names[0]
tvlct,r,g,b
incr=256/(s(1)+1)
for i=0,s(1)-1 do begin
oplot,z,st(i,rng),color=255-incr*(i+1),psym=-3,thick=3.
end

end

pro draw_all,fit,stack,pars,chans,rng=rng,xval=xval,fixy=fixy,quant=quant
window,0,xs=600,ys=700
wp=where(pars ge 0)
pars=pars(wp)
wch=where(chans ge 0)
chans=chans(wch)
if wp(0) ne -1 then m=n_elements(pars) else m=0
if wch(0) ne -1 then n=n_elements(chans) else n=0
!p.multi=[0,1,m+n]
!x.margin=[10,3]
!y.margin=[3,0]
;print,pars
;help,fit,/st
;help,stack
;help,rng
for i=0,m-1 do if m ne 0 then draw_fit_par,fit,pars(i),/abs,smth=1
for i=0,n-1 do draw_profiles,stack,chans(i),getind(fit.x,xval),fit.x,fit.z,fixy=fixy,rng=rng,quant=quant
!p.multi=0
!x.margin=[10,3]
!y.margin=[4,2]
a=indgen(256)
m=mreplicate(reverse(a),10)
tvscl,transpose(m)
s=size(stack)
for i=0,s(1)-1 do xyouts,10,(i+1)*256/(s(1)+1),strtrim(string(i),2),/dev,color=0
xyouts,0.7,0.95,' V = '+strtrim(string(fit.x(getind(fit.x,xval))),2)+' mV',/norm,color=0,charsize=1.5
xyouts,0.7,0.9,'(V = '+strtrim(string(xval),2)+' mV)',/norm,color=0,charsize=1.5
end

function addstacks,d0t,d1t
;concatenates two stacks
s1=size(d0t)
s2=size(d1t)
if s1(0) eq 3 then d0r=reform(d0t,1,s1(1),s1(2),s1(3)) else d0r=d0t
if s2(0) eq 3 then d1r=reform(d1t,1,s2(1),s2(2),s2(3)) else d1r=d1t
s1=size(d0r)
s2=size(d1r)
;print,s1
;print,s2
if s1(0) eq 4 and s2(0) eq 4 then begin
newd=dblarr(s1(1)+s2(1),s1(2),s1(3),s1(4))
newd(0:s1(1)-1,*,*,*)=d0r
newd(s1(1):s2(1)+s1(1)-1,*,*,*)=d1r
end else newd=0
return,newd
end

pro showstack,stack,chans,x,y,eps=eps
;eps adjusts the charsize

if keyword_set(eps) then chsz=1. else chsz=2.5

st=stack(*,chans,*,*)
s=size(st)

if not(keyword_set(x)) then x=indgen(s(3))
if not(keyword_set(y)) then y=indgen(s(4))

!p.multi=[0,s(1),s(2)]
!x.margin=[4,1]
!y.margin=[1,0]

levels=254

for j=0,s(2)-1 do $
    for i=0,s(1)-1 do begin
	data=(reform(st(i,j,*,*)))
	help,(where(finite(data,/nan)))
	data(where(finite(data,/nan)))=mmean(data,/nan)
	print,i,j,min(data,/nan),max(data,/nan)
	if max(data,/nan) ne min(data,/nan) then step = ((Max(data,/nan) - Min(data,/nan)) / levels) else step=1.
	userLevels = (IndGen(levels)) * step + Min(data,/nan)
;    print, userlevels
;	SetDecomposedState, 0, CurrentState=state
	Contour, data, x, y, /Fill, C_Colors=Indgen(levels), Background=255, $
	Levels=userLevels, Color=0,xst=1,yst=1,ticklen=-0.02,charsize=chsz;charsize=2.5/n_elements(chans)^0.5
;	Contour, data, x, y, /Overplot, Levels=userLevels, /Follow, Color=0
;	SetDecomposedState, state

;	contour,data,x,y,nlevels=255,c_colors=findgen(255)+3.,/fill,xst=1,yst=1,charsize=2.,color=0,background=255
;	contour,data,x,y,nlevels=255,c_colors=indgen(256),/fill,xst=1,yst=1;,/overplot
;	contour,(reform(st(i,j,*,*))),x,y,nlevels=255,c_colors=indgen(256),/fill,xst=1,yst=1,charsize=2.,color=0,background=255,/overplot,/nodata
end


!p.multi=0
end

pro video,area,xt,zt
s=size(area)
;help,area
for j=0,s(2)-1 do begin
    tvlct,r,g,b,/get
    loadct,0,/silent
    plot,xt,area(*,j),xst=1,yst=1,yrange=[min(area(*,j:*)),max(area(*,j:*))],background=255,color=0
    tvlct,r,g,b
    for i=j,s(2)-1,3 do oplot,xt,area(*,i),color=255.-float(i-j)/(s(2)-j)*255.
    xyouts,260,680,strtrim(string(zt(j)),2)+"-"+strtrim(string(zt(s(2)-1)),2)+"pm",/dev,color=0,charsize=2.0
a=tvrd(0,true=1)
a=reverse(a,3)
write_png,"graph_"+strtrim(string(j),2)+".png",a
end
end

pro video2,fullarea,ch,xt,zt,dirnm=dirnm,chans=chans,names=names,fixy=fixy,all=all,fit=fit
;ch is the first index (field)
;xt,zt - values of x and z
;dirnm - name of dir to use for saving files
;names - names of channels
;fixy - keep y axes on the same range
;all - ignore ch and draw all once with different colors

area=reform(fullarea(ch,*,*,*))
s=size(area)
fs=size(fullarea)
if not(keyword_set(names)) then names=strtrim(string(indgen(s(1))),2)
names[0]='Z [pm]'
names[1]='I [nA]'
names[2]='dI/dV [a.u.]'
names[3]='Energy [eV]'
names[5]='df [Hz]'
names[6]='Exc [eV]'


if not(keyword_set(chans)) then chans=indgen(s(1))
!p.multi=[0,1,n_elements(chans)]
cd,current=cwd
if not(keyword_set(dirnm)) then dirnm=cwd
if not(keyword_set(all)) then file_mkdir,dirnm+'/bias_dep'
tvlct,r,g,b,/get
loadct,0,/silent
window,0,xs=500,ys=200*n_elements(chans)
;help,area
xd=!x.margin
!x.margin=[10,1]
yd=!y.margin
!y.margin=[3,1]
incr=256/(fs(1)+1)

yrng=dblarr(n_elements(chans),2)

    for i=0,n_elements(chans)-1 do if keyword_set(fixy) then $
	yrng(i,*)=[min(fullarea(*,chans(i),*,*)),max(fullarea(*,chans(i),*,*))] $
	else yrng(i,*)=[min(fullarea(ch,chans(i),*,*)),max(fullarea(ch,chans(i),*,*))]

if not(keyword_set(all)) then begin
    loadct,0,/silent
    for j=0,s(3)-1 do begin
	for i=0,n_elements(chans)-1 do begin
	    plot,xt,area(chans(i),*,j),xst=1,yst=1,background=255,$
		color=0,thick=3.,psym=-3,charsize=n_elements(chans)^0.5,ytitle=names(chans(i)),xtitle='Bias [mV]';,yrange=yrng(i,*)
		if keyword_set(fit) and chans(i) eq 2 then oplot,fit.x,fit.fit(ch,*,j),color=128,thick=3.,psym=-3
	end
	xyouts,0.7,0.95,strtrim(string(zt(j),format='(F04.0)'),2)+' pm',/norm,color=0,charsize=1.5

	a=tvrd(0,true=1)
	a=reverse(a,3)
	write_png,dirnm+"/bias_dep/"+strtrim(string(j,format='(I04)'),2)+"_"+strtrim(string(zt(j),format='(F04.0)'),2)+"pm.png",a
    end
end else begin
    for j=0,s(3)-1 do begin
	if not(keyword_set(fixy)) then for p=0,n_elements(chans)-1 do yrng(p,*)=reform([min(fullarea(*,chans(p),*,j)),max(fullarea(*,chans(p),*,j))])
	loadct,0,/silent
	for i=0,n_elements(chans)-1 do begin
		plot,xt,fullarea(0,chans(i),*,j),xst=1,yst=1,background=255,$
		color=0,thick=3.,psym=-3,charsize=n_elements(chans)^0.5,ytitle=names(chans(i)),xtitle='Bias [mV]',yrange=yrng(i,*)
		tvlct,r,g,b

		for k=0,fs(1)-1 do $
		    oplot,xt,fullarea(k,chans(i),*,j),color=255-(k+1)*incr,thick=3.,psym=-3
	end
	xyouts,0.7,0.95,strtrim(string(zt(j),format='(F04.0)'),2)+' pm',/norm,color=0,charsize=1.5


	bl=indgen(256)
	ml=mreplicate(reverse(bl),10)
	tvscl,transpose(ml)
	for blm=0,fs(1)-1 do xyouts,10,(blm+1)*256/(fs(1)+1),strtrim(string(blm),2),/dev,color=0,charsize=1.5

	a=tvrd(0,true=1)
	a=reverse(a,3)
	write_png,dirnm+'/z_'+strtrim(string(j,format='(I04)'),2)+"_"+strtrim(string(zt(j),format='(F04.0)'),2)+"pm.png",a
    end
end




!x.margin=[10,3]
!y.margin=[5,2]
!p.multi=0
tvlct,r,g,b
end

function merge,a,b
;merges two arrays, respects the x coordinates, resulting x can be irregular
    nx=[a.x,b.x]
    srt=sort(nx)
    nx=nx(srt)
    sa=size(a.data)
    sb=size(b.data)
    nd=dblarr(sa(1),sa(2),sa(3)+sb(3),sa(4))
    nd(*,*,0:sa(3)-1,*)=a.data
    nd(*,*,sa(3):sa(3)+sb(3)-1,*)=b.data
    ;nnd=nd*0
    ;for i=0,n_elements(srt)-1 do nnd(*,*,i,*)=nd(*,*,srt(i),*)
    nnd=nd(*,*,srt,*)
    return,{data:nnd,x:nx,z:a.z}
end


function process_all,dr,chans=chans,pars=pars,x=x,z=z,$
eps=eps,graphs=graphs,allgraphs=allgraphs,imgs=imgs,rngz=rngz,rmshift=rmshift,$
fit=fit,frng=frng,transp=transp,valsx=valsx,wtime=wtime,$
quant=quant,invert=invert,cinvert=cinvert,fixy=fixy,data=data,$
exc=exc,fold=fold,bkg=bkg,smthz=smthz,gm=gm


;processes the entire directory specified by dr (default is current dir)
;data - uf this keyword is set, data s not loaded from the directory but from the data value
;folds
;rmshift - removes offset in the second index (rows)
;x - column values range [min,max]
;z - row values range [min,max]
;graphs - produces a subdir with dI/dV(x) graphs for each z
;allgraphs - as graphs but in the main dir and by different colors
;imgs - produces overview images to the subdir
;eps - produces eps files in the subdir
;fit - fits kondo peaks
;frng - define fit range [low_index,high_index]
;transp - if set, transposes the read array
;chans - shows only selected channels
;pars - draws only selected fit parameters
;valsx - produces profiles across columns at specified x coordinates
;wtime - waits after each fit
;quant - recalculates current to quantum conductance (diverges at zero)
;invert - inverts in the showstack
;cinvert - inverts lockin signal
;fixy - sets y to the same scale
;excitation - sets the far distance excitation, if not, taken from the curve itself
;fold - folds the fwd and bwd channels
;bkg - try to subtract the exponential background (only for PTCDA)
;smthz - smooth in y direction
;gm - gamma correction to the lockin image

cd,current=cwd
if not(keyword_set(dr)) then dr=cwd
if not(keyword_set(pars)) then pars=[-1]

if not(keyword_set(data)) then begin

    ;print,dr
    dirs=getfiles(dr,/dir)
    help,dirs
    files=getfiles(dirs(0),mask='*.dat')
    help,files
	d=sts_toarea(files,bias=bias)
    if(not(keyword_set(transp))) then d=transpose(d,[0,2,1])

	s=size(d)
	if min(bias) ne max(bias) then x=bias else $
	if not(keyword_set(x)) then x=indgen(s(2)) else x=findgen(s(2))/(s(2)-1)*(x[1]-x[0])+x[0]
	if not(keyword_set(z)) then z=reform(d(0,0,*))*1e12 else z=findgen(s(3))/(s(3)-1)*(z[1]-z[0])+z[0]
help,z
print,z
    ;help,x
    ;help,z

    ndir=n_elements(dirs)

    if ndir gt 1 then $
    for i=1,ndir-1 do begin
	dirs=getfiles(dr,/dir)
	files=getfiles(dirs(i))
	dn=sts_toarea(files)
	if(not(keyword_set(transp))) then dn=transpose(dn,[0,2,1])
	d=addstacks(d,dn)
    end else d=reform(d,1,s(1),s(2),s(3))

    ;help,d

    ;end
    if keyword_set(fold) then df=fold_stack(d) else df=d
    if keyword_set(smthz) then df=zsmooth(df,smthz)
    if keyword_set(bkg) then df=background2(df)

    if keyword_set(rmshift) then dfr=rmshift(df,chan=rmshift,/missing) else dfr=df
;    dfr=d
end else begin

    dfr=data.data
    x=data.x
    z=data.z
end
s=size(dfr)

    if not(keyword_set(frng)) then frng=[0,s(3)-1] 

    if not(keyword_set(wtime)) then wtime=0 
    if (keyword_set(rngz)) then begin
    loz=getind(z,rngz(0))
	hiz=getind(z,rngz(1))
	rngz=indgen(abs(hiz-loz)+1)+loz
    end else rngz=indgen(s(4))



    if not(keyword_set(chans)) then chans=indgen(s(2))

bkdfr=dfr
s=size(dfr)
;help,dfr
    if keyword_set(invert) then invert=-1 else invert=1

;lockin
    if keyword_set(cinvert) then dfr(*,2,*,*)=(abs(dfr(*,2,*,*)))
;current to quantum conductance or just brings it to nA range
    varr=mreplicate(x*1E-3,s(4))
    ;help,varr
    G0=7.7480917346E-5
    if keyword_set(quant) then for i=0,s(1)-1 do dfr(i,1,*,*)=dfr(i,1,*,*)/varr/G0 else dfr(*,1,*,*)=dfr(*,1,*,*)*1E9

;excitation
    k=540000*2
    Q=31000 ;q-factor
    conversion=6.24150934E18
    amp=60E-12

    if not(keyword_set(exc)) then begin
	exc=dblarr(s(1))
	for i=0,s(1)-1 do exc(i)=mmean(dfr(i,6,*,*),/nan) ;takes first value in every curve (has to be the distant part)
    end
    print,exc
    for i=0,s(1)-1 do dfr(i,6,*,*)=(dfr(i,6,*,*)/exc(i)-1)*!PI*k*amp^2/Q*conversion

;df 2x integrate
    fint=reform(dfr(*,5,*,*),s(1),s(3),s(4))
    ;help,fint
    sfint=size(fint)
    f0=990000

    for j=0,sfint(1)-1 do begin
	for i=0,sfint(2)-1 do fint(j,i,*)=(fint(j,i,*)-mmean(fint(j,i,sfint(3)-60:sfint(3)-40),/nan))
	for i=50,sfint(3)-1 do fint(j,*,i)=fint(j,*,i)+fint(j,*,i-1)
	for i=50,sfint(3)-1 do fint(j,*,i)=fint(j,*,i)+fint(j,*,i-1)
    end
    
    dfr(*,3,*,*)=fint*(-2*k/f0)*conversion*((max(z,/nan)-min(z,/nan))/n_elements(z)*1E-12)^2 ;energy calculation from the stiffness and f0

dfrs=dfr


if keyword_set(imgs) then begin
    window,0,xs=200*s(1),ys=n_elements(chans)*200
    showstack,invert*dfrs(*,*,*,rngz),chans,x,z(rngz)
    a=tvrd(0,true=1)
    a=reverse(a,3)
    write_png,dr+'/overview.png',a
end

nvalsx=n_elements(valsx)
if keyword_set(fit) then begin
    ;help,mreplicate(frng,s(1))
    fdfr=fit_stack(dfr(*,*,*,rngz),2,x,z(rngz),ranges=mreplicate(frng,s(1)),/plt,wtime=wtime)
    spar=size(fdfr.par)
	for i=0,spar(1)-1 do begin
	    openw,1,'fit_'+strtrim(string(i),2)+'.dat',width=250
		for j=0,spar(3)-1 do printf,1,[fdfr.z(j),reform(fdfr.par(i,*,j)),total((fdfr.data(i,*,j)-fdfr.fit(i,*,j))^2,/double,/nan)]
	    close,1
	end
end


if not(keyword_set(fit)) then fdfr={fit:0,x:x,z:z(rngz),par:0}

for i=0,nvalsx-1 do begin
    draw_all,fdfr,dfr,pars,chans,rng=rngz,xval=valsx(i),fixy=fixy,quant=quant
    a=tvrd(0,true=1)
    a=reverse(a,3)
    vval=strtrim(string(valsx(i),format='(F05.1)'),2)
    nmb=string(i,format='(I04)')
    write_png,dr+'/profile_'+nmb+'_'+vval+'.png',a
end




if keyword_set(graphs) then for i=0,s(1)-1 do video2,(dfrs(*,*,*,rngz)),i,x,z(rngz),dirnm=dirs(i),chans=chans,fixy=fixy,fit=fdfr
if keyword_set(allgraphs) then video2,(dfrs(*,*,*,rngz)),0,x,z(rngz),dirnm=dr,chans=chans,fixy=fixy,fit=fdfr,/all

if keyword_set(eps) then begin
    set_plot,'ps'
    device,/encapsul,/color,filename=dr+'/overview.eps',xsize=s(1)*2,ysize=8
    showstack,invert*dfrs(*,*,*,rngz),chans,x,z(rngz)
    device,/close
    set_plot,'X'
end



if keyword_set(imgs) then begin

    window,0,xs=s(1)*200,ys=200
    dfrs=dfr
    for j=0,s(1)-1 do for i=0,s(4)-1 do dfrs(j,2,*,i)=(dfrs(j,2,*,i)-min(dfrs(j,2,*,i)))/(max(dfrs(j,2,*,i))-min(dfrs(j,2,*,i)))
    rng=rngz
    ;showstack,dfrs(*,*,*,rng),[2],x,z(rng)
    showstack,invert*abs(dfrs(*,*,*,rng))^gm,[2],x,z(rng)
    a=tvrd(0,true=1)
    a=reverse(a,3)
    write_png,dr+'/overview_scaled.png',a
end

if keyword_set(eps) then begin
    set_plot,'ps'
    device,/encapsul,/color,filename=dr+'/overview_scaled.eps',xsize=s(1)*2,ysize=2
    showstack,invert*abs(dfrs(*,*,*,rng)),[2],x,z(rngz),/eps
    device,/close
    set_plot,'X'
end
;help,dfr
;if keyword_set(fit) then begin
;    ;help,mreplicate(frng,s(1))
;    fdfr=fit_stack(dfr,2,x,z(*),ranges=mreplicate(frng,s(1)),/plt,wtime=wtime)
;    spar=size(fdfr.par)
;	for i=0,spar(1)-1 do begin
;	    openw,1,'fit_'+strtrim(string(i),2)+'.dat'
;		for j=0,spar(3)-1 do printf,1,[fdfr.z(j),reform(fdfr.par(i,*,j)),total((fdfr.data(i,*,j)-fdfr.fit(i,*,j))^2,/double,/nan)]
;	    close,1
;	end
;end


;nvalsx=n_elements(valsx)


;if not(keyword_set(fit)) then fdfr={fit:0,x:x,z:z(rngz),par:0}

;for i=0,nvalsx-1 do begin
;    draw_all,fdfr,dfr,pars,chans,rng=rngz,xval=valsx(i),fixy=fixy,quant=quant
;    a=tvrd(0,true=1)
;    a=reverse(a,3)
;    vval=strtrim(string(valsx(i),format='(F05.1)'),2)
;    nmb=string(i,format='(I04)')
;    write_png,dr+'/profile_'+nmb+'_'+vval+'.png',a
;end

return,{data:bkdfr,z:z,x:x}
end

function background,t
;tries to figure out a background by an exponential decay for channel 2 (=dIdV)
;and to subtract it
;very specific for PTCDA, experimental
nt=t
s=size(t)
for i=0,s(1)-1 do begin
    d=reform(t(i,2,*,*))
    sd=size(d)
    i1=0 ;positions from where to take the bkg
    i2=sd(2)-1
    p1=smooth(d(*,i1),5)
    p2=smooth(d(*,i2),5)
    k=-alog(p1/p2)/double(i1-i2) ;using index for simplicity
    a=p1/exp(-k*i1)
    ee=dblarr(sd(1),sd(2))
    for j=0,sd(1)-1 do begin ;for each voltage...
	e=a(j)*exp(-(k(j))*dindgen(sd(2))) ; base exponential decay
	ee(j,*)=e
    end
    nt(i,2,*,*)-=ee ;remove the background
end

return,nt
end


function background2,t
;tries to figure out a background by an exponential decay for channel 2 (=dIdV)
;and to subtract it
;very specific for PTCDA, experimental
nt=t
s=size(t)
for i=0,s(1)-1 do begin
    d=reform(t(i,2,*,*))
    help,d
    sd=size(d)
    i1=200 ;x positions from where to where take the bkg
    i2=250
    e=total(d(i1:i2,*),1) ;gives an average form
    ;e=e-min(e) ;let's normalize it
    ;e=e/max(e)
;    help,e
    j1=5
    j2=10 ;y indices where the curve should be matched to data
    p1=total(d(*,j1:j2),2)
;    p2=smooth(d(*,j2),5)
;    help,p1
;    k=(p1-p2)/(e(j1)-e(j2))
    k=p1/total(e(j1:j2))
;    plot,k
;    a=p1-k*e(j1)
;    help,a
    ee=dblarr(sd(1),sd(2))
    for j=0,sd(1)-1 do begin ;for each voltage...
	et=k(j)*e;+mean(a(i1:i2)) ; base decay
	ee(j,*)=et
    end
    nt(i,2,*,*)-=ee ;remove the background
end

return,nt
end

function zsmooth,t,smth
nt=t
s=size(t)
for i=0,s(1)-1 do begin
    d=reform(t(i,2,*,*))
    sd=size(d)
    for j=0,sd(1)-1 do begin ;for each voltage...
	d(j,*)=smooth(reform(d(j,*)),smth) ; base decay
    end
    nt(i,2,*,*)=d
end

return,nt
end

pro dataexp,st
d=st.data
s=size(d)
for i=0,s(1)-1 do begin
    for j=0,s(4)-1 do begin
	f=strtrim(string(i),2)+'_'+strtrim(string(j,format='(I03)'),2)+'.dat'
	openw,1,f
	    for k=0,s(3)-1 do printf,1,st.x(k),d(i,2,k,j)
	close,1
    end
end
end


pro ternes_fit_dump
f=getfiles('.')
n=n_elements(f)
for i=0,n-1 do begin
ex=loadnanonis_sts(f(i))
th=read_file('fit/'+f(i)+'.fit',/array,/igcom)
thd=splitcols(th)


plot,ex.data(0,*),-ex.data(2,*),xst=1
oplot,thd(0,*)/1000,thd(1,*)

wait,0.1
end

end

pro kondo_save,dir,t
;saves to separate folders, files by heights
s=size(t.data)
cd,curr=curr
cd,dir
file_mkdir,'export'
cd,'export'
for b=0,s(1)-1 do begin
	dr=strtrim(string(b+1,format='(I1)'),2)
	file_mkdir,dr
	cd,dr
	for z=0,s(4)-1 do begin
		zs=string(t.z(z),format='(F05.1)')
		openw,1,'Bias_spectroscopy_'+dr+'_'+zs+'.dat',width=320
;		printf,1,'[DATA]'	
;		printf,1,"Bias calc (V)	Current (A)	Input 2 (V)	Z (m)	Amplitude (m)	Frequency Shift (Hz)	Excitation (V)	LIX 1 omega (A)	LIY 1 omega (A)"	
		for v=0,s(3)-1 do begin
			vlt=string(t.x(v))
;			for ch=1,s(2)-1 do begin
;				line=line+string(t.data(b,ch,v,z))
;				if ch ne s(2)-1 then line=line+' ';string(9B) 
;				
;			end
			printf,1,t.x(v),reform(t.data(b,1:*,v,z))
		end
		close,1
	end
	cd,'..'
end
cd,curr
end
