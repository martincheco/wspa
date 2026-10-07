common interfaz,menuwidth,basicsize,s

function offleed,stack,xoff,yoff
;by setting values centers the pattern 
;img - the image with the spots (can be constructed e.g by variance_map)
;lstr - structure to be offset

nstack=stack
nstack=shift(stack,0,xoff,yoff)
return, nstack
end


function circ_mask,x,y,cx,cy,r,inv=inv
;creates circular mask
;x,y - size
;cx,cy - center of the circle

mask=bytarr(x,y)
for i=0,x-1 do for j=0,y-1 do if (double(i-cx)^2+double(j-cy)^2)/r^2 le 1. then mask(i,j)=1
if keyword_set(inv) then mask=1-mask
return,mask
end



function readspots,f,fdir,energy
;reads the previously saved spot trajectories, ignoring the header
;assuming first column of energies and the next ones as x0,y0,x1,y1,etc.
;note that zero coordinate is passed as zero coordinate

nfdir=""
if not(keyword_set(f)) then f=dialog_pickfile(/must_exist,path=fdir,get_path=nfdir,filter="*.spt")
;print,f
if file_test(f) ne 0 then tmp_spots=read_ascii(f,data_start=1,/verbose) else return, -1
help,tmp_spots,/struct
tmp_spots=tmp_spots.(0)

s=size(tmp_spots)

if s(1) ge 3 then begin
	n=n_elements(energy)
	nn=(s(1)-1)/2
	;print,n
	spot=intarr(99,n,2)
	
	    for j=0,s(2)-1 do begin
		;print,'energy: '+string(tmp_spots(0,j))
	        wf=abs(energy - tmp_spots(0,j))
    	        ;plot,wf
		w=where(wf eq min(wf))
		;print,w
		;print,'nearest: '+string(energy(w(0)))
		if w(0) ne -1 then $
		    for i=0,nn-1 do begin
			spot(i,w(0),0)=tmp_spots(1+i,j)
			spot(i,w(0),1)=tmp_spots(1+nn+i,j)
		    end
		
	    end
end

return,spot
end

function readleed,f,fdir
;simply reads a bunch of tiff files, returns a structure
;{energy,stack}
;energy is determined from the name s****_****.*eV.tiff
;equal to what is found between "_" and "eV"
nfdir=""
if not(keyword_set(f)) then f=dialog_pickfile(/multiple_files,path=fdir,get_path=nfdir,/must_exist,filter=["*.tif*","*.TIF*"])
n=n_elements(f)

f=f(sort(f))

if nfdir ne "" then fdir=nfdir

if f(0) eq "" then return,{energy:-1,stack:-1}
if file_test(f(0)) then img=read_tiff(f(0)) else return,{energy:-1,stack:-1}
s=size(img)

lstr={energy:fltarr(n),stack:intarr(n,s(1),s(2))}

i_msg,'Reading data..'

for i=0,n-1 do begin
if file_test(f(i)) then img=read_tiff(f(i))
lstr.stack(i,*,*)=img
fb=file_basename(f(i))
p1=strpos(fb,"eV")
p2=strpos(fb,"_")+1
;i_msg,fb
en=strmid(fb,p2,p1-p2)
;i_msg,en
lstr.energy(i)=double(en)
end

return,lstr
end

;**************image and stack filters************************

function reduce,stack,newsize
s=size(stack)
nstack=intarr(newsize,s(2),s(3))
for i=0,newsize-1 do nstack(i,*,*)=stack(s(1)*i/newsize,*,*)
return,nstack
end

function rscaleed,stack,energy,norm=norm,bkg=bkg,fast=fast
;rescales the stack of LEED images according to energy
;by simple downscaling by factor sqrt(Energy), 
;it is possible to renormalize
;the intensities or to remove background;
;but that is unreliable since it is determined by simple smoothing
;stack - image(energy)
;energy - vector of energies for the stack
;/norm - renormalizing switch
;/bkg - background switch

s=size(stack)
n=s(1)
dummy=intarr(s(2),s(3))
nstack=intarr(n,s(2),s(3))
mx=max(energy)
mn=min(energy)

for i=0,n-1 do begin
  fact=sqrt(double(energy(i))/mx)
  sx=round(s(2)*fact)
  sy=round(s(3)*fact)
  img=reform(stack(i,*,*))
  if keyword_set(bkg) then img=img-smooth(img,10)
  img=congrid(img,sx,sy)
  if keyword_set(norm) then img=round(double(img)/fact^2)
  dummy(s(2)/2-sx/2:s(2)/2-sx/2+sx-1,s(3)/2-sy/2:s(3)/2-sy/2+sy-1)=img
  nstack(i,*,*)=dummy
end

return, nstack
end

function mark_spots,stack_total,auto=auto

;stack_total - rescaled stack, flattened

s=size(reform(stack_total))
spot_size=3
cell_size=spot_size*12

xsteps=s(1)/cell_size/2
ysteps=s(2)/cell_size/2

coords=dblarr(xsteps*ysteps,2)

s=size(stack_total)
i=0

for x=0,xsteps-1 do $
  for y=0,ysteps-1 do $
  begin
  coords(i,*)=encirc(stack_total,2*cell_size,spot_size,2*x*cell_size+cell_size,2*y*cell_size+cell_size)
  i=i+1
  end


cx=coords(*,0)
cy=coords(*,1)

w=where(cx gt 0 and cy gt 0)

cx=cx(w)
cy=cy(w)

return,[[cx],[cy]]
end

function variance_map,im
;calculates variance map, good for finding the spots
s=size(im)
if s(1) gt 1 then begin
img=dblarr(s(2),s(3))
for i=0,s(2)-1 do for j=0,s(3)-1 do img(i,j)=variance(reform(im(*,i,j)),/double)
return,img
end else return,im
end

function dead_px,stack,maxvalue
;attempts to remove dead pixels from the raw stack
;rule is if the mean intensity reaches the maxvalue specified

s=size(stack)
img=double(total(stack,1))/s(1)
badpx_i=where(img gt maxvalue)
print,'here'
if badpx_i(0) ne -1 then begin
img=img*0+1
img(badpx_i)=0
nstack=stack
for i=0,s(1)-1 do $
begin
nstack(i,*,*)=nstack(i,*,*)*img
i_msg,"Processing slice no. "+strtrim(i,2),/noprint
end
return,nstack
end else return,stack
end


;***********IV routines**************************

function cut_out_stack,stack,coords,mask
;cuts out a subset of slices according to the coordinates given
;the sizes are controlled, are thrown out if the size exceeds!
;built for single coords

s_m=size(mask)
s=size(stack)

