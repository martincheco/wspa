function lumi_load,f,asc=asc

if not(keyword_set(asc)) then begin
sp=loadnanonis_sts(f,/silent)
stub=file_basename(f,'.dat')

num=fix(strmid(stub,3,/reverse))

curr=double(getvalns(sp.p.par,'Current avg. (A)'))
;help,curr

;return,{i:sp.data(1,*),x:sp.data(0,*),curr:curr,num:num,par:sp.p.par}
return,{i:sp.data(2,*),x:sp.data(0,*),curr:curr,num:num,par:sp.p.par}

end else begin



sp=read_ascii(f)

stub=file_basename(f,'.asc')
num=fix(strmid(stub,3,/reverse))

data=sp.(0)

return,{i:data(1,*),x:data(1,0:*),curr:0,num:num,par:''}

end

end

function lumi_mapfix,d,lne,x,y
;fixes a broken image
;curr defines a 

dfixa=shift(d.map,x,y,0)
dfixb=d.map
s=size(d.map)

for j=lne,s(2)-1 do begin
	dfixb(*,j,*)=dfixa(*,j,*)

end

return,{map:dfixb,num:d.num,par:d.par,x:d.x,curr:d.curr}
end


function lumi_rollbase,d,rz,rx,niter,zrange=zrange,heat=heat,vis=vis

if not(keyword_set(zrange)) then zrange=[0,-1]
;if not(keyword_set(heat)) then heat=0.002

bkz=0
bkxy=0

if where(Tag_Names(d) EQ StrUpcase('fit')) ne -1 then begin
	if where(Tag_Names(d.fit) EQ StrUpcase('bkz')) ne -1 then begin
		print,'bkz found'
		bkz=d.fit.bkz
	end
	if where(Tag_Names(d.fit) EQ StrUpcase('bkxy')) ne -1 then begin
		bkxy=d.fit.bkxy
		print,'bkxy found'
	end
	map=d.omap ;takes the original map instead of the new one
	help,d	
	print,'Used the original map'
end else map=d.map ;first run

bkg=rollb(transpose(map(*,*,zrange[0]:zrange[1]),[2,0,1]),rz,rx,niter,bkxy=bkxy,bkz=bkz,zheat=0,xheat=heat,vis=vis)

bkgt=transpose(bkg,[1,2,0]) ;strangely written rollb function, have to transpose

bkgte=map

bkgte(*,*,zrange[0]:zrange[-1])=bkgt ;because of zrange
help,bkgte

return,{map:map-bkgte,num:d.num,par:d.par,x:d.x,curr:d.curr,omap:map,fit:{fits:bkgte,bkz:bkz,bkxy:bkxy}}
end

function lumi_rollbase2,d,rz,rx,smth=smth


bkg=roll_bkg_3d(d.map(*,*,*),rz,rx,smth=smth)



return,{map:d.map-bkg,num:d.num,par:d.par,x:d.x,curr:d.curr,omap:d.map,fit:{fits:bkg}}
end




function lumi_mbaseline,d,width=width,whr=whr,show=show,sgm=sgm,niter=niter,interactive=interactive
;performs multisegment fitting
;whr defines the areas to latch on
;width is the savgol width (as fit in baseline function)
;sgm - indices denoting the segments to fit separately (first and last are added automatically at the ends of the range)
;niter - number if iterations in fitting
;interactive - lets you select the segments


s=size(d.map)

totd=total(total(d.map,1,/double,/nan),1,/double,/nan)/double(s(1))/double(s(2)) ;calculate average

if keyword_set(interactive) then begin
	f=findgen(s(3))
	plot,f,totd,xst=1
	xxx=0L
	xx=0L
	while xx lt s(3) do begin
		cursor,xx,yy,/up,/data
		print,xx
		if xx lt s(3)-1 then begin
			ii=((indgen(width)+xx-width/2)>0)<(s(3)-1)
			oplot,ii,totd(ii)*0,color=128,psym=1
			plots,xx,totd(xx)*0,color=255,psym=2
			xxx=[xxx,xx]
		end
	end
	xxx=xxx(1:*)
	print,xxx
	sgm=xxx
	whr=0
	for i=0,n_elements(sgm)-1 do $
		whr=[whr,((sgm(i)+indgen(width)-width/2)>0)<(s(3)-1)]
	
	whr=whr(1:*)
end




if keyword_set(sgm) then sgm=[0,sgm,s(3)-1] else sgm=[0,s(3)-1]
ns=n_elements(sgm)

nmap=d.map*0
bkg=nmap

f=findgen(s(3))
if keyword_set(show) then begin
	plot,f,totd,xst=1
	oplot,f(whr),f(whr)*0,color=128,psym=1
	oplot,f(sgm),f(sgm)*0,color=255,psym=2
	wait,2.
end
	
