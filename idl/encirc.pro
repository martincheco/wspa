;function follow_spot,im
;s=size(im)
;rlim=5
;rstart=10
;coords=dblarr(s(1),2)
;magnitude=dblarr(s(1))

;for i=0,s(1)-1 do begin
;coords(i,*)=encirc(im(i,*,*),rstart,rlim)
;magnitude(i)=im(i,0<coords(i,0)<s(2),0<coords(i,1)<s(3))
;end
;magnitude=reform(total(im,1))
;magnitude=magnitude(coords(*,0),coords(*,1))

;contour,total(im,1),/fill,/iso,nlevels=60
;xyouts,coords(*,0),coords(*,1),"*";,color=256-bytscl((magnitude))
;return,coords
;end


function encirc,im,rstart,rlim,xstart,ystart,show=show,dmp=dmp ;finds the position in the image by the circle method
;print,rstart,rlim,xstart,ystart
;dmp returns zero coords if convergence did not occur
img=bytscl(reform(im))
s=size(img)
delay=2
r=dblarr(s(1)*4+1)
x=r
y=r

if not(keyword_set(rstart)) then r(0)=double(min([s(1),s(2)])/2-2) else r(0)=rstart
if not(keyword_set(rlim)) then rlim=r(0)/20+5
if not(keyword_set(xstart) and keyword_set(ystart)) then begin
  x(0)=double(s(1))/2
  y(0)=double(s(2))/2
end else begin
x(0)=xstart
y(0)=ystart
end

;print,r(0),rlim,x(0),y(0)

i=0

while i lt r(0)*2 do begin
  divs=r(i)*2
  df=2*!PI/divs
  xr=round(r(i)*cos(findgen(divs)*df)+x(i))
  yr=round(r(i)*sin(findgen(divs)*df)+y(i))
  vect=img(xr,yr)
  sm_vect=vect;(smooth(vect,round(divs/20))>2)
  dir=where(sm_vect eq max(sm_vect))
  dir=round(dir(0))
  i=i+1
  x(i)=((x(i-1)+(xr(dir)-x(i-1))/r(i-1)))
  y(i)=((y(i-1)+(yr(dir)-y(i-1))/r(i-1)))
  if r(i-1) gt rlim then r(i)=r(i-1)-0.5 else r(i)=r(i-1)

  ;imgcp=bytscl(img)
  ;imgcp(xr,yr)=255
  ;tvscl,imgcp

end

if keyword_set(show) then begin
imgcp=bytscl(img)
imgcp(xr,yr)=255
tvscl,imgcp
end

xc=x(i-1)
yc=y(i-1)
if ((xc-x(0))^2+(yc-y(0))^2) gt r(0)^2 then $
    if keyword_set(dmp) then begin
	xc=0
	yc=0
    end else begin
	xc=xstart
	yc=ystart
    end

return,[xc,yc]
end 


function spotstat,spotstack

s=size(spotstack)
spot_mean = dblarr(s(1))
spot_var = dblarr(s(1))
tot = dblarr(s(1))
for i=0,s(1)-1 do begin
circ=encirc(spotstack(i,*,*))
spot_mean(i)=mean(circ)
spot_var(i)=variance(circ)
tot(i)=total(spotstack(i,*,*))
end

plot,spot_var/max(spot_var)
oplot,spot_mean/max(spot_mean),psym=5
oplot,tot/max(tot),psym=-2
return,spot_var

end

;***************obsolete*******************

function circ,img,x,y,r,divs,angle,amp,slope=slope

s=size(img)

df=2*!PI/divs
vect=intarr(divs)
sine=intarr(divs)
sined=intarr(divs)
cor=lonarr(divs)

;for i=0,divs-1 do begin
;xr=round(r*cos(i*df)+x)
;yr=round(r*sin(i*df)+y)
;vect(i)=img(xr,yr)
;end
;contour,img,nlevels=60,/fill
xr=round(r*cos(findgen(divs)*df)+x)
yr=round(r*sin(findgen(divs)*df)+y)
vect=img(xr,yr)
;oplot,xr,yr,psym=6
ampl=total(smooth((vect-mean(vect)),3)^2)^0.25
sine=ampl*sin(findgen(divs)*df)

plot,vect-mean(vect)

for i=0,divs-1 do begin
cor(i)=total((vect-shift(sine,i))^2)
end

mn=where(cor eq min(cor))
mn=mn(0)
sined=ampl*sin((findgen(divs)-mn)*df)
oplot,sined

angle=double(mn)/divs*360
amp=ampl 
if keyword_set(slope) then begin
slope=img*0

sy=double(sine(0))/r
sx=double(sine(divs/4))/r

slopex=findgen(s(1)) # replicate(sx/s(1),s(2)) 
slopey=findgen(s(2)) # replicate(sx/s(2),s(1)) 
slopey=transpose(slopey)
return,img-mean(vect)-slopex-slopey
end else $ 
return,vect
end 


function analyze_spot,st,r
;follows a spot of the normalized stack
tvscl,total(st.stack,1)
cursor,xrough,yrough,/up,/device

wstack=st.stack(*,xrough-r:xrough+r,yrough-r:yrough+r)
wstack_r=wstack
xrough=r/2
yrough=r/2
s=size(wstack)

ivcurve=lonarr(s(1))
ivcurve2=ivcurve
ivcurve3=ivcurve
xmax=ivcurve
ymax=ivcurve
imax=ivcurve

for i=0,s(1)-1 do begin
wstacks=circ(reform(wstack(i,*,*)),xrough,yrough,r,360,/slope)
wstacks2=reform(wstack(i,*,*))
imaxi=where(wstacks eq max(wstacks))
imax(i)=imaxi(0)
xmax(i)=imax(i) mod (2*r+1)
ymax(i)=imax(i) / (2*r+1)
ivcurve(i)=total(wstacks)
wstack_r(i,*,*)=wstacks
ivcurve2(i)=total(wstacks2-min(wstacks2))
ivcurve3(i)=total(wstacks2)
end
;plot,ivcurve3
;oplot,ivcurve2,color=150
;oplot,ivcurve
;print,pendry(st.energy,ivcurve>2,ivcurve2)

for i=0,s(1)-1 do begin
contour,(wstack_r(i,*,*)),nlevels=60,/fill,/iso,zrange=[0,256]
oplot,[0,xmax(i)],[0,ymax(i)],psym=-5
wait,0.05
end

valids=(where(abs(xmax-r) lt r and abs(ymax-r) lt r))
plot,st.energy,ivcurve
return,ivcurve
end

function deadpx,stack
nstack=stack
s=size(stack)
for i=0,s(2)-1 do begin
  for j=0,s(3)-1 do begin
    vect=reform(stack(*,i,j))
    if variance(vect) lt 100 or mean(vect) gt 50 then nstack(*,i,j)=vect*0
  end
end

return,nstack
end