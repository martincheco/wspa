;should take two 3D arrays and rotate 
;and zoom one onto another such that they'd match
;this requires a fitting and a measure of how good the fit is

function register_autocrop,res,coords=coords
;crops to an rectangle without nans
;at is an atomic unit cell that will get cut accordingly(but also collapsed)
;coords give back the limits
s=size(res.a)
if keyword_set(coords) then begin
	if coords(0) lt 0 then coords(0)=s(1)+coords(0)
	if coords(1) lt 0 then coords(1)=s(1)+coords(1)
	if coords(2) lt 0 then coords(2)=s(2)+coords(2)
	if coords(3) lt 0 then coords(3)=s(2)+coords(3)
	if coords(4) lt 0 then coords(4)=s(3)+coords(4)
	if coords(5) lt 0 then coords(5)=s(3)+coords(5)
	coords=double(coords)
	z1=coords(0)
	z2=coords(1)
	x1=coords(2)
	x2=coords(3)
	y1=coords(4)
	y2=coords(5)


end else begin

help,res.a
help,res.b
p=res.a*res.b
help,p
pz=total(total(p,3,/nan),2,/nan)
px=total(total(p,3,/nan),1,/nan)
py=total(total(p,2,/nan),1,/nan)
wx=where((px))
wy=where((py))
wz=where((pz))
if wx(0) eq -1 then begin
	x1=0
	x2=-1
end else begin
	x1=min(wx)
	x2=max(wx)
end
if wy(0) eq -1 then begin
	y1=0
	y2=-1
end else begin
	y1=min(wy)
	y2=max(wy)
end

if wz(0) eq -1 then begin
	z1=0
	z2=-1
end else begin
	z1=min(wz)
	z2=max(wz)
end
coords=double([z1,z2,x1,x2,y1,y2])
end
;help,res.a
;print,coords
return,{vect:res.vect,r:res.r,a:res.a(z1:z2,x1:x2,y1:y2),b:res.b(z1:z2,x1:x2,y1:y2),mhat:res.mhat}
end

pro register_dep,st,n1,n2,cut=cut,all=all,nocnt=nocnt,bs=bs,cc=cc,reg=reg,ovlp=ovlp
;makes and images a 2d histogram
;cut defines where to threshold the data (0..1)
;all causes the routine to use the entire stacks, not just slices
;reg will return regression pars
;cc will return correlation
;nocnt switches contour and linear fit imaging
if not(keyword_set(bs)) then bs=0.05
if keyword_set(all) then begin
	a=st.a
	b=st.b
end else begin

	if keyword_set(cut) then begin
		a=register_bkgstrip(st.a(n1,*,*))
		b=register_bkgstrip(st.b(n2,*,*))
	end else begin
		a=(st.a(n1,*,*))
		b=(st.b(n2,*,*))
	end

end

ff=finite(a*b)
w=where(ff)
if w(0) ne -1 then begin

	mna=min(a(w))
	mxa=max(a(w))
	mnb=min(b(w))
	mxb=max(b(w))
	h2d=hist_2d(a(w),b(w),bin1=bs,bin2=bs,min1=mna,min2=mnb,max1=mxa,max2=mxb)
	cc=correlate(a(w),b(w))
	ovlp=register_overlap(a,b)
	s=size(h2d)
	x=dindgen(s(1))*bs+mna
	y=dindgen(s(2))*bs+mnb
	if not(keyword_set(nocnt)) then contour,h2d,x,y,/fill,nlevels=128,/iso;,xrange=[-5.05,3.05],yrange=[-5.05,3.05],xst=1,yst=1
	reg=linfit(a(w),b(w),/double)
;	print,reg
;	print,cc
	yfit=reg(0)+reg(1)*x
	if (keyword_set(nocnt)) then oplot,x,yfit,color=round(cc*255D)>1L,psym=3

end
end

pro register_corr,st,reg=rega,cc=cca,ovlp=ovlpa,linf=linf,dep=dep
s=size(st.a)
a=st.a
b=st.b
device,decomposed=0
loadct,39
if keyword_set(dep) then register_dep,st,/all
loadct,0
rega=dblarr(2,s(1))*(-0./0.)
cca=dblarr(s(1))*(-0./0.)
ovlpa=cca
for i=0,s(1)-1 do begin
;	print,'Slice:',i
	cc=-0./0.
	reg=-0./0.
	ovlp=-0./0.
	if (keyword_set(linf)) then register_dep,st,i,i,/nocnt,cc=cc,reg=reg,ovlp=ovlp
	rega(*,i)=reg
	cca(i)=cc
	ovlpa(i)=ovlp
end


end


function btscl,ar,nan=nan
;bytescale ignoring nans
mx=max(ar,/nan)
mn=min(ar,/nan)