outp_stack=intarr(s(1),s_m(1),s_m(2))

rzx2=s_m(1)/2
rzx1=s_m(1)-rzx2-1
rzy2=s_m(2)/2
rzy1=s_m(2)-rzy2-1

x=reform(coords(*,0))
y=reform(coords(*,1))

for i=0,s(1)-1 do begin
xc=x(i)
yc=y(i)
if (xc ge rzx1) and (yc ge rzy1) and xc+rzx2 lt s(2) and (yc+rzy2) lt s(3) $
then outp_stack(i,*,*)=stack(i,xc-rzx1:xc+rzx2,yc-rzy1:yc+rzy2)*mask
end

return, outp_stack
end


function meanbkg_iv,coords,data_act,radius,region_size,simple=simple
;more clever method to obtain the curves, is merged with the simple one
areasize=double(region_size)
radius=double(radius)
help,areasize
help,radius
smask=circ_mask(areasize,areasize,areasize/2,areasize/2,radius)
bmask=circ_mask(areasize,areasize,areasize/2,areasize/2,areasize/2)

mask=bmask-smask
s=size(data_act)

peak=cut_out_stack(data_act,coords,smask)
bkg=cut_out_stack(data_act,coords,mask)

peakmean=dblarr(s(1))
bkgmean=peakmean

for i=0,s(1)-1 do begin
peakdummy=reform(peak(i,*,*))
w_i=where(peakdummy)
if w_i(0) ne -1 then peakmean(i)=mean(peakdummy(w_i))
bkgdummy=reform(bkg(i,*,*))
w_i=where(bkgdummy)
if w_i(0) ne -1 then bkgmean(i)=mean(bkgdummy(w_i))
end

if keyword_set(simple) then return,peakmean else return,peakmean-bkgmean
end


;***********other routines***********************

function shade_out,points,shadow
;sends all the points outside the defined region to zero
;points is a vector
spoints=points*0

x0=double(shadow(0))
y0=double(shadow(1))
x1=double(shadow(3))
y1=double(shadow(4))


rmax=double(shadow(2))^2
rmin=double(shadow(5))^2

dx0=double(points(*,0))-x0
dy0=double(points(*,1))-y0

dx1=double(points(*,0))-x1
dy1=double(points(*,1))-y1

r0=dx0^2+dy0^2
r1=dx1^2+dy1^2

w=where(r0 lt rmax and r1 gt rmin)

if w(0) ne -1 then spoints(w,*)=points(w,*)

return,spoints
end

;***********1D filters***********************
function fill_gaps,v,e,lsquad=lsquad,spline=spline
;for the zero elements of v(e) finds interpolation
;assumes a non-zero vector

w=where(v ne 0)

if w(0) ne -1 then begin
    if keyword_set(lsquad) then nv=INTERPOL(v(w), e(w), e,/quadratic) else $
    if keyword_set(spline) then nv=INTERPOL(v(w), e(w), e,/spline) else $
    nv=INTERPOL(v(w), e(w), e) 
end else nv=v
return,nv
end


;**********interface routines*******************

function spotmove,index,wh,dir
;unusable
dir=dir>(-1)
dir=dir<1
w=where(wh gt 0)
if w(0) ne -1 then begin
    position=where(w eq index)
    if position(0) ne -1 then $
	begin
	    npos=position(0)+dir
	    npos=npos<(n_elements(w)-1)>0
	    nindex=w(npos)
	end else nindex=index
    end else nindex=index

return,nindex
end

function rf_matrix,iv,energy,rf,filter,filterpar
;returns a square matrix with a chosen rfactors of IVs at energies defined by array energy
;ignores zero values
;uses filter to smooth the data first

if not(keyword_set(filterpar)) then filterpar=[10,20]
if not(keyword_set(filter)) then filter="none"

s=size(iv)
help,iv
pmatrix=dblarr(s(1),s(1))
for i=0,s(1)-1 do for j=0,s(1)-1 do $
    begin
	iv1=reform(iv(i,*))
	iv2=reform(iv(j,*))
	
	case filter of
	    "savgol":$
	    begin
		iv1=dezofilter(energy, iv1, width=filterpar(0), /savg)
		iv2=dezofilter(energy, iv2, width=filterpar(0), /savg)
	    end
	else:$
	    i_msg,"No filter",/noprint
	endcase
	
	w=where(iv1 gt 0 and iv2 gt 0)
    
	if w(0) gt -1 then $ ;throws away all that is =< 0
    	    begin
		iv1=iv1(w)
    		iv2=iv2(w)
		e=energy(w)
	    end
    
	case rf of $
	    "pendry": pmatrix(i,j)=pendry2(e,iv1>2,iv2>2)
	    ;"ja": pmatrix(i,j)=ja_rfactor(e,iv1>2,iv2>2)
	    ;"whatever": pmatrix(i,j)=whatever_rfactor(e,iv1>2,iv2>2)
	else: i_msg,"Unknown R-factor",/noprint
	endcase
        
    end
;i_msg,pmatrix,/noprint

return,pmatrix
end


function i_ask_coords,pos,nonstrict=nonstrict
;nonstrict keyword allows to return on click out of range specified by pos
;in that case, coordinates are returned, dirty, but works

x1=pos(0)
x2=pos(0)+pos(2)
y1=pos(1)
y2=pos(1)+pos(3)

if not(keyword_set(nonstrict)) then $
begin
    repeat begin
	cursor,x,y,/up,/device
    endrep until x le x2 and x ge x1 and y le y2 and y ge y1
end else $
begin
	cursor,x,y,/up,/device
end

return,[x,y]
end

pro i_menu_redraw,menu,menu2,pos
common interfaz;,menuwidth,basicsize
sz=basicsize
nm=n_elements(menu)
nm2=n_elements(menu2)
maxn=pos(3)/sz-1

if not(keyword_set(pos)) then pos=[0,0,100,1024]
tv,intarr(pos(2),pos(3)),pos(0),pos(1)
plots,[pos(0),pos(0)],[pos(1),pos(1)+pos(3)],/device
plots,[pos(0)+pos(2),pos(0)+pos(2)],[pos(1),pos(1)+pos(3)],/device
for i=0,nm-1 do begin
xyouts,pos(0),pos(1)+i*sz+sz/5,menu(i),charsize=sz/10,/device
plots,[pos(0),pos(0)+pos(2)],[pos(1)+i*sz,pos(1)+i*sz],/device
end

for i=0,nm2-1 do begin
xyouts,pos(0),pos(1)+(maxn-i)*sz+sz/5,menu2(i),charsize=sz/10,/device
plots,[pos(0),pos(0)+pos(2)],[pos(1)+(maxn-i)*sz,pos(1)+(maxn-i)*sz],/device
end

