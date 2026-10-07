function derivation,img
s=size(img)
new=img
for j=0, s(2)-2 do $
new(j,*)=img(j,*)-img(j+1,*)
img=new+70
return,img
end

pro vi, img
s=size(img)
window,1,xsize=s(1),ysize=s(2),xpos=1,ypos=2,title='vi'
wset,1
;tv,img
end






;pro cts,img
;ctb=[0,1,3,4,15,9,11,8,29]
;for i= 0,8 do begin
;s=size(img)
;window,1,xsize=s(1),ysize=s(2) ,xpos=1,ypos=1
;loadct,ctb(i)
;print,ctb(i)
;tv,img
;cursor,x,y,/down
;endfor
;end


function histeqA,imgx,wx
sx=size(imgx)
;print,min(imgx),max(imgx)
;imgx=imgx-min(imgx)+1
print,min(imgx),max(imgx)
nimgx=imgx
for ix=wx+1,sx(1)-wx-1 do $
for jx=wx+1,sx(2)-wx-1 do begin
if jx eq wx+1 then print,ix
px=histogram(nimgx(ix-wx:ix+wx,jx-wx:jx+wx))
for kx=1,n_elements(px)-1 do px(kx)=px(kx)+px(kx-1) ;integrate

imgx(ix,jx)=px(nimgx(ix,jx))
endfor
return,imgx
end

function histeqAc,img,w
s=size(img)
nimg=img
for i=w+1,s(1)-w-1 do begin
 p=histogram(nimg(i-w:i+w,1:2*w+1))
 for k=1,n_elements(p)-1 do p(k)=p(k)+p(k-1) ;integrate
   print,i

  for j=w+1,s(2)-w-2 do begin
   adp=histogram(nimg(i-w:i+w,j+w+1))
   for k=1,n_elements(adp)-1 do adp(k)=adp(k)+adp(k-1) ;integrate
   sbp=histogram(nimg(i-w:i+w,j-w))
   for k=1,n_elements(sbp)-1 do sbp(k)=sbp(k)+sbp(k-1) ;integrate
   p=p+adp-sbp
   img(i,j)=p(nimg(i,j))
 endfor

endfor

end


function lmax,img,w
s=size(img)
lmx=bytarr(s(1),s(2))

for i=w,s(1)-w-1 do $
for j=w,s(2)-w-1 do begin
mx=0
for k=i-w,i+w do $
for l=j-w,j+w do if mx le img(k,l) $
and ((k-i)^2+(l-j)^2) le w*w then $
begin
	km=k
	lm=l
	mx=img(k,l)
    endif
lmx(km,lm)=lmx(km,lm)+1.
endfor
return, lmx
end

function discr,img,barrier,up
s=size(img)
bla=img
if up eq 1 then begin
for i=0,s(1)-1 do $
for j=0,s(2)-1 do $
if bla(i,j) lt barrier then bla(i,j)= 0 else bla(i,j)=255
endif else begin
for i=0,s(1)-1 do $
for j=0,s(2)-1 do $
if bla(i,j) gt barrier then bla(i,j)= 0
endelse
return, bla
end

function dx,img
d=img
s=size(img)
for i=1,s(1)-2 do $
d(i,*)=(img(i+1,*)-img(i-1,*))/2.
d(0,*)=(-3.*img(0,*)+4*img(1,*)-img(2,*))/2.
d(s(1)-1,*)=-(-3.*img(s(1)-1,*)+4*img(s(1)-2,*)-img(s(1)-3,*))/2.
return,d
end

function dy,img
d=img
s=size(img)
for i=1,s(1)-2 do $
d(*,i)=(img(*,i+1)-img(*,i-1))/2.
d(*,0)=(-3.*img(*,0)+4*img(*,1)-img(*,2))/2.
d(*,s(1)-1)=-(-3.*img(*,s(1)-1)+4*img(*,s(1)-2)-img(*,s(1)-3))/2.
return,d
end

function lmax2,img
s=size(img)
drx=dx(img)
dry=dy(img)
ddrx=dx(drx)
ddry=dy(dry)
ddrxy=dy(drx)
ddryx=dx(dry)
bla=bytarr(s(1),s(2))
for i=0,s(1)-1 do $
for j=0,s(2)-1 do $
if (abs(round(drx(i,j))) lt 0.00000001) and (abs(round(dry(i,j))) lt 0.00000001) $
and (ddrx(i,j) gt 0.) and (ddry(i,j) gt 0.) then bla(i,j)=255B

return,bla
end

pro leed,f
img=read_tiff('/home/stma/Si.tif')

img=img(100/6:499/6,25/6:424/6);^1/2
;img=bytscl(convol(img,intarr(2,2)+1./4.))
s=size(img)
window,1,xsize=400, ysize=400
tv,img

;img=shift(img, s(1)/2,s(2)/2)
imga=lmax(img,2)^1./2.
;imga=bytscl(convol(imga,[[1,1,1,1],[1,1,1,1],[1,1,1,1]]))
;imga=lmax(img,2)
;print, max(imga)
imga=discr(imga,max(imga)*0.6,1)
imgf=rebin(imaginary(fft(img)), s(1)*6,s(2)*6)
imgg=rebin(imga*img,s(1)*6,s(2)*6)
tvscl,imgg
tvscl,imgf
;window,2
;shade_surf,imgf
end

function read_auger,f
c=intarr(1000)
i=1
openr,1,f
while not(eof(1)) do begin
readf,1,a
;print,a,i
c(i)=round(a)
;print,c(i)
if i lt 1000 then i=i+1
end
close,1
return,c(2:i-1)
end