im=(255*(ar-mn)/(mx-mn))
if keyword_set(nan) then begin
	ff=finite(im,/nan)
	w=where(ff)
	if w(0) ne -1 then im(w)=0
end
return,im
end

function register_bkgstrip,img,lvl
imgn=img
s=size(img)
if not(keyword_set(lvl)) then lvl=0.5
for i=0,s(1)-1 do begin
	imgslc=img(i,*,*)
	mn=min(imgslc,/nan)
	mx=max(imgslc,/nan)
	w=where(imgslc lt (mn+lvl*(mx-mn)))
	imgslc(w)=0./0.
	imgn(i,*,*)=imgslc
end

return,imgn
end

function register_zoom,im,zom
s=size(im)
x=s(2)*zom
y=s(3)*zom
img=dblarr(s(1),x,y)*(-0./0.)
for i=0,s(1)-1 do $
if (where(finite(im(i,*,*))))(0) ne -1 then img(i,*,*)=congrid(reform(im(i,*,*)),x,y,/interp)

return,img
end

pro register_vis,r,g,file=file,linreg=linreg
;images two arrays as rgb composite
;linreg shows the deviation squares
rc=btscl(reform(r),/nan)
bc=btscl(reform(g),/nan)
gc1=255*finite(reform(r),/nan,sign=-1)*finite(reform(g)) 
gc2=255*finite(reform(g),/nan,sign=-1)*finite(reform(r))
gca=255*finite(reform(r),/nan,sign=-1)
gcb=255*finite(reform(g),/nan,sign=-1)
;rio=bytscl(reform(r)*reform(g),/nan)
gc=gc1+gc2
if keyword_set(linreg) then begin
	ldev=btscl((reform(r)-linreg*reform(g))^2,/nan)
	rgb=[[[ldev]],[[ldev]],[[ldev]]]
end else rgb=[[[rc+gc1]],[[gc+gc1+gc2]],[[bc+gc2]]]
;help,rgb

;rgb=[[[rio]],[[rio]],[[rio]]]
rgb1=[[[rc+gca]],[[rc+gca]],[[rc]]]
rgb2=[[[bc]],[[bc+gcb]],[[bc+gcb]]]
;help,rgb1
;help,rgb2
rgb=[rgb,rgb1,rgb2]
;help,rgb
if keyword_set(file) then write_png,file,transpose(rgb,[2,0,1])
tv,transpose(rgb,[2,0,1]),/true
end

function register_abpad,img,a,b,norot=norot
s=size(img)
sa=size(a)
sb=size(b)
mxz=max([sa(1),sb(1)])
mxx=max([sa(2),sb(2)])
mxy=max([sa(3),sb(3)])

if not(keyword_set(norot)) then mxx=mxx*2^0.5
if not(keyword_set(norot)) then mxy=mxy*2^0.5
im=dblarr(mxz,mxx,mxy)*(-0./0.)
;print,s
im(0:s(1)-1,mxx/2-s(2)/2:mxx/2-s(2)/2+s(2)-1,mxy/2-s(3)/2:mxy/2-s(3)/2+s(3)-1)=img
return,im
end