;plots,[pos(0),pos(0)+pos(2)],[pos(1)+nm*sz,pos(1)+nm*sz],/device


end

function i_menu_select,menu,menu2,pos

common interfaz;,menuwidth,basicsize

sz=basicsize
nm=n_elements(menu)
nm2=n_elements(menu2)
nmax=pos(3)/sz-1
i_menu_redraw,menu,menu2,pos

repeat begin
coords=i_ask_coords(pos,/nonstrict)
id=fix((coords(1)-pos(1))/sz)

if coords(0) lt pos(0) then action="COORDS:"+STRING(coords(0))+","+STRING(coords(1)) $
    else if (id ge 0 and id le nm-1) then action=menu(id) $
	else if (id lt nmax and id ge nmax-nm2+1) then action=menu2(nmax-id) $
	    else action=""

endrep until action ne "" and (strpos(action,">") eq -1)


if coords(0) ge pos(0) then begin
    tv,intarr(pos(2),sz)+255,pos(0),pos(1)+id*sz
    xyouts,pos(0),pos(1)+id*sz+sz/5,action,charsize=sz/10,/device,color=0
end

return,action
end

pro i_msg,msg,noprint=noprint
common interfaz;,menuwidth,basicsize
sz=basicsize
if not(keyword_set(noprint)) then print,msg
tv,intarr(640,basicsize)
xyouts,0,sz/5,msg,charsize=sz/10,/device
end

function i_input,query,pos
common interfaz
sz=float(basicsize)
st=""
k=query
apos=0
tv,intarr(pos(2),sz)+255,pos(0),pos(1),/device
xyouts,pos(0)+apos,sz/5+pos(1),k,/device,color=0,width=w
k=""
apos=apos+xn2d(w)
xyouts,pos(0)+apos,sz/5+pos(1),"_",/device,color=0,width=w

repeat $
    begin
	if apos le pos(2)-2*xn2d(w) then begin
	xyouts,pos(0)+apos,sz/5+pos(1),"_",/device,color=255
	xyouts,pos(0)+apos,sz/5+pos(1),k,/device,color=0,width=w
	st=st+k
	apos=apos+xn2d(w)
	xyouts,pos(0)+apos,sz/5+pos(1),"_",/device,color=0,width=w
	end
	
	;if k eq 27 then begin
;	
	;s=strmid(s,0,-1)
	;apos=apos+xn2d(w)
	;end
	k=get_kbrd(/key_name)
    endrep $ 
until byte(k) eq 10 
tv,intarr(pos(2),sz),pos(0),pos(1),/device
return,st
end

function xn2d,x ; returns x converted from normal to device coords
return, x*!D.X_VSIZE
end

function generate_img,data_act,e,ei,disptype,filter,thr
;takes care about applying filters
help,thr
s=size(data_act)


case disptype of

"energy": $
    begin
	img=reform(data_act(ei,*,*))
	i_t=where(img ge thr)
	if i_t(0) ne -1 then img(i_t)=0 ;saturation
    end

"variance": $
    begin
	data_temp=data_act(indgen(10)*s(1)/10,*,*)
	varmap=variance_map(data_temp)
	img=varmap
    end

"scaledvariance": $
    begin
	frscl=rscaleed(data_act(indgen(10)*s(1)/10,*,*),e(indgen(10)*s(1)/10))
	varmapscl=variance_map(frscl)
	img=varmapscl
    end

"scaledflat":$
    begin
	frscl=rscaleed(data_act(indgen(10)*s(1)/10,*,*),e(indgen(10)*s(1)/10))
	img=total(frscl,1)
    end

"flat":$
    begin
	forig=total(data_act,1)
	img=forig
    end


else: $ 
    begin
	i_msg,"i_display: No recognized disptype, using energy: "+disptype
	;img=intarr(s(2),s(3))
	img=reform(data_act(ei,*,*))
	i_t=where(img ge thr)
	if i_t(0) ne -1 then img(i_t)=0 ;saturation
    end
endcase

case filter of
"log": img=alog(img+1)
"heq": img=hist_equal(img)
"boo": img=alog((smooth(img,4)-(smooth(img,20))>0+1))
else:
endcase

return,img
end


pro i_display,img ; the only procedure that displays the image
tvscl,img
end

pro i_display_spots,spot,spot_i,ei
s=size(spot)

wspot=where(spot)
;wpath=where(path)

if wspot(0) gt -1 then $
    begin
	wspoti=array_indices([s(1),s(2),s(3)],wspot,/dimensions)
	plots,spot(wspoti(0,*),wspoti(1,*),0),spot(wspoti(0,*),wspoti(1,*),1),psym=1,/device,color=200
	plots,spot(spot_i,*,0),spot(spot_i,*,1),psym=1,/device
	plots,spot(spot_i,ei,0),spot(spot_i,ei,1),psym=6,/device,color=200
    end

;if wpath(0) gt -1 then $
;    begin
;	wpathi=array_indices([s(1),s(2),s(3)],wpath,/dimensions)
;	plots,path(wpathi(0,*),wpathi(1,*),0),path(wpathi(0,*),wpathi(1,*),1),psym=3,/device,color=200
;	plots,path(wpathi(0,*),ei,0),path(wpathi(0,*),ei,1),psym=2,/device,color=200
;	plots,path(spot_i,wpathi(1,*),0),path(spot_i,wpathi(1,*),1),psym=1,/device,color=200

;	plots,reform(path(*,*,0)),reform(path(*,*,1)),psym=3,/device,color=200
;	plots,path(*,ei,0),path(*,ei,1),psym=3,/device,color=200
;	plots,path(spot_i,*,0),path(spot_i,*,1),psym=3,/device,color=200
;	plots,path(spot_i,ei,0),path(spot_i,ei,1),psym=4,/device
;    end

end


function i_display_paths,img,path,spot_i,ei,spotsize,areasize
s=size(spot)
;help,img
;print,min(img),max(img)

col1=max(img)*0.7
col2=max(img)

nimg=img
wpath=where(path)

if wpath(0) gt -1 then $
    begin
;	wpathi=array_indices([s(1),s(2),s(3)],wpath,/dimensions)
;	plots,path(wpathi(0,*),wpathi(1,*),0),path(wpathi(0,*),wpathi(1,*),1),psym=3,/device,color=200
;	plots,path(wpathi(0,*),ei,0),path(wpathi(0,*),ei,1),psym=2,/device,color=200
;	plots,path(spot_i,wpathi(1,*),0),path(spot_i,wpathi(1,*),1),psym=1,/device,color=200

	nimg(reform(path(*,*,0)),reform(path(*,*,1)))=col2