for i=0,ns-2 do begin
	print,"Segment #",strtrim(string(i),2)
	a=sgm(i)
	b=sgm(i+1)
	whrsel=where(whr ge a-width and whr lt b+width)
	r=lumi_baseline(d,fit=width,whr=whr(whrsel),rng=[a,b-1],show=show,niter=niter)
	nmap(*,*,a:b-1)=r.map(*,*,a:b-1)
	bkg(*,*,a:b-1)=r.fit.fits(*,*,a:b-1)
end

fit={fits:bkg}

return,{map:nmap,num:d.num,par:d.par,x:d.x,curr:d.curr,fit:fit}

end

function lumi_baseline,d,shirley=shirley,individual=individual,linear=linear,med=med,rng=rng,fit=fit,crv=crv,show=show,whr=whr,spl=spl,niter=niter
;performs background subtraction
;default is subtracting min

;shirley substacts integrated shirley bkg
;individual - subtracts each curve individually
;linear - apply linear type bkg (not implemented)
;med - apply median 
;rng - use range for calculating the bkg

;SPECIAL FITTING OPTIONS FOR FACTORIZATION
;fit - use fitting, vlaue defines savgol filter width (for creating curve for factorization)
;crv - supply own curve for factorization (has to have equal no. of elements as the input)
;show - show the fitting procedure
;whr - areas at the factorization curve to latch on
;spl - use spline (sometimes gets loco)

s=size(d.map)
nstk=d.map
fitres={amps:-1,offs:-1,fits:-1}
if keyword_set(individual) then ind=1 else ind=0
if keyword_set(rng) then begin
	rng1=rng(0)>0
	rng2=rng(1)<(s(3)-1)
	print,"RANGE: ",rng1,rng2
end else begin
	rng1=0
	rng2=s(3)-1
end

if keyword_set(shirley) then begin
	stk=transpose(d.map,[2,0,1])
	print,'shirley bkg'
	nstk=transpose(stackshirley(stk,individual=individual,/rev),[1,2,0])
end else $
if keyword_set(fit) then begin
	fits=nstk
	f=findgen(s(3))
	amps=dblarr(s(1),s(2))
	offs=dblarr(s(1),s(2))
	if keyword_set(crv) then begin 
		fitcrv=crv 
		wh=[lindgen(rng1>1),lindgen(s(3)-rng2)+rng2]
		if keyword_set(whr) then wh=whr 
	end else begin
		totd=total(total(d.map,1,/double,/nan),1,/double,/nan)/double(s(1))/double(s(2)) ;calculate average
		width=(fit>5)<s(3)/2
		print,"Using filter width: ",width
		f=findgen(s(3))
		totdf=dezofilter(f,totd,width=width,/savg)
		atotdif=abs(totd-totdf)
		atotdiff1=smooth([fltarr(4*width)*atotdif(0),atotdif,fltarr(4*width)*atotdif(-1)],4*width,/edge_wrap)
		atotdiff=atotdiff1(4*width:-4*width-1)
		if keyword_set(whr) then wh=whr else begin
			wh=where(atotdiff lt 1.1*median(atotdiff))
			wh=wh(where(wh gt max([1,rng1]) and wh lt min([(s(3)-1),rng2])))
		end
		if wh(0) ne -1 then begin
			fitcrv=interpol(totdf(wh),f(wh),f,spline=spl)
		end else begin
			print,"ERROR: no fittable regions found!"
			fitcrv=f*0.
		end
		if keyword_set(show) then begin
			plot,f,totd,xst=1
			oplot,f,fitcrv,color=128
			oplot,f,totd-fitcrv
			oplot,f(wh),f(wh)*0,color=128,psym=1
			wait,2.
		end
	end
;	c=0B
	for i=0,s(1)-1 do for j=0,s(2)-1 do begin
;		if round(10*float(i*s(2)+j)/s(1)/s(2)) gt c then begin
;			if c ge 9 then print,c,Format='(I1.0)' else	print,c,Format='(I1.0, $)'
;			c++
;		end
		pres=factorize(reform(nstk(i,j,wh)),reform(fitcrv(wh)),niter)
		if keyword_set(show) then plot,f,nstk(i,j,*),yst=1,xst=1
		bkg=pres.amp*fitcrv+pres.off
		nstk(i,j,*)-=bkg
		fits(i,j,*)=bkg
		amps(i,j)=pres.amp
		offs(i,j)=pres.off
		if keyword_set(show) then begin
			oplot,f,bkg,color=128
			oplot,f(wh),bkg(wh),psym=1,color=128
		end
		print,string(13B),round(100*float(i*s(2)+j)/s(1)/s(2)),format='(A,I3,"%",$)'
	end
	print
	fitres={fits:fits,amps:amps,offs:offs}

