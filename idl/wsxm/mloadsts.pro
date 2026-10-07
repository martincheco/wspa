function sts_copy,m
n=n_elements(m)
mc=ptrarr(n)
for i=0,n-1 do mc(i)=ptr_new(*m(i))
return,mc
end


function chan_rename,ch
nch=ch
n=n_elements(ch)
for i=0,n-1 do begin
ich=ch(i)
if strpos(ich,'Excitation') ne -1 then nch(i)='exc'
if strpos(ich,'Frequency') ne -1 then nch(i)='df'
if strpos(ich,'Current') ne -1 then nch(i)='I'
if strpos(ich,'Input 2') ne -1 then nch(i)='dIdV'
if strpos(ich,'Amplitude') ne -1 then nch(i)='amp'
end
return,nch
end


pro dump_sts_txt,m
;dumps data into files without header
for i=0,n_elements(m)-1 do begin
    mp=(*m(i))
    s=size(mp.data)
    openw,1,mp.p.f+'.txt',width=1024
    for j=0,s(2)-1 do begin
	printf,1,reform(mp.data(*,j))
    end
    close,1
end


end


pro dump_sts,m
n=n_elements(m)
;help,n
for i=0,n-1 do begin
    mp=(*m(i))
    nchans=chan_rename(mp.chans)
    x=reform(mp.data(0,*))
    xunit=mp.units(0)
    x=axred(x,xunit)
    nch=(n_elements(mp.chans)-1)/2
    for j=1,nch do begin
	y1=mp.data(j,*)
	y2=mp.data(j+nch,*)
	yunit1=mp.units(j)
	yunit2=mp.units(j+nch)
	y1=axred(y1,yunit1)
	y2=axred(y2,yunit2)
;	tvlct,r,g,b,/get
	fnm=mp.p.f+'.'+nchans(j)
	set_plot,'ps'
	Device,/color,filename=fnm+'.eps',xs=30,ys=12,/encapsulated
	plot,x,y1,xst=1,yst=1,yrange=[min([y1,y2]),max([y1,y2])],xtitle=mp.chans(0)+' ['+xunit+']',ytitle=mp.chans(j)+' ['+yunit1+']',psym=-1,color=0,background=255
	oplot,x,y2,color=128,psym=-1
	device,/close
	print,fnm
	spawn,'convert -bordercolor white  -border 0x0 "'+fnm+'.eps" "'+fnm+'.png"'
	spawn,'rm "'+fnm+'.eps" &'
    end
end
	set_plot,'X'

end

pro dump_sts_all,morig,xchan=xchan,ychan=ychan,xrng=xrng,xoff=xoff,zcorr=zcorr
n=n_elements(morig)
print,n
;takes first curve and determines channels
;then for each channel plots together all data
;x is the zero channel
;xrng - xrange by hand
;xoff - remove xoffset by the lowest value
;dat - save as dat files also (x vs. value)
;zcorr - correct the Z offset for curves that have the Z rel only, will operate on the first channel exclusively (Z rel)

m=sts_copy(morig) ;a copy

if keyword_set(zcorr) then $
    for i=0,n-1 do begin
	    mp=(*m(i))
	    (*m(i)).data(0,*)=mp.data(0,*)+mp.p.z
	    help,(*m(i)).p.z
    end

mp0=(*m(0))
yunit=mp0.units
nnch=n_elements(mp0.chans)
nch=(nnch-1)/2
ymin=dblarr(nnch)
ymax=ymin
print,yunit
;initialize mins and maxes and main unit

for j=0,nnch-1 do begin
    yu=yunit(j)
    mp0.data(j,*)=axred(mp0.data(j,*),yu)
    yunit(j)=yu
    ymin(j)=min(mp0.data(j,*))
    ymax(j)=max(mp0.data(j,*))
end
print,yunit

if not(keyword_set(xchan)) then xchan=0
if not(keyword_set(ychan)) then ychan=[1,2,5,6]

print,ymin,ymax

;determines global maxima and minima
for i=0,n-1 do begin
    mp=(*m(i))

    for j=0,nnch-1 do begin
	newdt=axred(mp.data(j,*),mp.units(j),funit=yunit(j))
	(*m(i)).data(j,*)=newdt
	ymin(j)=ymin(j)<min(newdt)
	ymax(j)=ymax(j)>max(newdt)
    end
end
print,ymin,ymax

nchans=chan_rename(mp0.chans)
mainx=([ymin(xchan),ymax(xchan)])
mainxmin=min(mainx)
if keyword_set(xoff) then mainx=mainx-min(mainx)
if keyword_set(xrng) then mainx=xrng


nychan=n_elements(ychan)

;plots all by channel
for k=0,nychan-1 do begin
    j=ychan(k)
    y=([ymin(j),ymax(j)])
    set_plot,'ps'
    fnm=mp0.p.f+'.'+nchans(j)
    Device,/color,filename=fnm+'.eps',xs=30,ys=12,/encapsulated
    plot,mainx,y,/nodata,xtitle=mp0.chans(xchan)+' ['+yunit(xchan)+']',ytitle=mp0.chans(j)+' ['+yunit(j)+']',xst=1,yst=1,color=0
    print,mainx
    for i=0,n-1 do begin
	mp=(*m(i))
	x=reform(mp.data(xchan,*))
	if keyword_set(xoff) then x=x-mainxmin
	xunit=mp.units(xchan)
	y1=mp.data(j,*)
	yunit1=mp.units(j)
	oplot,x,y1,psym=-1,color=250/n*(i+1)
    end
    device,/close
    spawn,'convert -bordercolor white  -border 0x0 "'+fnm+'.eps" "'+fnm+'.png"'
    spawn,'rm "'+fnm+'.eps" &'
end

set_plot,'X'

end


function mloadsts,f,dump=dump
;reads sts into a pointer structure
;currently supports only nanonis, can be extended
if not(keyword_set(f)) then f=dialog_pickfile(/must_exist,/multi)
n=n_elements(f)
parr=ptrarr(n)
help,n
for i=0,n-1 do parr(i)=ptr_new(loadnanonis_sts(f(i)))
if keyword_set(dump) then dump_sts_all,parr
return,parr
end