;	plots,path(*,ei,0),path(*,ei,1),psym=3,/device,color=200
	nimg(path(spot_i,*,0),path(spot_i,*,1))=col2
	divs=2*spotsize
	df=2*!PI/divs
	xr=round(spotsize*cos(findgen(divs)*df)+path(spot_i,ei,0))
	yr=round(spotsize*sin(findgen(divs)*df)+path(spot_i,ei,1))
	nimg(xr,yr)=col2
	divs=4*areasize/2
	df=2*!PI/divs
	xr=round(areasize/2*cos(findgen(divs)*df)+path(spot_i,ei,0))
	yr=round(areasize/2*sin(findgen(divs)*df)+path(spot_i,ei,1))
	nimg(xr,yr)=col2
    end 
return,nimg
end


pro i_display_mask,mask
	wset,1
	i_display,mask
	wset,0
end

pro i_display_iv,iv,energy
if iv(0) ne -1 then $
		    begin
			s_iv=size(iv)
			window,1,xsize=640,ysize=200,title="LEED IV's"
			wset,1
			w=where(iv(*,*)) ;here corrected
			if w(0) ne -1 then $
			    begin
				plot,energy,intarr(n_elements(energy)),yrange=[0,max(iv)],xstyle=1,ystyle=1,background=255,xtitle="Energy [eV]",ytitle="Intensity",color=0
				for i=0,s_iv(1)-1 do $
				begin
				w=where(iv(i,*))
				if w(0) ne -1 then oplot,reform(energy(w)),reform(iv(i,w)),color=i*(256/s_iv(1))
				end
			    end
			wset,0
		    end
end

pro i_display_rfactor,rfactor,wsp,offs

if wsp(0) ne -1 and rfactor(0) ne -1 then if n_elements(wsp) gt 1 then $
		    begin
			if not(keyword_set(offs)) then offs=[0,0]
			window,2,xsize=250,ysize=180,title="R-factors"
			wset,2
			rfsz=size(rfactor)
			;print,rfsz
				xyouts,0+offs(0),0+offs(1),(string(float(rfactor(0,0)),format='(1F4.2)')),/data,width=rfwdth,align=0.0
				erase
				rfwdth=xn2d(rfwdth)
				    for i=0,rfsz(1)-1 do $
					for j=0,rfsz(2)-1 do begin
					    ;print,(string(float(rfactor(i,j)),format='(1F4.2)'))
					    xyouts,(1+i)*rfwdth*1.2+offs(0),(1+j)*20+offs(1),(string(float(rfactor(i,j)),format='(1F4.2)')),/device,align=0.0
					end
			for i=0,rfsz(1)-1 do xyouts,(1+i)*rfwdth*1.2+offs(0),(1+rfsz(2))*20+offs(1),(string(wsp(i),format='(1I4)')),/device,align=0.5
			for i=0,rfsz(1)-1 do xyouts,(1+i)*rfwdth*1.2+offs(0),0+offs(1),(string(wsp(i),format='(1I4)')),/device,align=0.5
			for j=0,rfsz(2)-1 do xyouts,(1+rfsz(1))*rfwdth*1.2+offs(0),(1+j)*20+offs(1),(string(wsp(j),format='(1I4)')),/device,align=0.5
			for j=0,rfsz(2)-1 do xyouts,0+offs(0),(1+j)*20+offs(1),(string(wsp(j),format='(1I4)')),/device,align=0.5
		    end
wset,0
end


pro i_display_shadow,shadow
if shadow(0) gt -1 then $
    begin
	r=shadow(2)
	divs=r>5
	df=2*!PI/divs
	xr=round(r*cos(findgen(divs)*df)+shadow(0))
	yr=round(r*sin(findgen(divs)*df)+shadow(1))
	plots,xr,yr,/device,linestyle=2
	r=shadow(5)
	divs=r>5
	df=2*!PI/divs
	xr=round(r*cos(findgen(divs)*df)+shadow(3))
	yr=round(r*sin(findgen(divs)*df)+shadow(4))
	plots,xr,yr,/device,linestyle=2
    end

end

function i_energyslider,data_act,filter,energy,thr
common interfaz

repeat begin
cursor,x,y,/change,/device
;print,!mouse.button
ei=s(1)*y/s(3)
img=generate_img(data_act,energy,ei,"energy",filter,thr)
i_display,img
i_msg,"Energy: "+strtrim(energy(ei),2)+" eV",/noprint
endrep until !mouse.button eq 1
msg="Energy set to: "+strtrim(energy(ei),2)+" eV"

cursor,x,y,/nowait ; hack to fool idl to read the mouse status
if !mouse.button ne 0 then cursor,x,y,/up ; if the button is not released yet, wait for the release, otherwise continue

return,ei
end


;***************obsoleted routines***********************
function centroid, im
;gives a center of mass of the specified 2D array, unusable
s = Size(im)
totalMass = Total(im)
xcm = Total(Total(im, 2) * Indgen(s(1)) ) / totalMass
ycm = Total(Total(im, 1) * Indgen(s(2)) ) / totalMass                                                                        
return, [xcm, ycm]
end

function calculate_path,x,y,xcenter,ycenter,energy,energies
;unusable
;calculates a path from coordinates x,y at energy
;energies - a vector of all energies
;returns coordinates
;assumes the ideal case when the image is centered
fact=sqrt(double(energies)/energy)
xc=round((x-xcenter)/fact+xcenter)
yc=round((y-ycenter)/fact+ycenter)

return,[[xc],[yc]]
end

function calc_path_stack,spots,data_act,energy
;unusable
n_spots=n_elements(spots(*,0))
s=size(data_act)
n_energy=n_elements(energy)
path_coords=intarr(n_spots,s(1),2)
for i=0,n_spots-1 do $
path_coords(i,*,*)=$
calculate_path(spots(i,0),spots(i,1),s(2)/2.,s(3)/2.,max(energy),energy)
return,path_coords
end

function autofocus_spot,spot_part,data_act,rlim,rstart
;under reconstruction
spot_part=reform(spot_part)
nwspot_part=spot_part
s=size(spot_part)

	for j=0,s(1)-1 do if spot_part(j,0) ne 0 then $ ; for each index that contains a spot
	    begin
		;print,j
		im=reform(data_act(j,*,*))
		xst=spot_part(j,0)
		yst=spot_part(j,1)
		nwspot_part(j,*)=encirc(im,rstart,rlim,xst,yst,/show)  ;for each pair of path coordinates
	    end

return,nwspot_part
end

function refine_path,spot_paths,energy,filtersize
;smooths the path
;assumes a set of spots and energies, ignores gaps and spacing