end else $
	if ind gt 0 then $ 
		if keyword_set(med) then begin	
			print,'individual median'
			for i=0,s(1)-1 do for j=0,s(2)-1 do nstk(i,j,*)-=median(reform(nstk(i,j,rng1:rng2)),s(3)/5.) 
		end $
		else begin
			print,'individual minimum'
			for i=0,s(1)-1 do for j=0,s(2)-1 do nstk(i,j,*)-=min(nstk(i,j,rng1:rng2)) 
	end $
	else $
		if keyword_set(med) then begin
			print,'global median'
			nstk-=median(nstk(*,*,rng1:rng2))
		end else begin
			print,'global minimum'
			nstk-=min(nstk(*,*,rng1:rng2))
		end
	

return,{map:nstk,num:d.num,par:d.par,x:d.x,curr:d.curr,omap:d.map,fit:fitres}
end

function lumi_corr,d,x,y,thr=thr,iter=iter,export=export,weight=weight,avg=avg,rng=rng
;returns average curve according to the correlation with the curve at x,y
;uses the function stackcorrelations
;iter iterates to get mutually correlating curves
;user is responsible for the baskground subtraction
;thr - correlation threshold for averaging
;avg - averages around the point with avg radius

stk=transpose(d.map,[2,0,1])

s=size(d.map)
print,s
x=(x<(s(1)-1))>0
y=(y<(s(2)-1))>0
fb=getval(d.par,'Experiment')
if keyword_set(avg) then begin
	avg=(avg>0)
	corrs=dblarr(s(1),s(2))
	corrs((x-avg)>0:(x+avg)<(s(1)-1),(y-avg)>0:(y+avg)<(s(2)-1))=1.
	corrs=reform(corrs,s(1),s(2))
	avgarr=stk(*,(x-avg)>0:(x+avg)<(s(1)-1),(y-avg)>0:(y+avg)<(s(2)-1))
	avg=dblarr(s(3))
	help,avgarr
	for i=0,s(3)-1 do avg(i)=total(avgarr(i,*,*),/nan)
	res={avg:avg/total(corrs,/nan),i:x,j:y,diameter:avg,corrs:corrs,x:d.x}
end else if keyword_set(thr) then begin
		thr=(thr>0.)<1.
		res=stackcorrelations(stk,x,y,thr=thr,iter=iter,weight=weight,rng=rng)
		avg=res.avg
	end else begin
		avg=stk(*,x,y)
		res={avg:avg,i:x,j:y,diameter:0,corrs:-1,x:d.x}
	end

if keyword_set(export) then begin
	print,export
	export=string(export)
	fnm=fb+'_corravg_'+strtrim(string(x),2)+'_'+strtrim(string(y),2)+'_'+export
	print,fnm
	openw,1,fnm+'.xey'
		for i=0,s(3)-1 do printf,1,d.x(i),1240./d.x(i),avg(i)
	close,1
	openw,1,fnm+'.txt',width=16*s(1)
		for i=0,s(2)-1 do printf,1,res.corrs(*,i)
	close,1
end

return,res
end


function lumi_despk,d,tol=tol,wid=wid
;runs a despiker on all spectra

s=size(d.map)

map=d.map

for i=0,s(1)-1 do for j=0,s(2)-1 do begin
	map(i,j,*)=despk(reform(map(i,j,*)),tol=tol,wid=wid)
end

return,{map:map,num:d.num,par:d.par,x:d.x,curr:d.curr}
end


function lumi_despk2d,d,tol,dry=dry
;runs a despiker on 2d slices
;dry run sends detected spikes to zero

s=size(d.map)
print,s
map=d.map
med=dblarr(s(3))

mn=min(map)

if keyword_set(dry) then fact=0. else fact=1.

for i=0,s(3)-1 do begin
	sl=reform(map(*,*,i))
	med=filter_image(sl,median=5,/all_pixels)
;	med(i)=median(sl,/double,/even)
;	w=where((sl-med(i)) gt tol)
	w=where((sl-med) gt tol)
	if w(0) ne -1 then begin
		sl(w)=med(w)*fact+mn*(1.-fact)
		map(*,*,i)=sl
	end
end

return,{map:map,num:d.num,par:d.par,x:d.x,curr:d.curr,med:med}
end



function lumi_loadsxm,f


if (f(0)) ne '' then begin
	spectrum=1
	a=loadnanonis(f(0),spectrum=spectrum)
	x=reform(spectrum(0,0,1,*)) ;dirty trick so far
	map=reform(spectrum(*,*,0,*))
	par=a(-1).par
	par(0)=strmid(par,0,strpos(par(0),'.sxm'))
	par(0)='Experiment '+strmid(par(0),10)
	print,par(0)
;	par=par(1:*)
	w=where(strmatch(a(*).par(15),'*Curr*',/fold_case))
	if w(0) ne -1 then curr=a(w(0)).img else curr=a(0).img
	s=size(curr)
	num=reform(indgen(s(1)*s(2)),s(1),s(2))

end else return,0

return,{map:map,num:num,x:x,par:par,curr:curr}
end

function lumi_load3ds,f,chnl=chnl
;reads 3ds grid, assumes wavelength info in the file and only one channel of measurements