function register_overlap,a,b
;s=size(a)
;for i=0,s(1)-1 do begin
;	wa=where(finite(a(i,*,*))
;	wb=where(finite(b(i,*,*))
;	if wa(0) ne -1 and wb(0) ne -1 then begin
;		wab=where(finite(a(i,*,*)+finite(b(i,*,*)) eq 1)
;	end

;padding: to ignore
na=finite(a,/nan,sign=1)
nb=finite(b,/nan,sign=1)
;normal values
fa=finite(a)
fb=finite(b)
;background, sent to nan by thresholding (see register_bkgstrip)
ba=finite(a,/nan,sign=-1)
bb=finite(b,/nan,sign=-1)

;calculate the area, where there is no overlap (near ot edges)
w1=where(fa*bb)
w2=where(fb*ba)
;tvscl,total(fa*bb+fb*ba,1,/nan,/double)
nna=n_elements(where(fa*bb))
nnb=n_elements(where(fb*ba))

return,abs((nna-nnb)*(nna+nnb))

end

function register_mean,t

w=where(finite(t))
if w(0) ne -1 then return,total(t(w),/preserve)/n_elements(w) else return,0./0.

end

function register_stddev,t
w=where(finite(t))
if w(0) ne -1 then return,stddev(t(w),/double) else return,0./0.

end

function register_diff,a,b

;calculates the sum of squares for the two stacks

ax=a-register_mean(a)
bx=b-register_mean(b)
ax=ax/register_stddev(ax)
bx=bx/register_stddev(bx)
ab=ax-bx
w=finite(ab)
ww=where(w)
tot=total((ab(ww))^2,/preserve)

return,tot/double(n_elements(ww))
end

function register_cc_getmax,cc
;finds maximum in the crosscorrelation
m=max(abs(cc),loc)
s=size(cc)

ind=array_indices(cc,loc)
z=ind(0)
x=ind(1)
y=ind(2)

if x gt s(2)/2 then x=-(s(2)-x)
if y gt s(3)/2 then y=-(s(3)-y)
if z gt s(1)/2 then z=-(s(1)-z)

return,{ind:ind,dx:[z,x,y]}
end

function register_space,a,b,z1,z2,zstep,ang1,ang2,astep,fast=fast,vis=vis
;tries to zoom, rotate and translate a to fit b the best
;a,b - 3D arrays, z,x,y
;dx,dy,dz - translations extents in each directions
;ang1,ang2,astep - start,endpoint,step in angle
;z1,z2,zstep - zoom range in pixels
;fast - switch for fast rotation (low-quality)

a=double(a)
b=double(b)
;z=double(z)
sa0=size(a)
sb0=size(b)


zn=double(z2-z1)/zstep+1
;help,zn
zn=round(zn)
;help,zn
;init
dfz=dblarr(zn,abs(ang2-ang1)/astep+1)*0./0.
dfx=dfz
dfy=dfz
dfzm=dfz
dfa=dfz
dfmax=dfz
dffin=dfz
fnt=1
;help,dfz

for zm=0,zn-1 do begin ;the zoom
    ;help,zm
    zom=(zm*zstep+z1)
    ;help,zom
    az=register_zoom(a,zom)
    ;make the padded arrays
    ap=register_abpad(az,az,b)
    bp=register_abpad(b,az,b)
    sa=size(ap)
    for an=0,abs(ang2-ang1)/astep do begin ;the angle
	ang=an*astep+ang1
	apr=rot3d(ap,ang,fast=fast)
;	print,zom,ang
;		if keyword_set(vis) then tvscl,[btscl(reform(ap(0,*,*)))+btscl(reform(bp(0,*,*)))],/nan
		    
	cc=ccor(apr,bp,/nan,fnt=fnt)
	ff=finite(cc)
;	help,cc
	if total(ff) gt 0 then begin
		if keyword_set(vis) then tvscl,[btscl(reform(apr(0,*,*)))*btscl(reform(bp(0,*,*)))],/nan
		   
		coords=register_cc_getmax(cc)
		dfzm(zm,an)=zom
		dfa(zm,an)=ang
		dfx(zm,an)=coords.dx(1)
		dfy(zm,an)=coords.dx(2)
		dfz(zm,an)=coords.dx(0)
		dfmax(zm,an)=cc(coords.ind(0),coords.ind(1),coords.ind(2))
		dffin(zm,an)=fnt
	;	print,fnt
	end
    end
end

return,{x:dfx,y:dfy,z:dfz,a:dfa,zm:dfzm,cc:dfmax,w:dffin}
end

function register_func,vect,a,b,vis=vis,resa=resa,resb=resb,cov=cov,norot=norot,mhat=mhat,sav=sav
sa0=size(a)
zom=vect(0)
ang=vect(1)
dz=vect(2)
dx=vect(3)
dy=vect(4)
zr=[0.5,2.0]
if zom ge zr(0) and zom le zr(1) then begin
	;az=dblarr(sa0(1),zom*sa0(2),zom*sa0(3))
	if abs(zom-1.) gt 0.001 then az=register_zoom(a,zom) else az=a
	;for i=0,sa0(1)-1 do az(i,*,*)=congrid(reform(a(i,*,*)),zom*sa0(2),zom*sa0(3),/interp)
	;make the padded arrays
	ap=register_abpad(az,az,b,norot=norot)
	bp=register_abpad(b,az,b,norot=norot)
	if abs(ang) gt 0.01 then apr=rot3d(ap,ang,/accel) else apr=ap
	aprs=shift(apr,dz,dx,dy)
	if keyword_set(resa) then resa=aprs
	if keyword_set(resb) then resb=bp

	cc=(aprs*bp)
	ff=(finite(cc))
	;fnt=total(ff)
	w=where(ff)
;	dfmax3=linfit(aprs(w),bp(w),chisqr=chisqr,/double)
	dfmax=correlate(aprs(w),bp(w),/double,cov=cov)
	
;	linreg=linfit(aprs(w),bp(w),/double,chisq=chisq)

;	dfmax=-chisq
;	dfmax1=double((register_overlap(aprs,bp)))
	aprsw=aprs(w)
	bpw=bp(w)
	mhat = total(aprsw*bpw)/total(aprsw^2)
;	dfmax=-((TOTAL( ((bpw-MHAT*aprsw))^2 ,/double))^0.5)


	;print,dfmax
;dfmax=dfmax2
;	dfmax= - register_diff(aprs,bp)

	if keyword_set(vis) then register_vis,total(aprs,1,/nan),total(bp,1,/nan),file=sav;,linreg=mhat
return,(double(dfmax));/double(fnt)
end else return,(0D)

end

function register_iter,ao,bo,z0,ang0,dz0,dx0,dy0,step=step,vis=vis,cov=cov,norot=norot,at=at,sav=sav,mask=mask
if not(keyword_set(step)) then step=[.001,.2,.5,.5,.5]*16.
if keyword_set(mask) then step=step*mask
istep=step/16.
stp=0
vect=[z0,ang0,dz0,dx0,dy0]
sa0=size(ao)
sb0=size(bo)


if sa0(1) ne sb0(1) then begin
;enlarges one array to have the same z dim as the other
	sz=max([sa0(1),sb0(1)])
	a0=dblarr(sz,sa0(2),sa0(3))*0./0.
	b0=dblarr(sz,sb0(2),sb0(3))*0./0.
	a0(0:sa0(1)-1,*,*)=ao
	b0(0:sb0(1)-1,*,*)=bo
end else begin
	a0=ao
	b0=bo
end
sa0=size(a0)
sb0=size(b0)
if keyword_set(sav) then sv=sav+'0000.png'
rd=register_func(vect,a0,b0,vis=vis,cov=cov,norot=norot,mhat=mhat,sav=sv)	
rdx=rd
vectx=vect
s1=step*[1,0,0,0,0]
s2=step*[0,1,0,0,0]
s3=step*[0,0,1,0,0]
s4=step*[0,0,0,1,0]
s5=step*[0,0,0,0,1]
sm=[[s1],[s2],[s3],[s4],[s5]]
c=1L
repeat begin

if keyword_set(sav) then sv=sav+string(c,format='(I04)')+'.png'

c+=1

r=dblarr(5)-1D9
rm=r
	for i=0,4 do begin
		if sm(i,i) gt 0.00001 then r(i)=register_func(vect+sm(i,*),a0,b0,norot=norot,mhat=mhat)
		if sm(i,i) gt 0.00001 then rm(i)=register_func(vect-sm(i,*),a0,b0,norot=norot,mhat=mhat)	
	end
	mx=where(r gt rd)
	;print,'mx',mx
	if mx(0) ne -1 then begin
		w=where(r eq max(r))
		rdx=r(w(0))
		vectx=vect+sm(w(0),*)
		for i=0,n_elements(mx)-1 do vect=vect+(rd-r(mx(i)))/total(rd-r(mx))*sm(mx(i),*)
	end

	mxm=where(rm gt rd)
	;print,'mxm',mxm
	if mxm(0) ne -1 then begin
		w=where(rm eq max(rm))
 		rdx=rm(w(0))
		vectx=vect-sm(w(0),*)
		for i=0,n_elements(mxm)-1 do vect=vect-(rd-rm(mxm(i)))/total(rd-rm(mxm))*sm(mxm(i),*)
	end
	
	;print,'params:',vect
	if mx(0) eq -1 and mxm(0) eq -1 then begin
		sm=sm/1.5
		;print,"Decreasing speed"
		;print,'steps:',sm(indgen(5),indgen(5))
	end else begin
		rd=register_func(vect,a0,b0,vis=vis,norot=norot,mhat=mhat,sav=sv)
		if rd lt rdx then begin
			vect=vectx
			rd=rdx
		end 
	end


;help,rd

totsm=total(sm(indgen(5),indgen(5))/istep,/nan)
;help,totsm
endrep until totsm le 1.
;print,sm(indgen(5),indgen(5))
resa=1
resb=1
r=register_func(vect,a0,b0,vis=vis,resa=resa,resb=resb,norot=norot,mhat=mhat,sav=sv)
;print,"Final:",r, vect
if not(keyword_set(mhat)) then mhat=-1
return,{r:r,vect:vect,a:resa,b:resb,mhat:mhat}
end

pro register_fvis,st,nn,file=file
s=size(st.a)
n=(nn<(s(1)-1))>0
register_vis,st.a(n,*,*),st.b(n,*,*),file=file;,linreg=st.mhat
end

pro register_dump,st
s=size(st.a)
for i=0,s(1)-1 do begin
	w=where(finite(st.a(i,*,*)*st.b(i,*,*)))
	if w(0) ne -1 then $
		register_fvis,st,i,file="img_"+strtrim(string(i,format='(I04)'),2)+".png"	
end

end