s=size(spot_paths)
nspot_paths=spot_paths

for i=0,s(1)-1 do begin

spot_path=reform(spot_paths(i,*,*))
x=spot_path(*,0)
y=spot_path(*,1)

;xef=fill_gaps(x*e^0.5,e)
;yef=fill_gaps(y*e^0.5,e)

w=where(x gt 0 and y gt 0)
x=x(w)
y=y(w)
e=energy(w)


xefs=smooth(x*e^0.5,filtersize,/edge_wrap)/e^0.5
yefs=smooth(y*e^0.5,filtersize,/edge_wrap)/e^0.5

nspot_paths(i,w,0)=xefs
nspot_paths(i,w,1)=yefs
end

return,nspot_paths
end



pro leed,data,output

;common options, spotsize, areasize

common interfaz,menuwidth,basicsize,s

menuwidth=110
basicsize=15

cd,current=origdir ; get the original dir
;print,origdir

spotsize=8 ;radius(!) of the peak
areasize=30 ;diameter of the area

device,retain=2
device,decomposed=0

colortbl=0

;cmds=strarr(999)
counter=0
f=""
fdir=origdir
if not(keyword_set(data)) then data=readleed(f,fdir)
s=size(data.stack)
offset=[0,0] ;offset coordinates
frscl=-1
wsp=-1
rfactor=-1
iv=-1
shadow=-1
data_act=data.stack ;actual data
spot_i=0
thr=250
disptype="energy"
disptyped=""
filter="none"
filterd=""
		x0=0
		x1=0
		y0=0
		y1=0
		r1=0
		r0=0


    begin
	;help,origdir
	param=loadparam(origdir+'/leed.ini')
	;print,origdir+'/leed.ini'
	if n_elements(param) gt 1 then $
	    begin
		
		tmp_spotsize=getval(param,'spot radius','float')
		if string(tmp_spotsize) ne "" then spotsize=tmp_spotsize
		
		tmp_areasize=getval(param,'area diameter','float')
		if tmp_areasize ne "" then areasize=tmp_areasize
		
		tmp_colortbl=getval(param,'color table','int')
		if tmp_colortbl ne "" then colortbl=tmp_colortbl

		tmp_filter=getval(param,'filter','string')
		if tmp_filter ne "" then filter=tmp_filter
		
		tmp_disptype=getval(param,'display type','string')
		if tmp_disptype ne "" then disptype=tmp_disptype

		tmp_thr=getval(param,'threshold','int')
		if tmp_thr ne "" then thr=tmp_thr

		tmp_r0=getval(param,'r0','int')
		if tmp_r0 ne "" then r0=tmp_r0
		
		tmp_x0=getval(param,'x0','int')
		if tmp_x0 ne "" then x0=tmp_x0
		
		tmp_y0=getval(param,'y0','int')
		if tmp_y0 ne "" then y0=tmp_y0
		
		tmp_r1=getval(param,'r1','int')
		if tmp_r1 ne "" then r1=tmp_r1
		
		tmp_x1=getval(param,'x1','int')
		if tmp_x1 ne "" then x1=tmp_x1
		
		tmp_y1=getval(param,'y1','int')
		if tmp_y1 ne "" then y1=tmp_y1
		
		shadow=[x0,y0,r0,x1,y1,r1]

help,thr

	    end
	loadct,colortbl
    end



imgchanged=1

spot=intarr(99,s(1),2) ;array for coordinates of spots, max no. is 99
path=intarr(99,s(1),2) ;array for coordinates of paths, max no. is 99
help,spot
ei=s(1)/2 ; index of actual energy
img=(data_act(ei,*,*)) ;actual image

;window,1,xsize=640,ysize=200,title="LEED IV's"
;window,2,xsize=250,ysize=180,title="R-factors"

window,0,xsize=s(2)>640+menuwidth,ysize=s(3)>480,title="LEED processing"

msg="Welcome to LEED processing software! (last update 03/02/2013)"

mainmenu=["<Main>"," File"," Display"," Paths"," IVs"," R-factors"," Operations"," Parameters",""," Exit"]
mainmenu=reverse(mainmenu)

menu_ener=reverse([" SLIDER"," MANUAL"," TEN DOWN"," DOWN"," "+strtrim(data.energy(ei),2)+" eV"," UP"," TEN UP","<Energy>"])
menu_file=[""," Export R-factors"," Save ini"," Export image"," Export spots"," Export IVs","<Export>",""," Load ini"," Read spots"," Open new set","<File>"]
menu_path=[""," Reset leading spots"," Reset path"," Apply deadzone"," Autofocus spots"," Autofocus path"," Fill paths (spl)"," Fill paths (quad)"," Fill paths (lin)"," Remove spot"," Add spot"," Next path"," Path: "+strtrim(spot_i,2)," Previous path","<Paths>"]
menu_iv=[""," Without background"," Mean background","<IV curves>"]
menu_disp=[""," None"," Boost mask"," Histogram equalize"," Logarithmic","<Filter>",""," Scaled var."," Flat scaled"," Orig. var."," Flat orig."," Color table","<Display>"]
menu_oper=[""," Cut out dead zones"," Define dead zones"," Reset data"," Remove dead pixels"," Offset","<Operations>"]
menu_exit=[""," Exit"," Exit&pass variables","<Exit>"]
menu_para=[""," Peak radius"," Background size","<Parameters>"]
menu_r=[""," J.-A."," Pendry (filter 5)"," Pendry","<R-factors>"]



repeat begin

if imgchanged or disptype ne disptyped or filter ne filterd or disptype eq "energy" then begin
imgchanged=0
img=generate_img(data_act,data.energy,ei,disptype,filter,thr)
filterd=filter
disptyped=disptype
i_display,i_display_paths(img,path,spot_i,ei,spotsize,areasize)
i_display_spots,spot,spot_i,ei
i_display_shadow,shadow
end

if msg ne "" then $
    begin 
	i_msg,msg
	msg=""
    end

menu_act=strtrim(i_menu_select(mainmenu,menu_ener,[s(2),0,menuwidth,s(3)]),2)
;print,"Debug: menu_act = ",menu_act

case menu_act of

"File": menu_sub=menu_file

"Display": menu_sub=menu_disp

"Operations": menu_sub=menu_oper

"Paths": menu_sub=menu_path

"IVs": menu_sub=menu_iv

"Exit": menu_sub=menu_exit

"R-factors": menu_sub=menu_r

"Parameters": menu_sub=menu_para

else:menu_sub=">"

endcase

msg=""

repeat begin