if (f(0)) ne '' then begin
	a=load3ds(f(0))
	s=size(a.stack)
	if keyword_set(chnl) then begin
		if chnl lt 0 or chnl gt s(2)-1 then chnl=0 
		print,'Using channel: ',chnl
	end else chnl=0
	map=reform(a.stack(*,chnl,*,*))
	map=transpose(map,[1,2,0])
	fname=getval(a.par,"Filename: ")
	fname=strtrim(fname,2)
	par0=strmid(fname,0,strpos(fname,'.3ds'))
	par0='Experiment '+strmid(par0,10)
	print,par0
	par=[par0,a.par(1:*)]
	s=size(map)
	num=reform(indgen(s(1)*s(2)),s(1),s(2))
	w=where(strmatch(a.par,'wl*'))
	help,w
	help,s(3)
	n=n_elements(w)
	x=dindgen(s(3))
	if w(0) ne -1 and n eq s(3) then begin
		print,'extracting the wavelengths'
		for i=0,n-1 do begin
			lne=getval(a.par,'wl '+strtrim(string(i),2)+'=')
			x(i)=double(lne)
		end

	end else print,'Wavelengths not found or not matching the z-size of the array!'



end else return,0

return,{map:map,num:num,x:x,par:par,curr:fltarr(s(1),s(2))}
end



function lumi_loadstack,f,srt=srt,m=m,asc=asc,chnl=chnl
;reads the data, can distinguish between .sxm, .3ds or set made of individual curves
;srt sorts the files according to the number

if strmatch(f(0),'*.sxm') then begin

return,lumi_loadsxm(f)
end

if strmatch(f(0),'*.3ds') then begin

return,lumi_load3ds(f,chnl=chnl)
end



if (f(0)) ne '' then begin
	
	a=lumi_load(f(0),asc=asc)
	help,a.i	
	n=n_elements(f)
	map=fltarr(n,n_elements(a.i))
	map(0,*)=a.i
	x=a.x
	if n_elements(a.par) gt 1 then par=a.par(1:*) else par=''
	num=lonarr(n)
	num(0)=a.num
	curr=dblarr(n)
	curr(0)=a.curr


	for i=1,n-1 do begin
		print,f(i)
		a=lumi_load(f(i),asc=asc)
		map(i,*)=a.i
		num(i)=a.num
		curr(i)=a.curr
	end
	if keyword_set(srt) then begin
		sr=sort(num)
		print,sr
		num=num(sr)
		map=map(sr,*)
		curr=curr(sr)
	end

	s=size(map)
	print,s
	if keyword_set(m) then begin
		nn=fix(m)*(fix(n_elements(map(*,0)))/fix(m))
		help,nn
		help,nn/m
		map=map(0:nn-1,*)
		num=num(0:nn-1)
		curr=curr(0:nn-1)
		s=size(map)
		map=reform(map,m,nn/m,s(2))
		
		num=reform(num,m,nn/m)
		curr=reform(curr,m,nn/m)
	end else begin
		map=reform(map,n,1,s(2))
		num=reform(num,n,1)
		curr=reform(curr,n,1)
	end

end else p=-1

return,{map:map,num:num,x:x,par:par,curr:curr}
end



function lumi_int,dt,aa,bb,replicate=replicate,ev=ev,nm=nm,cm=cm
;replicate extends the data all over the spectral range

map=dt.map


if keyword_set(nm) then vals=dt.x
if keyword_set(ev) then vals=1240./dt.x
if keyword_set(cm) then vals=nm2cm(dt.x,exc=cm)


if keyword_set(nm) or keyword_set(ev) or keyword_set(cm) then begin
	daa=abs(vals-aa)
	dbb=abs(vals-bb)
	wa=where(daa eq min(daa))
	wb=where(dbb eq min(dbb))
	a=min([wa(0),wb(0)])
	b=max([wa(0),wb(0)])

end else begin
	a=aa
	b=bb
end

print,'a,b,b-a+1:',a,b,b-a+1
print,'aa,bb:',aa,bb

s=size(map)
if not(keyword_set(replicate)) then $
return,total(reform(double(map(*,*,a:b)),s(1),s(2),b-a+1),3,/double,/nan)$;/(b-a+1)$ 
else begin
mapn=map
slice=total(double(reform(map(*,*,a:b),s(1),s(2),b-a+1)),3,/double,/nan);/(b-a+1) 
for i=0,s(3)-1 do mapn(*,*,i)=slice
return,mapn 
end

end

function lumi_smooth,data,w,svg=svg

s=size(data.map)
nmap=double(data.map)

    if keyword_set(svg) then begin
	sg=savgol(w,w,0,4)
        for i=0,s(1)-1 do for j=0,s(2)-1 do begin
		nmap(i,j,*)=convol(reform(data.map(i,j,*)),sg,/edge_wrap)
        end
    end else $
	for i=0,s(1)-1 do for j=0,s(2)-1 do begin
	    nmap(i,j,*)=smooth(reform(data.map(i,j,*)),w)
        end


