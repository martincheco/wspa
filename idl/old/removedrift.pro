
function rds,e,f
return, (LONG(e)^2+LONG(f)^2)
end

function acor,im
print, 'Creating autocorrelation..'
temp=fft(im,-1)
imf=fft(temp*CONJ(temp),-1)
return, imf
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
print,'Thresholding..'
s=size(img)
bla=img
if not(keyword_set(down)) then $
bla(where(bla lt barrier))=0 else bla(where(bla gt barrier))=0 
return, bla
end

function superfilter, im ;another filter
print, 'Removing alias..'
mskmsk=[[0.3,0.6,0.3],[0.6,0.9,0.6],[0.3,0.6,0.3]]
imgg= bytscl(smooth(((dilate(bytscl((im)),mskmsk*10,/gray))),2,/edge_truncate))
return,imgg<3*mean(imgg)
end

function filtrr,n,s1,s2
filtr=fltarr(s1,s2)

for r=0,s1-1 do for s=0,s2-1 do $
if ((rds(r-s1/2,s-s2/2) lt n/2) or (rds(r-s1/2,s-s2/2) gt 3.*n)) then $
filtr(r,s)=1.
;filtr(r,s)=1./(1.+float(rds(r-s1/2,s-s2/2))/float(n))

filtr=shift(filtr,s1/2,s2/2)
return, filtr
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


function rmdp, im, rdis
print,'Vectorizing..'
s=size(im)
a=where(im)
x=a mod s(1)
y=a / s(2)
c=a*0

cnt=0

print,'Trying to remove excess points..'

for i = 0,n_elements(a)-1 do begin
cnt=cnt+1
if not(c(i)) then c(i)=cnt
  for j= 0,n_elements(a)-1 do begin
    if (j lt i) and (rds(x(i)-x(j),y(i)-y(j)) lt rdis) then begin 
    c(j)=cnt
  end 
  endfor
endfor

for h=0,n_elements(c) do begin
wh=where(c eq h,pct)
if pct gt 1 then $
begin
x(wh)=mean(x(wh))
y(wh)=mean(y(wh))
c(wh(1:*))=0
end
endfor

;print, where(c)

x=x(where(c))
y=y(where(c))

;plot,x,y,psym=7
vect=intarr(n_elements(x),2)
vect(*,0)=x
vect(*,1)=y
return, vect
end

function gridparm, im,filtersize
filtersize=filtersize^2
lim=0.7
s=size(im)
print, 'EXTRACTING GRID CHARACTERISTICS!..'
imb=(acor(im))
if not(keyword_set(filtersize)) then $
filtersize=(n_elements(where((discr(imb,max(imb)/2)) ne 0)))*2.5

print,'Size of the filter',filtersize
ima=bytscl(shift(imb,s(1)/2,s(2)/2))
ima=ima*(1-(shift(filtrr(filtersize,s(1),s(2)),s(1)/2,s(2)/2)))
;tvscl,ima
contour,ima,nlevels=60,/iso,/fill
sdf=lmax(discr(ima,max(ima)*lim),1)
;tvscl, (ima)*(1+(discr(sdf,max(sdf)-1)))
sdff=rmdp(discr(sdf,max(sdf)-1),2)-s(1)/2 ;??
return, sdff
end

function Sivectors, sd
s1=500
s2=500
print, 'Extracting main vectors..'
s=size(sd)
lngth=rds(sd(*,0),sd(*,1))
sdfd=sd(sort(lngth),*)
sdfd=sdfd(0:5,*)
if n_elements(sdfd(*,0)) lt 6 then return,0
sdfd(where(sdfd(*,0) le 0),*)=0
sdfd=sdfd(where((sdfd(*,0) ne 0) or (sdfd(*,1) ne 0)),*)
;sdfd=sdfd(0:2,*)
sdfd=sdfd(sort(abs(sdfd(*,1))),*)
v_a=COMPLEX(sdfd(*,0),sdfd(*,1))
print,'Found',n_elements(v_a),'points'

;if abs(v_a(1)+v_a(0)) gt 1.2*(abs(v_a(1))+abs(v_a(0)))/2 then vv= v_a([0,1]) else $
;if abs(v_a(2)+v_a(0)) gt 1.2*(abs(v_a(2))+abs(v_a(0)))/2 then vv= v_a([0,2]) else vv= v_a([0,3])
oplot,s1/2+float(v_a),s2/2+imaginary(v_a),psym=1,color=0
oplot,s1/2+float(v_a(0:1)),s2/2+imaginary(v_a(0:1)),psym=4,color=0
return,v_a
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


function removedrift,im,n=n,hard=hard,fsize=fsize,base_i=base_i,im_ori=im_ori
;removes drift from images with hexagonal periodic structures (tested on 400x400 and 500x500px)
;is able to process single images or arrays with structure array(index,xcoord,ycoord)
;base_i is the index of image used to calculate the main lattice vectors
;/hard forces the preset orientation of the output
;fsize presets the cellsize, otherwise automatically selected
;n sets the expansion of the base vectors (in px), if not set,
;it is chosen the same as an average vector length
;autoscale sets n according to length of the vectors found
;ori_im can be given if im is a part of it; warping is then done on this, N/A for stacks
s=size(im)
print, 'Image type and dimensions:', s
ll=max([s(1),s(2)])
;if not(keyword_set(n)) then n=ll
;if not(keyword_set(typ)) then typ="Si"

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
  y=Sivectors(gridparm(imr,fsize))
  z=max([abs(y(1)),abs(y(0))]) ;maximum and minimum size of vectors found
  zz=min([abs(y(1)),abs(y(0))])

  ar=(y(0)/abs(y(0))*abs(y(1))/y(1))
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
 ;im=congrid(im_ori,so(1)*2,so(2)*2,cubic=-0.5)
 if so(0) gt 1 then begin
  imm=im_ori
   for i=0,so(0)-1 do begin
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