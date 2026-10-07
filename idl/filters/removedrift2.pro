

function rds,e,f
return, (LONG(e)^2+LONG(f)^2)
end

function acor,im
print, 'Creating autocorrelation..'
temp=fft(im,-1)
imf=fft(temp*CONJ(temp),-1)
return, imf
end


function dir_matrix,ima
ima=float(ima)
s=size(ima)
r=min([s(1),s(2)])/2
mtrix=fltarr(r+2,360)
cxa=fltarr(2,360)

for i=0,359 do begin
cx=(r-1)*cos((!PI*i)/180.)+s(1)/2
cy=(r-1)*sin((!PI*i)/180.)+s(2)/2
cxa(0,i)=cx
cxa(1,i)=cy
mp=mprofile(ima,s(1)/2,cx,s(2)/2,cy)
mtrix(0:n_elements(mp)-1,i)=mp
end

return,mtrix(0:r-4,*)
end


function lmax,img,w
print, 'Searching for local maxima..'
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

function discr,img,barrier,down=down ; oreze hodnoty
;print,'Thresholding..'
s=size(img)
bla=img
if not(keyword_set(down)) then $
bla(where(bla lt barrier))=0 else bla(where(bla gt barrier))=0 
return, bla
end


function fiiltrr,n,s1,s2
fiiltr=intarr(s1,s2)

for r=0,s1-1 do for s=0,s2-1 do if (rds(r-s1/2,s-s2/2) lt n) then fiiltr(r,s)=1
fiiltr=shift(fiiltr,s1/2,s2/2)
return, fiiltr
end


function rowfilter,im
s=size(im)
imf=im
flt=fiiltrr(5000.,s(1),s(2))
flt=flt(*,0)
;plot,flt
for i=0,s(2)-1 do imf(*,i)=fft(fft((im(*,i)),-1)*(flt))
return,imf
end


function gridparm, im
lim=0.7
s=size(im)
print, 'EXTRACTING GRID CHARACTERISTICS!..'
imb=(acor(im))
;imb=smooth(imb,3,/edge_wrap)-smooth(imb,10,/edge_wrap)
ima=bytscl(shift(imb,s(1)/2,s(2)/2))
radial_dist=smooth(dir_matrix(ima),3,/edge)
contour,(radial_dist),/iso,color=125

sr=size(radial_dist)
sign_dirs=dblarr(sr(2))

for i=0,sr(2)-1 do sign_dirs(i)=(variance(reform(radial_dist(*,i)))) ;finding variances of the profiles taken under different angles

;sign_dirs=convol(sign_dirs,[0.25,0.5,1.,0.5,0.25]/2.5)

sgd=local_max_circ(sign_dirs,10) ;finds the biggest variances

pos_max=where(discr(sgd,max(sgd)/3)) ;discards small maxima



sgdd=sgd(pos_max)

print,'Main angles:',pos_max

;oplot,intarr(n_elements(pos_max))+100,pos_max,psym=5

radss=pos_max

for i=0,n_elements(pos_max)-1 do begin

cut=reform(radial_dist(*,pos_max(i))) ;gets profiles in significant angles
rads=local_max(cut,5) ;finds local maxima
radsi=where(discr(rads,max(rads)/2)) ;discards small local maxima
radsi=radsi(where(radsi gt 10)) ;discards radii smaller than 10
;print,'radsi',radsi
radrs=cut(radsi)
;print,'radrs',radrs
;radrs=(max(radrs)-radrs)
;radsi=radsi((sort(radsi)))
;help,radsi
;print,'radsi',radsi(0)
radss(i)=radsi(0)
end


;print,'radss',radss
pos_max=pos_max((sort(radss))) ;sorts maxima by distance
radss=radss((sort(radss)))
nn=n_elements(pos_max)-1
pos_max=pos_max(0:nn) ;takes only first biggest
radss=radss(0:nn)
radss=radss(sort(pos_max))
pos_max=pos_max(sort(pos_max)) ;sorts by angle
;print,pos_max
pos_max_diff=abs(abs(pos_max(1:nn)-pos_max(0:nn-1)) - 60) ;finds differences of subsequent angles
;print,pos_max_diff
pos_max_ind=where(pos_max_diff eq min(pos_max_diff)) ;gets the two which have the difference nearest to 60DEG
pos_max=shift(pos_max,-pos_max_ind(0)) ;shifts the array to get these two to beginning of the array 
radss=shift(radss,-pos_max_ind(0)) ;shifts the array to get these two to beginning of the array 



oplot,radss,pos_max,psym=1
pos_max=pos_max(0:1)
radss=radss(0:1)

print,pos_max,radss
ccx=radss*cos(!PI*pos_max/180.)
ccy=radss*sin(!PI*pos_max/180.)

;print,ccx
;print,ccy

;contour,bytscl(ima),/cell_fill,nlevels=20
;oplot,ccx+s(1)/2,ccy+s(2)/2,psym=1
oplot,radss,pos_max,psym=2
vect=intarr(n_elements(ccx),2)
vect=COMPLEX(ccx,ccy)
return, vect
end

function mosaicvectors, sd
print, 'Extracting main MOSAIC vectors..'
s=size(sd)
lngth=rds(sd(*,0),sd(*,1))
sdfd=sd(sort(lngth),*)
sdfd(where(sdfd(*,0) le 0),*)=0
sdfd=sdfd(where((sdfd(*,0) ne 0) or (sdfd(*,1) ne 0)),*)
return, COMPLEX(sdfd(0:1,0),sdfd(0:1,1))
end