return,{map:nmap,num:data.num,par:data.par,x:data.x}
end


function lumi_mapsmooth3d,map,w,h
	s=size(map)
	ww=round(w)/2
	hh=round(h)/2
	enmap=dblarr(s(1)+2*ww,s(2)+2*ww,s(3)+2*hh)
	;stupid wrapping, bcause stupid gdl implementation of smooth

	enmap(ww:-ww-1,ww:-ww-1,hh:-hh-1)=map
	for i=0,hh-1 do begin
		enmap(ww:-ww-1,ww:-ww-1,i)=map(*,*,0)
		enmap(ww:-ww-1,ww:-ww-1,-i-1)=map(*,*,-1)
	end

	for i=0,ww-1 do begin
		enmap(i,ww:-ww-1,*)=enmap(ww,ww:-ww-1,*)
		enmap(-i-1,ww:-ww-1,*)=enmap(-ww-1,ww:-ww-1,*)
		enmap(ww:-ww-1,i,*)=enmap(ww:-ww-1,ww,*)
		enmap(ww:-ww-1,-i-1,*)=enmap(ww:-ww-1,-ww-1,*)
	end

	for i=0,ww-1 do for j=0,ww-1 do begin
		enmap(i,j,*)=enmap(ww,ww,*)
		enmap(-i-1,-j-1,*)=enmap(-ww-1,-ww-1,*)
		enmap(i,-j-1,*)=enmap(ww,-ww-1,*)
		enmap(-i-1,j,*)=enmap(-ww-1,ww,*)
	end


	nmap=smooth(enmap,[w,w,h])



return,nmap(ww:-ww-1,ww:-ww-1,hh:-hh-1)
end



function lumi_smooth3d,data,w,h
	s=size(data.map)
	ww=round(w)/2
	hh=round(h)/2
	enmap=dblarr(s(1)+2*ww,s(2)+2*ww,s(3)+2*hh)
	;stupid wrapping, bcause stupid gdl implementation of smooth

	enmap(ww:-ww-1,ww:-ww-1,hh:-hh-1)=data.map
	for i=0,hh-1 do begin
		enmap(ww:-ww-1,ww:-ww-1,i)=data.map(*,*,0)
		enmap(ww:-ww-1,ww:-ww-1,-i-1)=data.map(*,*,-1)
	end

	for i=0,ww-1 do begin
		enmap(i,ww:-ww-1,*)=enmap(ww,ww:-ww-1,*)
		enmap(-i-1,ww:-ww-1,*)=enmap(-ww-1,ww:-ww-1,*)
		enmap(ww:-ww-1,i,*)=enmap(ww:-ww-1,ww,*)
		enmap(ww:-ww-1,-i-1,*)=enmap(ww:-ww-1,-ww-1,*)
	end

	for i=0,ww-1 do for j=0,ww-1 do begin
		enmap(i,j,*)=enmap(ww,ww,*)
		enmap(-i-1,-j-1,*)=enmap(-ww-1,-ww-1,*)
		enmap(i,-j-1,*)=enmap(ww,-ww-1,*)
		enmap(-i-1,j,*)=enmap(-ww-1,ww,*)
	end

;		enmap(ww:-ww-1,ww:-ww-1,hh:-hh-1)=data.map

	nmap=smooth(enmap,[w,w,h])

	if where(Tag_Names(data) EQ StrUpcase('fit')) ne -1 then begin
		return,{map:nmap(ww:-ww-1,ww:-ww-1,hh:-hh-1),num:data.num,par:data.par,x:data.x,curr:data.curr,fit:data.fit}
	end else begin
		return,{map:nmap(ww:-ww-1,ww:-ww-1,hh:-hh-1),num:data.num,par:data.par,x:data.x,curr:data.curr}
	end
end

function lumi_redshift,data,x,y,a
;will shift energies by a parabolic function
	s=size(data.map)
	d=-shift(dist(2*s(1),2*s(2)),s(1),s(2))
	d=a*d^2.
	d=d(0.5*s(1)-x:1.5*s(1)-1-x,0.5*s(2)-y:1.5*s(2)-1-y)
	tvscl,d
	d=d-mean(d)
	nmap=data.map
	for i=0,s(1)-1 do for j=0,s(2)-1 do begin
		nmap(i,j,*)=shift(reform(nmap(i,j,*)),d(i,j))
	end

return,{map:nmap,num:data.num,par:data.par,x:data.x,curr:data.curr}
end



function lumi_norm,data,smthh,smthz,zrange=zrange,thr=thr,min=min
;normalizes, assuming that Intensity= Photon_map * Current * Plasmon + Plasmon * Current
;data is fitted data (Intensity - Current * Plasmon), and includes the background fit (Current*Plasmon)
;result will be fdata / Current*Plasmon
;smth smoothes by 3D the bkg in Z
;zrange selects the range for determining the absolute minimum 
;thr is bkg intensity threshold for where to not calculate the result
;min - if min is set, it does use it

