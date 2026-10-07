function sts_coords,t,m
;converts coordinates of sts to pixel values
;t - ptrarr of sts
;m - image pointer, one channel

r=stsmapstruct(t)
n=n_elements(t)
xy=lonarr(n,2)


xm=getval(m.par,'X Offset:','float')
ym=getval(m.par,'Y Offset:','float')



xrel=r.x-xm
yrel=r.y-ym
s=size(m.img)
xs=1E-9*m.xsize
ys=1E-9*m.ysize
help,xrel
help,xy
xy(*,0)=round((xrel/xs+0.5)*float(s(1)))
xy(*,1)=round((yrel/ys+0.5)*float(s(2)))

return,xy
end


function sts_refine,xy,img,tol
;uses encirc function (search for the nearby maximum)
n=n_elements(xy(*,0))
nxy=xy*0
for i=0,n-1 do begin
	nxy(i,*)=encirc(img,tol,1,xy(i,0),xy(i,1))
end

return,nxy
end


function sts_2dhist,ptr,chan,nx,zcorr=zcorr
;makes a 2D hist plot of the given pointer arr of sts
n=n_elements(ptr)
r=stsmapstruct(ptr,zcorr=zcorr)
if not(keyword_set(ny)) then ny=nx*2
rxr=r.data(*,0,*)
ryr=r.data(*,chan,*)

dx=double(r.data(0,0,0)-r.data(0,0,-1))/n_elements(r.data(0,0,*))
help,dx

xmx=max(rxr,/nan)
ymx=max(ryr,/nan)
xmn=min(rxr,/nan)
ymn=min(ryr,/nan)

help,xmx
help,xmn

nx=abs((xmx-xmn)/dx)

help,nx
if not(keyword_set(ny)) then ny=nx*2
hh=intarr(nx,ny)

rxr=r.data(*,0,*)
for i=0,n-1 do begin
	rx=r.data(i,0,*)
	ry=r.data(i,chan,*)
	rxn=nx*(rx-xmn)/(xmx-xmn)
	ryn=ny*(ry-ymn)/(ymx-ymn)
;	plot,rxn,ryn
	hh(rxn,ryn)+=1
end

return,hh
end

pro stsmapvis,t,m,chan=chan,offs=offs,refine=refine,nxy=nxy,vals=vals
;visualize sts (pointer array) on the image (structure m)
if not(keyword_set(chan)) then chan=0
if not(keyword_set(offs)) then offs=[0D,0D]

xy=sts_coords(t,m(chan))
xy(*,0)+=offs(0)
xy(*,1)+=offs(1)

if keyword_set(refine) then begin
	tol=(refine>2)<10
	nxy=sts_refine(xy,smooth(m(chan).img,tol/2,/edge_wrap),tol)
end else nxy=xy
contour,m(chan).img,/iso,nlevels=128,/fill,xst=1,yst=1
oplot,xy(*,0),xy(*,1),psym=3,color=128
oplot,nxy(*,0),nxy(*,1),psym=3,color=255

im=bytscl(m(chan).img)
vals=im(nxy(*,0),nxy(*,1))
end