if imgchanged or disptype ne disptyped or filter ne filterd or disptype eq "energy" then begin
imgchanged=0
img=generate_img(data_act,data.energy,ei,disptype,filter,thr)
filterd=filter
disptyped=disptype
i_display,i_display_paths(img,path,spot_i,ei,spotsize,areasize)
i_display_spots,spot,spot_i,ei
help,shadow
print,shadow
i_display_shadow,shadow
;wsp=where(total(total(path(*,*,*),2),2))
;if wsp(0) eq -1 then rfactor=-1
;i_display_rfactor,rfactor,wsp
end

if msg ne "" then $
    begin 
	i_msg,msg
	msg=""
    end

if (menu_sub(0) ne ">") then $
begin
    action=i_menu_select([" Back",menu_sub],menu_ener,[s(2),0,menuwidth,s(3)])
    action=strtrim(action,2) 
end $
else action=menu_act

;print,"Debug: action = ",action

;cmds(counter)=action ; log the command
counter=counter+1


if strpos(action," eV") gt -1 then action="Redraw" 

if strpos(action,"COORDS:") gt -1 then begin ;in case of click into the display area
p1=strpos(action,":")+1
p2=strpos(action,",")+1
xclick=double(strmid(action,p1,p2-p1-1))
yclick=double(strmid(action,p2))
action="screenclick" 
end


case action of

"Without background":$
    begin
    wsp=where(total(total(path(*,*,*),2),2))
    nsp=n_elements(wsp) ; no. of nonzero paths
    iv=dblarr(nsp,s(1))
	for i=0,nsp-1 do $
	    begin
	    	if wsp(i) gt -1 then iv(i,*)=meanbkg_iv(reform(path(wsp(i),*,*)),data_act,spotsize,areasize,/simple)>0
	    end
    i_display_iv,iv,data.energy
    smask=circ_mask(areasize,areasize,areasize/2,areasize/2,spotsize)
    bmask=circ_mask(areasize,areasize,areasize/2,areasize/2,areasize/2)
    i_display_mask,bmask-smask
    end

"Mean background":$

    begin
    wsp=where(total(total(path(*,*,*),2),2))
    nsp=n_elements(wsp) ; no. of nonzero paths
    iv=dblarr(nsp,s(1))
	for i=0,nsp-1 do $
	    begin
	    	if wsp(i) gt -1 then iv(i,*)=meanbkg_iv(reform(path(wsp(i),*,*)),data_act,spotsize,areasize)>0
	    end
    i_display_iv,iv,data.energy
    smask=circ_mask(areasize,areasize,areasize/2,areasize/2,spotsize)
    bmask=circ_mask(areasize,areasize,areasize/2,areasize/2,areasize/2)
    i_display_mask,bmask-smask
    end

;"Offset":$
;    begin
;	i_msg,"Mark the center"
;	offset=-(i_ask_coords([0,0,s(2),s(3)])-[s(2)/2,s(3)/2])
;	i_msg,"Modifying data"
;	data_act=offleed(data_act,offset(0), offset(1))
;    end

"Export image":$
    begin
        imgtow=tvrd(0,true=1)
	fimg=""
	imgtow=imgtow(*,0:s(2)-1,0:s(3)-1)
	nfdir=""
	fimg=dialog_pickfile(filter="*.png",path=fdir,get_path=nfdir)
	if nfdir ne "" then fdir=nfdir 
	if fimg(0) ne "" then $
	    begin
		write_png,fimg,imgtow
		msg="Image exported to: "+fimg
	    end else msg="No filename to write."
    end

"Redraw": disptype="energy"

"UP": $
    begin
	ei=ei+1<(s(1)-1)
	disptype="energy"
	menu_ener(3)=" "+strtrim(data.energy(ei),2)+" eV"
    end

"DOWN": $
    begin
	ei=ei-1>0
	disptype="energy"
	menu_ener(3)=" "+strtrim(data.energy(ei),2)+" eV"
    end
    
"TEN DOWN": $
    begin
	ei=ei-10>0
	disptype="energy"
	menu_ener(3)=" "+strtrim(data.energy(ei),2)+" eV"
    end

"TEN UP": $
    begin
	ei=ei+10<(s(1)-1)
	disptype="energy"
	menu_ener(3)=" "+strtrim(data.energy(ei),2)+" eV"
    end

;"MANUAL": $
;    begin
;        inp=fix(i_input("Enter energy ("+strtrim(min(data.energy),2)+" - "+strtrim(max(data.energy),2)+" [eV]): ",[0,0,270]))
;	if inp ge min(data.energy) and inp le max(data.energy) then $
;	    begin
;		edist=abs(data.energy-inp)
;		pei=where(edist eq min(edist))
;		if ei(0) ne -1 then ei=pei(0)
;	    end
;	disptype="energy"
;	menu_ener(3)=" "+strtrim(data.energy(ei),2)+" eV"
;    end

"SLIDER": $
    begin
	pei=i_energyslider(data_act,filter,data.energy,thr)
	if ei ge 0 and ei lt s(1) then ei=pei
	disptype="energy"
	menu_ener(3)=" "+strtrim(data.energy(ei),2)+" eV"
    	msg="Energy set to: "+strtrim(data.energy(ei),2)+" eV"
    end

"Color table": xloadct,/block,/modal
"Orig. var.": disptype="variance"
"Scaled var.": disptype="scaledvariance"
"Flat scaled": disptype="scaledflat"
"Flat orig.": disptype="flat"

"Reset data": $
    begin
	path_coords=-1
	offset=[0,0]
	data_act=data.stack
	imgchanged=1
    end

"Reset leading spots": $
    begin
	spot(spot_i,*,*)=0
	path(spot_i,*,*)=0
    end

"Reset path": $
    begin
	path(spot_i,*,*)=0
    end

"Logarithmic": filter="log"
"Histogram equalize": filter="heq"
"Boost mask": filter="boo"
"None": filter="none"

"Remove dead pixels": $
    begin
	data_act=dead_px(data_act,50)
	imgchanged=1
    end


"Define dead zones": $
    begin
	p=intarr(3,2)
	for spi=0,2 do $
	    begin
		i_msg,"Mark point no."+strtrim(spi+1,2)+" of 3 of the outer limit: "
		p(spi,*)=i_ask_coords([0,0,s(2)+menuwidth,s(3)])
	    end
	
	cir_3pnt,p(*,0),p(*,1),r0,x0,y0


	for spi=0,2 do $
	    begin
		i_msg,"Mark point no."+strtrim(spi+1,2)+" of 3 of the inner limit: "
		p(spi,*)=i_ask_coords([0,0,s(2)+menuwidth,s(3)])
	    end

	cir_3pnt,p(*,0),p(*,1),r1,x1,y1
	shadow=[x0,y0,r0,x1,y1,r1]
	msg="Outer X, Y, R: "+string(x0)+string(y0)+string(r0)+" Inner X, Y, R: "+string(x1)+string(y1)+string(r1)
	imgchanged=1
    end