fit=data.fit.fits
map=data.map

if keyword_set(smthh) and keyword_set(smthz) then begin
	fit=lumi_mapsmooth3d(fit,smthh,smthz) 
	map=map+data.fit.fits-fit
end
if(keyword_set(zrange)) then fitr=fit(zrange[0]:zrange[1]-1) else fitr=fit
mn=min(fitr(where(fitr)))
mx=max(fitr(where(fitr)))
help,mn
help,mx

if keyword_set(min) then mn=min else mn=mn-1. ;to avoid division by zero

nmap=(map)/(fit-mn)
if keyword_set(thr) then begin
	fitnm=(fit-mn)/(mx-mn)
	w=where(abs(fitnm) lt thr)
	if w(0) ne -1 then nmap(w)=0 
	nmap=nmap

end
return,{map:nmap,num:data.num,par:data.par,x:data.x,curr:data.curr,fit:data.fit}
end



function lumimap,mask,m=m,fname=fname,asc=asc,bkg=bkg,filt=filt,chnl=chnl
;mask - mask for spectral maps
;m number of columns
;f - specific files

help,fname
;print,fname


if keyword_set(fname) then $
d=lumi_loadstack(fname,/srt,m=m,asc=asc) $
else $
if keyword_set(mask) then d=lumi_loadstack(getfiles(mask=mask),/srt,m=m,asc=asc) else d=lumi_loadstack(dialog_pickfile(/multi,filt=filt),/srt,m=m,asc=asc,chnl=chnl)

dm=d.map(*,0:-1,*)
	
bk=dm
help,dm
s=size(dm)
;bk1=reform(total(d.map(*,0,*),1,/double))/s(1)
;for i=0,s(1)-1 do for j=0,s(2)-1 do bk(i,j,*)=bk1



;curr3=dblarr(s(1),s(2),s(3))

;for i=0,s(3)-1 do curr3(*,*,i)=d.curr

return,{map:dm,curr:d.curr,nmap:-1,par:d.par,x:d.x,num:d.num}
end

function lumi_bindown3d,data,fact
	nmap=bindown3d(data.map,fact)
	return,{map:nmap,num:data.num,par:data.par,x:data.x,curr:data.curr}
end


pro lumi_vis,data,cub=cub,xx=xx,yx=yx,zx=zx,cm=cm,ev=ev,nm=nm,rott=rott,zrange=zrange,zgraph=zgraph,fit=fit,cut=cut,rebn=rebn,gm=gm
;ev,nm shows Z-values in electronvolts, nanometers
;xx xy xz expansion factors if not autoscale
;cub is for cubic interp
;rott performs rotation by DEG
;zrange - only show a Z-range [from,to]
;zgraph - show a spectrum in a separate win
;fit - show the fitted curve if present in the structure
;cut - cuts the extremes (below zero)
;rebn - rebin down factor
;gm - gamma factor

if keyword_set(cut) then begin
	cut0=cut(0)
	cut1=cut(1)
end else begin
	cut0=-9E99
	cut1=9E99
end

if keyword_set(fit) then begin;and where(Tag_Names(data) EQ StrUpcase('fit')) then begin
	print,'fitted BKG found, displaying..'
	help,data.fit.fits
	dt=data.fit.fits 
end else begin
	print,'fitted BKG NOT found, displayin the map..'
	dt=data.map
end
s=size(dt)
if not(keyword_set(xx)) then begin
	xx=round(128/((s(1)*s(2))^0.5))
	if not(keyword_set(yx)) then yx=xx
end

if keyword_set(zrange) then begin
	a=zrange(0)
	b=zrange(1)
end else begin
	a=0
	b=s(3)-1
end

if not(keyword_set(zx)) then if (b-a) gt 1023. then zx=1./round((b-a)/512.) else zx=1.

print,s
print,'xx,yx,zx: ',xx,yx,zx

zdist=indgen(s(3))

if keyword_set(rebn) then begin
	dt=bindown3d(dt,rebn)
end

s=size(dt)

if keyword_set(nm) then zdist=data.x
if keyword_set(ev) then zdist=1240./data.x
if keyword_set(cm) then zdist=nm2cm(data.x,exc=cm)


if keyword_set(cub) then begin
	dtz=dblarr(s(1)*xx,s(2)*yx,b-a+1)
	for i=0,b-a do dtz(*,*,i)=congrid(reform(dt(*,*,a+i)),s(1)*xx,s(2)*yx,cubic=-0.5)
	viewstack,(transpose(dtz,[2,0,1])>cut0)<cut1,zx=zx,xx=1,yx=1,/xp,rott=rott,gm=gm