function ttrans,yf,yif,p,q

y1x=float(yf(0))
y1y=imaginary(yf(0))

y2x=float(yf(1))
y2y=imaginary(yf(1))

i1x=float(yif(0))
i1y=imaginary(yif(0))

i2x=float(yif(1))
i2y=imaginary(yif(1))

print,p,q

b=(q*y1x-p*y1y)/(y2y*y1x-y2x*y1y)

a=(p-y2x*b)/y1x

;a=((p-q)*y2y)/(y1x*y2y-y1y*y2x)

;b=(p-a*y1x)/y2x

print,a,b

m=a*yif(0)+b*yif(1)

return,m
end


function removedrift2,im,n=n,hard=hard,fsize=fsize,base_i=base_i,im_ori=im_ori
;removes drift from images with hexagonal periodic structures (tested on 400x400 and 500x500px)
;is able to process single images or arrays with structure array(index,xcoord,ycoord)
;base_i is the index of image used to calculate the main lattice vectors
;/hard forces the preset orientation of the output
;fsize presets the cellsize, otherwise automatically selected
;n sets the expansion of the base vectors (in px), if not set,
;it is chosen the same as an average vector length
;autoscale sets n according to length of the vectors found
;im_ori can be given if im is a part of it; warping is then done on this, N/A for stacks
s=size(im)
;if (s(1) mod 2) eq 0 then im=im(1:s(1)-1,*)
;if (s(2) mod 2) eq 0 then im=im(*,1:s(2)-1)
s=size(im)
print, 'Image type and dimensions:', s

ll=max([s(1),s(2)])

if s(0) eq 3 then begin 
 if not(keyword_set(base_i)) then base_i=0 
 immm=reform(im(base_i,*,*),s(2),s(3))
 n_i=s(1)-1
 print,'Multi-channel image detected'
end else begin
 n_i=0
 immm=im
 print,'Simple image detected'
end

;tvscl,immm
imr=(smooth((subtrplane(extremesexcluded(immm))),2))
tvscl,imr
sz=size(imr)
print,sz
  y=gridparm(imr)
  
  
  z=max([abs(y(1)),abs(y(0))]) ;maximum and minimum size of vectors found
  zz=min([abs(y(1)),abs(y(0))])

  ar=(y(0)/abs(y(0)))*(y(1)/abs(y(1)))
  arg=atan(imaginary(ar)/float(ar))
  print,'The vectors found have a',arg*180./!PI,'DEG delta. Should be in the (0,90) interval'

  if keyword_set(hard) then begin ; default values of Si(111) vectors, unit size
  yiy=[-0.5,0.5]
  yix=[0.866,0.866]
  yi=COMPLEX(yix,yiy) ;going complex is simpler ;) 
  print,'Forcing the vectors..'
  end else begin 
  yi=y/abs(y)
  endelse

;rotating the vectors so they have the right DELTA
; ttt=complex(0.5,0.866)
; if arg lt 0 and abs(arg) lt then yi(1)=yi(0)*ttt*ttt else yi(1)=yi(0)/ttt/ttt 
;  if arg lt 0 and arg lt -!PI/2 then yi(1)=yi(0)*ttt
  


print,'Vectors extracted by gridparm: ',y

if not(keyword_set(n)) then begin
n=abs(zz)/(2^0.5)
print,'Autoscaling, using n = ',n
end
;yi=n*zz*yi/z/ll
yi=n*yi
print,'Scaled vectors being used: ',yi
gx=[0.,sz(1),0.,sz(1)]
gy=[0.,0.,sz(2),sz(2)]

ggg=ttrans(y,yi,gx,gy)

gix=float(ggg)
giy=float(imaginary(ggg))

gix=gix-mean(gix)+ll/2 ;centering of the output
giy=giy-mean(giy)+ll/2


if n_i ne 0 then begin
imm=im
for i = 0,n_i do begin
print,'Warping image of index ',i
imrg=im(i,*,*)
imrg=(reform(imrg,s(2),s(3)))
;help,imrg
;tvscl,imrg
imm(i,*,*)=warp_tri(gix,giy,gx,gy,imrg); no filters

;imm(i,*,*)=warp_tri(gix,giy,gx,gy,(removeartifacts(subtrplane(imrg)))); removeartifacts for simple fft filtering
;help,imm
end
end else begin
;imm=warp_tri(gix,giy,gx,gy,(removeartifacts(subtrplane(im)))); removeartifacts for simple fft filtering

if keyword_set(im_ori) then begin
 so=size(im_ori)
 print, 'multichannel image data dimensions:',so
 ;im=congrid(im_ori,so(1)*2,so(2)*2,cubic=-0.5)
 if so(0) gt 1 then begin
  imm=im_ori
   for i=0,so(1)-1 do begin
    im=reform(im_ori(i,*,*))
    imm(i,*,*)=warp_tri(gix,giy,gx,gy,im); no filtering
   endfor
 end else $
 begin
  im=im_ori
 end

end else $
begin
 imm=warp_tri(gix,giy,gx,gy,im); no filtering
end

end
;tvscl,imm
return,imm
end