"Cut out dead zones": if shadow(0) gt -1 then $
    begin
	i_msg,"Modyfying the data"
	deadmask=circ_mask(s(2),s(3),shadow(0),shadow(1),shadow(2))
	deadmask=deadmask*circ_mask(s(2),s(3),shadow(3),shadow(4),shadow(5),/inv)

	for i=0,s(1)-1 do $
	    begin
	        i_msg,"Slice number: "+string(i),/noprint
		data_act(i,*,*)=data_act(i,*,*)*deadmask
		imgchanged=1
	    end
    end

"Previous path": $
    begin
	spot_i=(spot_i-1)>0
	str=" Path: " + strtrim(spot_i,2)
	menu_path(12)=str
	menu_sub=menu_path
    end


"Next path": $
    begin
	spot_i=(spot_i+1)<98
	str=" Path: " + strtrim(spot_i,2)
	menu_path(12)=str
	menu_sub=menu_path
    end

"Add spot": $
    begin
	i_menu_redraw,["","<for this energy>","<Mark spot>"],"",[s(2),0,menuwidth,s(3)]
	spot(spot_i,ei,*)=i_ask_coords([0,0,s(2),s(3)]);s(2)+menuwidth,s(3)])
    end

"screenclick": $
    begin
	if menu_act eq "Paths" then spot(spot_i,ei,*)=[xclick,yclick]
    end

"Remove spot": $
    begin
	spot(spot_i,ei,*)=0
    end

"Fill paths (lin)": $
begin
wspw=where(total(total(spot(*,*,*),2),2))
nsp=n_elements(wspw) ; no. of nonzero paths
for isp=0,nsp-1 do if wspw(isp) ne -1 and n_elements(where(spot(wspw(isp),*,0))) ge 2 then $
    begin
	spoti=wspw(isp)
	x=spot(spoti,*,0)
	y=spot(spoti,*,1)
	e=data.energy
	xf=fill_gaps(x*e^0.5,e^0.5)/e^0.5
	yf=fill_gaps(y*e^0.5,e^0.5)/e^0.5
	path(spoti,*,0)=xf
	path(spoti,*,1)=yf
    end
end


"Fill paths (quad)": $
begin
wspw=where(total(total(spot(*,*,*),2),2))
nsp=n_elements(wspw) ; no. of nonzero paths
for isp=0,nsp-1 do if wspw(isp) ne -1 and n_elements(where(spot(wspw(isp),*,0))) ge 2 then $
    begin
	spoti=wspw(isp)
	x=spot(spoti,*,0)
	y=spot(spoti,*,1)
	e=data.energy
	xf=fill_gaps(x*e^0.5,e^0.5,/lsquad)/e^0.5
	yf=fill_gaps(y*e^0.5,e^0.5,/lsquad)/e^0.5
	path(spoti,*,0)=xf
	path(spoti,*,1)=yf
    end
end

"Fill paths (spl)": $
begin
wspw=where(total(total(spot(*,*,*),2),2))
nsp=n_elements(wspw) ; no. of nonzero paths
for isp=0,nsp-1 do if wspw(isp) ne -1 and n_elements(where(spot(wspw(isp),*,0))) ge 4 then $
    begin
	spoti=wspw(isp)
	x=spot(spoti,*,0)
	y=spot(spoti,*,1)
	e=data.energy
	xf=fill_gaps(x*e^0.5,e^0.5,/spline)/e^0.5
	yf=fill_gaps(y*e^0.5,e^0.5,/spline)/e^0.5
	path(spoti,*,0)=xf
	path(spoti,*,1)=yf
    end
end

"Autofocus spots": if n_elements(where(spot(spot_i,*,0))) ge 1 then $
    begin
    	spot(spot_i,*,*)=autofocus_spot(reform(spot(spot_i,*,*)),data_act,spotsize/2,areasize/2)
	msg="Autofocused"
	imgchanged=1
    end

"Autofocus path": if n_elements(where(path(spot_i,*,0))) ge 1 then $
    begin
    	path(spot_i,*,*)=autofocus_spot(reform(path(spot_i,*,*)),data_act,spotsize/2,areasize/2)
	msg="Autofocused"
	imgchanged=1
    end


"Apply deadzone": $
begin
    wsp=where(total(total(path(*,*,*),2),2))
    nsp=n_elements(wsp) ; no. of nonzero paths
     if shadow(0) gt -1 then $
        for i=0,nsp-1 do $
    	    if wsp(i) gt -1 then path(wsp(i),*,*)=shade_out(reform(path(wsp(i),*,*)),shadow)

end

"Pendry": $
    if iv(0) ne -1 then begin
	rfactor=rf_matrix(iv,data.energy,"pendry") 
	i_display_rfactor,rfactor,wsp
    end else msg="Generate IV's first!"

"Pendry (filter 5)": $
    if iv(0) ne -1 then begin
	rfactor=rf_matrix(iv,data.energy,"pendry","savgol",[5,0])
	i_display_rfactor,rfactor,wsp
    end else msg="Generate IV's first!"

"J.-A.": $
    if iv(0) ne -1 then begin
	rfactor=rf_matrix(iv,data.energy,"ja")
	i_display_rfactor,rfactor,wsp
    end else msg="Generate IV's first!"



"Export IVs": $
    begin
        i_msg,"Select a file to write the ivs"
	nfdir=""
	fiv=dialog_pickfile(path=fdir,get_path=nfdir,filter="*.ivs")
	if nfdir ne "" then fdir=nfdir 
	
	if fiv ne "" and wsp(0) ne -1 then $
	    begin
		openw,lun,fiv,/get_lun,width=16*(n_elements(wsp)+1)
		printf,lun,["Energy [eV]", string(wsp)]
		for i=0,s(1)-1 do printf,lun,[data.energy(i),iv(*,i)]
		close,lun
		msg="IVs succesfully written."
	    end else msg="No data to write, aborting."			
    end

"Export spots": $
    begin
        i_msg,"Select a file to write the spots"
	nfdir=""
	fsp=dialog_pickfile(path=fdir,get_path=nfdir,filter="*.spt")
	if nfdir ne "" then fdir=nfdir 
	i_msg,fsp
	ssp=where(total(total(spot(*,*,*),2),2))
	
	if fsp ne "" and ssp(0) ne -1 then $
		
	    begin
		openw,lun,fsp,/get_lun,width=16*(2*n_elements(ssp))+1
		printf,lun,["Energy [eV] ","X: "+strtrim(string(ssp),2),"Y: "+strtrim(string(ssp),2)]
		    for i=0,s(1)-1 do if total(spot(ssp,i,0)) gt 0 then printf,lun,[data.energy(i),spot(ssp,i,0),spot(ssp,i,1)]
	    	close,lun
		msg="Spots succesfully written."
	    end else msg="No data to write, aborting."			
    end