end else viewstack,(transpose(dt(*,*,a:b),[2,0,1])>cut0)<cut1,zx=zx,xx=xx,yx=yx,/xp,zdist=zdist(a:b),rott=rott,zgraph=zgraph,gm=gm


end

function lumi_rebin,map,zm,int=int,cub=cub,smth=smth,thr=thr
;zm - zoom factor
;int - integration range
;nn nearest neighbor resamplng
;smth - smooth+bicubic (1 = no smoothing but bicubic interp.)
;thr - threshold for normalized maps

s=size(map)


if not(keyword_set(zm)) then zm=round(200/s(1))
if not(keyword_set(int)) then int=[630,670] 
if not(keyword_set(smth)) then smth=1

mp=lumi_int(map,int(0),int(1))
if keyword_set(thr) then mp=mp<(mmean(mp)*thr)

if not(keyword_set(cub)) then begin
t=rebin(ftgauss(mp,smth),s(1)*zm,s(2)*zm,/sample)
end else begin
t=congrid(ftgauss(mp,smth),s(1)*zm,s(2)*zm,cubic=-0.5)
end

return,t
end


function lumi_regen,t,extra,cm=cm,nm=nm,ev=ev
;extracts ranges from already exported slices in the active dir

help,extra
f=getval(t.par,'Experiment')
help,f
;f f eq '' then f=file_basename(getval(t.par,'Filename: '),)
r=f+"_"+extra+"_int_*_cm.txt"
help,r
print,r


if keyword_set(cm) then g=getfiles(mask=f+'_'+extra+'_int_*_cm.txt') $
	else if keyword_set(nm) then g=getfiles(mask=f+'_'+extra+'_int_*_nm.txt') $
		else if keyword_set(ev) then g=getfiles(mask=f+'-'+extra+'_int_*_ev.txt') $
			else g=getfiles(mask=f+'-'+extra+'_int_*.txt')

n=n_elements(g)
a=fltarr(n)
b=fltarr(n)

for i=0,n-1 do begin
	gg=strsplit(g(i),'_',/extract)
	ggg=strsplit(gg(-2),'-',/extract)
	print,ggg
	ggg=float(ggg)
	a(i)=ggg(0)
	b(i)=ggg(1)
end


return,{a:a,b:b}
end

pro lumi_exp_slice,t,aa,bb,ev=ev,nm=nm,extra=extra,regen=regen,cm=cm,center=center
;saves the slice integrated between a and b (index, wavel. or eVs), a and b can be arrays
;saves a txt matrix for gnuplot as well
;extra specifies what to add to the name
;regen tries to get as and bs from existing filenames in the dir than contain the string in regen
unit=''
if keyword_set(nm) then unit='nm'
if keyword_set(ev) then unit='ev'
if keyword_set(cm) then unit='cm'


if not(keyword_set(extra)) then extra=""
help,extra

nnn=n_elements(aa)
if n_elements(bb) ne nnn then bb=replicate(bb,nnn)


if keyword_set(regen) then begin
	ab=lumi_regen(t,extra,cm=cm,nm=nm,ev=ev)
	aan=ab.a
	bbn=ab.b
	aa=[aan,aa]
	bb=[bbn,bb]
	nnn=n_elements(aa)
end

if keyword_set(center) then begin
		a=aa-bb
		b=aa+bb
	end else begin
		a=aa
		b=bb
	end



help,extra
for j=0,nnn-1 do begin

	sl=lumi_int(t,float(a(j)),float(b(j)),ev=ev,nm=nm,cm=cm)

	f=getval(t.par,'Experiment')
	if f ne "" then f=f+"_"+extra+'_int_'+strtrim(string(float(aa(j))),2)+'-'+strtrim(string(float(bb(j))),2)+'_'+unit else f=dialog_pickfile()
	print,f

	fstp=f+'.stp'

	s=size(sl)

	openw,1,f+'.txt',width=16*s(1)
	for i=0,s(2)-1 do printf,1,reform(sl(*,i))
	close,1
	
	slicewsxm,fstp,sl
end

end

pro lumi_exp_cut,t,a,extra=extra
;saves the cut along coordinate at position a (sign denotes if it is the 1st or 2nd one) would like to do it by angle in da fucha
;built for generating an stp or a gnuplot

if a ge 0 then sl=reform(t.map(a,*,*)) else sl=reform(t.map(*,abs(a),*))

if not(keyword_set(extra)) then extra=''

f=getval(t.par,'Experiment')
print,f
if f ne "" then f=f+"_cut_"+strtrim(string(round(a)),2)+'_'+extra else f=dialog_pickfile()

s=size(t.map)
openw,1,f+'.xnm'
	for i=0,s(3)-1 do printf,1,t.x(i)
close,1
openw,1,f+'.xev'
	for i=0,s(3)-1 do printf,1,1240./t.x(i)
close,1

s=size(sl)
openw,1,f+'.txt',width=16*s(1)
for i=0,s(2)-1 do printf,1,reform(sl(*,i))
close,1
	
f=f+'.stp'
slicewsxm,f,sl
print,f
print,"all written"
end

function lumi_restore,f
if not(keyword_set(f)) then f=dialog_pickfile()
fs=strmid(f,0,strlen(f)-4)
fhd=fs+'.xhd'
fdb=fs+'.xdb'
fpr=fs+'.xpr'
fcr=fs+'.xcr'
fnm=fs+'.xnm'
fev=fs+'.xev'
ffi=fs+'.xfi'

print,fhd
print,fdb

a=0
b=a
c=a
 openr,1,fhd
	readf,1,a,b,c
 close,1

print,a,b,c

map=dblarr(a,b,c)
curr=dblarr(a,b)
x=dblarr(c)
par=""

 openr,1,fdb
	readu,1,map
 close,1
 openr,1,fcr
	readu,1,curr
 close,1
 
 if file_test(ffi) then begin
	fits=dblarr(a,b,c)
	print,"Discovered fitted BKG, loading also.."
	openr,1,ffi
	readu,1,fits
	close,1
 end else fits=-1

 openr,1,fnm
	for i=0,c-1 do begin
		readf,1,xx
		x(i)=float(xx)
	end
 close,1
 openr,1,fpr
 line=""
 par=""
WHILE NOT EOF(1) DO BEGIN & $
  READF, 1, line & $
  par = [par, line] & $
ENDWHILE
close,1

 return,{map:map,x:x,curr:curr,nmap:-1,num:-1,par:par,fit:{fits:fits}}
end



pro lumi_store,t,ext=ext
f=getval(t.par,'Experiment')
if f eq "" then f=dialog_pickfile()
if keyword_set(ext) then f=f+'_'+ext
fhd=f+'.xhd'
fdb=f+'.xdb'
fpr=f+'.xpr'
fcr=f+'.xcr'
fnm=f+'.xnm'
fev=f+'.xev'
ffi=f+'.xfi'

print,fhd
print,fdb

s=size(t.map)

 openw,1,fhd
	printf,1,s(1),s(2),s(3)
 close,1

 openw,1,fdb
	writeu,1,double(t.map)
 close,1
 openw,1,fcr
	writeu,1,double(t.curr)
 close,1

if where(Tag_Names(t) EQ StrUpcase('fit')) ne -1 then begin
	sz=size(t.fit.fits)
	if sz(1) eq s(1) and sz(2) eq s(2) and sz(3) eq s(3) then begin
		print,"Fitted BKG also present, exporting"
		openw,1,ffi
	        writeu,1,double(t.fit.fits)
		close,1
	end
 end

 openw,1,fnm
	for i=0,s(3)-1 do printf,1,t.x(i)
 close,1
 openw,1,fev
	for i=0,s(3)-1 do printf,1,1240./t.x(i)
 close,1
 n=n_elements(t.par)
 openw,1,fpr
 for i=0,n-1 do printf,1,t.par(i)
 close,1
end






pro lumi_export,f,energy=energy,sum=sum
if not(keyword_set(f)) then f=dialog_pickfile(/must_exist,/multi)

sm=0
for k=0,n_elements(f)-1 do begin
	dt=lumi_load(f(k))

	if (keyword_set(sum)) then begin
		sm+=dt.i

	end
	if (keyword_set(energy)) then begin
		dt.x=1240./dt.x
		openw,1,f(k)+'.ei'
	end else openw,1,f(k)+'.xi'
	
	for i=0,n_elements(dt.x)-1 do printf,1,dt.x(i),dt.i(i)
	close,1
end


if keyword_set(sum) then begin
	if keyword_set(energy) then openw,1,sum+'.ei' else openw,1,sum+'.xi'

	for i=0,n_elements(sm)-1 do printf,1,dt.x(i),sm(i)

	close,1 
end


end


function lumi_stark,st1,st2,rng=rng
;cross-correlates two maps: st1, st2 (have to be fitered, bkg + drift corrected first and cropped)
;and returns the shift in eVs along with reliability (correlation coefficient)
;assumes the same ranges
;rng restricts the range (indices)

s=size(st1.map)
print,s
if keyword_set(rng) then begin
	a=rng(0)>0
	b=rng(1)<s(3)
end else begin
	a=0
	b=s(3)-1
end

print,a,b

starkmap=dblarr(s(1),s(2))
ccor=starkmap
for i=0,s(1)-1 do for j=0,s(2)-1 do begin
	cc=1.

	r=get_shift_1d(reform(st1.map(i,j,a:b)),reform(st2.map(i,j,a:b)),mx=cc)
	print,r
	starkmap(i,j)=r
	ccor(i,j)=cc
end

dv=double(getval(st1.par,'Bias:',/unit))-double(getval(st2.par,'Bias:',/unit))
;dv is difference in biases (obtained from the parameters)
return,{stmap:starkmap,dv:dv,ccor:ccor}
end