"Export R-factors": $
    begin
        i_msg,"Select a file to write the R-factors"
	
	nfdir=""
	fr=dialog_pickfile(path=fdir,get_path=nfdir)
	if nfdir ne "" then fdir=nfdir 
	
	if fr ne "" and rfactor(0) ne -1 then $
	    begin
		openw,lun,fr,/get_lun,width=16*(n_elements(wsp)+1)
		printf,lun,string(wsp)
		printf,lun,rfactor
		close,lun
		msg="R-factors succesfully written."
	    end else msg="No data to write, aborting."			
    end

"Load ini":$

    begin
        i_msg,"Select a file to load the .ini file"
	
	nfdir=""
	fr=dialog_pickfile(path=fdir,get_path=nfdir,/must_exist,filter="*.ini")
	if nfdir ne "" then fdir=nfdir 
	;help,origdir
	
	if file_test(fr) then begin
	
	
	
	param=loadparam(fr)
;	print,origdir+'/leed.ini'
	if n_elements(param) gt 1 then $
	    begin
	    	tmp_spotsize=getval(param,'spot radius','float')
		if string(tmp_spotsize) ne "" then spotsize=tmp_spotsize
		
		tmp_areasize=getval(param,'area diameter','float')
		if tmp_areasize ne "" then areasize=tmp_areasize
		
		tmp_colortbl=getval(param,'color table','int')
		if tmp_colortbl ne "" then colortbl=tmp_colortbl
	    	
	    	tmp_filter=getval(param,'filter','string')
		if tmp_filter ne "" then filter=tmp_filter
	    	
	    	tmp_disptype=getval(param,'display type','string')
		if tmp_disptype ne "" then disptype=tmp_disptype

	    	tmp_thr=getval(param,'threshold','int')
		if tmp_thr ne "" then thr=tmp_thr

		
		tmp_r0=getval(param,'r0','int')
		if tmp_r0 ne "" then r0=tmp_r0
		
		tmp_x0=getval(param,'x0','int')
		if tmp_x0 ne "" then x0=tmp_x0
		
		tmp_y0=getval(param,'y0','int')
		if tmp_y0 ne "" then y0=tmp_y0
		
		tmp_r1=getval(param,'r1','int')
		if tmp_r1 ne "" then r1=tmp_r1
		
		tmp_x1=getval(param,'x1','int')
		if tmp_x1 ne "" then x1=tmp_x1
		
		tmp_y1=getval(param,'y1','int')
		if tmp_y1 ne "" then y1=tmp_y1
		
		help,areasize
		help,spotsize
		help,colortbl
		help,filter
		help,disptype
		help,thr
	    end
	loadct,colortbl
	imgchanged=1
	
	end
	
    end

"Save ini": $
    begin
        i_msg,"Select a file to write the .ini file"
	
	nfdir=""
	fr=dialog_pickfile(path=fdir,get_path=nfdir,filter="*.ini")
	if nfdir ne "" then fdir=nfdir 
	
	if fr ne "" then $
	    begin
		openw,lun,fr,/get_lun,width=16*(n_elements(wsp)+1)
		printf,lun,"spot radius"+string(spotsize)
		printf,lun,"area diameter"+string(areasize)
		printf,lun,"color table"+string(colortbl)
		printf,lun,"filter "+filter
		printf,lun,"display type "+disptype
		printf,lun,"threshold "+string(thr)
		printf,lun,"x0"+string(x0)
		printf,lun,"y0"+string(y0)
		printf,lun,"r0"+string(r0)
		printf,lun,"x1"+string(x1)
		printf,lun,"y1"+string(y1)
		printf,lun,"r1"+string(r1)
		close,lun
		msg=".ini succesfully written."
	    end else msg="No filename given, aborting."			
    end


;"Peak radius":$
;    begin
;    wset,0
;    inp=fix(i_input("Enter peaksize (4-64, currently "+strtrim(spotsize,2)+"): ",[0,0,300]))
;    if inp ge 4 and inp le 64 then begin
;	spotsize=round(inp)
;	end
;    end

;"Background size":$
;    begin
;    wset,0
;    inp=fix(i_input("Enter size of the background (16-256, currently "+strtrim(areasize,2)+"): ",[0,0,350]))
;    if inp ge 16 and inp le 256 then begin
;	areasize=round(inp)
;	end
;    end

"Exit&pass variables": begin
output={stack:data.stack,data_act:data_act,frscl:frscl,energy:data.energy,offset:offset,shadow:shadow,path:path,spot:spot,iv:iv}
i_msg,"Variables passed, bye!"
action="Exit"
end

"Exit": i_msg,"Bye!"

"Back":

"Read spots": $ ; reads the existing spot locations from a file
begin
    tmp_spot=readspots('',fdir,data.energy)
    ;print,tmp_spot
    if tmp_spot(0) ne -1 then begin
	spot=tmp_spot
	path(*,*,*)=0
    end
    
end


"Open new set": $ ; a copy of the initialization

begin
f=""
ndata=readleed(f,fdir)
if ndata.stack(0) ne -1 then $
begin
data=ndata
msg="New dataset succesfully loaded."
end else msg="Warning: Keeping the previous dataset."


;cmds=strarr(999)
counter=0
s=size(data.stack)
offset=[0,0] ;offset coordinates
frscl=-1
wsp=-1
rfactor=-1
iv=-1
shadow=-1
data_act=data.stack ;actual data
spot_i=0
;disptype="energy"
;disptyped=""
;filter="none"
;filterd=""
imgchanged=1
spot=intarr(99,s(1),2) ;array for coordinates of spots, max no. is 99
path=intarr(99,s(1),2) ;array for coordinates of paths, max no. is 99
ei=s(1)/2 ; index of actual energy
img=(data_act(ei,*,*)) ;actual image
window,1,xsize=640,ysize=200,title="LEED IV's"
window,0,xsize=s(2)>640+menuwidth,ysize=s(3)>480,title="LEED processing"
end


else: $
    begin
	msg="No associated action!"
	;cmds(counter-1)="unknown"
    end

endcase

if menu_sub(0) eq ">" then action="Back"

endrep until action eq "Exit" or action eq "Back"

endrep until action eq "Exit"

end

