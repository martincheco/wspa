function mnea, im
fg=mean(im(where(bytscl(im) ne 0)))
return,fg
end

function rowfilter,im
s=size(im)
imf=im
flt=fiiltrr(5000.)
flt=flt(*,0)
;plot,flt
for i=0,s(2)-1 do imf(*,i)=fft(fft((im(*,i)),-1)*(flt))

return,imf
end


function rds,e,f
return, (LONG(e)^2+LONG(f)^2)
end

function ffft,ghj
ghjj=fft(ghj)
ghjj(0,0)=0
ghjj(0,399)=0
ghjj(399,0)=0
ghjj(399,399)=0
return,ghjj
end


function acor,im,shift=shift
s=size(im)
print, 'Creating autocorrelation..'
temp=fft(im,-1)
imf=fft(temp*CONJ(temp),-1)
if keyword_set(shift) then imf=shift(imf,s(1)/2,s(2)/2)
return, imf
end

function shft,im
s=size(im)
imf=shift(im,s(1)/2,s(2)/2)
return,imf
end

function lmax,img,w
print, 'Searching for local maxima..'
s=size(img)
lmx=bytarr(s(1),s(2))

for i=w,s(1)-w-1 do $
for j=w,s(2)-w-1 do begin
mx=0

km=i
lm=j
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
bla(where(bla ne 0))=255
return, bla
end


function rd_int_img,f,x,y ;function reads a binary datafile 

if not(keyword_set(f)) then $
f = dialog_pickfile(/read, /must_exist, filter = '*.t**')

if not(keyword_set(x)) or not(keyword_set(y)) then $
begin
x=400
y=400
end
print,'Reading file:',f
openr,1,f,/swap_if_little_endian
status=fstat(1)
print,status.size
if (long(status.size/2) ge long(x*y)) then $
begin
a=intarr(x,y)
readu,1,a
end
close,1

return,a

end

function filtrr,n
filtr=fltarr(400,400)

for r=0,399 do for s=0,399 do if (rds(r-200,s-200) lt n) then filtr(r,s)=1./(1.+float(rds(r-200,s-200))/float(n))
filtr=shift(filtr,200,200)
return, filtr
end


function fiiltrr,n
fiiltr=intarr(400,400)

for r=0,399 do for s=0,399 do if (rds(r-200,s-200) lt n) then fiiltr(r,s)=1
fiiltr=shift(fiiltr,200,200)
return, fiiltr
end

function dewaveise, im,width=width ;odstrani lockin sum z obrazku
print, 'Removing alias..'
;imgf=extremesexcluded(imgf)
;imgf=extremesexcluded(imgf)
;imgf=extremesexcluded(imgf)
;imgf=extremesexcluded(imgf)

imgf=fft(im,-1)

if not(keyword_set(width)) then filterr=filtrr(3600) else filterr=filtrr(width^2)
imgf=imgf*Complex(filterr,filterr*0.)
imgf(0:2,0:2)=0
imgf(398:*,0:2)=0
imgf(0:2,398:*)=0
imgf(398:*,398:*)=0
imgg=fft(CONJ(imgf));smooth(fft(CONJ(imgf)),2, /edge_truncate)
return,(imgg)
end


function mosaicPb,im,overall=overall,autocut=autocut
imr=bytscl(float(subtrplane(smooth(dewaveise(im),3))))

window,1,xsize=410,ysize=400
;imr=bytscl(imr-smooth(subtractplane(imr),100,/edge_truncate))

if not keyword_set(overall) then begin

if not(keyword_set(autocut)) then begin

print,'Choose threshold, click beyond the image when satisfied.'

xv=349L
xvv= xv*255/400
tv,discr(imr,xvv)

while xv lt 400L do begin
xvvd=xvv
cursor,xv,yv,/device
xvv=LONG(xv)*255/400
print,xvv
if xv gt 399L then dddd=discr(imr,xvvd) else $ 
tv,discr(imr,xvv)
end


;dddd=discr(imr,xvvd)
;dddd(where(dddd ne 0))=1

;dddd=bytarr(400,400)
mask1=not(dddd)

print,'Choose upper threshold, click beyond the image when satisfied.'

xv=150L
xvv= xv*255/400
tv,discr(imr,xvv,/down)

while xv lt 400L do begin
xvvd=xvv
cursor,xv,yv,/device
xvv=LONG(xv)*255/400
print,xvv
if xv gt 399L then ddddd=discr(imr,xvvd,/down) else $ 
tv,discr(imr,xvv,/down)
end


;dddd=discr(imr,xvvd)
;dddd(where(dddd ne 0))=1

;dddd=bytarr(400,400)
mask2=not(ddddd)

endif else begin

mask1=not(discr(imr,320L*255/400))
mask2=not(discr(imr,150L*255/400,/down))


end


tv,(mask1 and mask2) * imr
endif else begin

mask1=not(discr(imr,150L*255/400,/down))
mask1=not(mask1)
mask2=mask1
end

return,mask1 and mask2
end



function takeit, im,imcurr,alll=alll
window,2,xsize=400,ysize=400
tvscl,im
if not(keyword_set(alll)) then mask=mosaicPb(imcurr,/autocut) else mask=mosaicPb(imcurr,/overall)

dlnIdlnV=(mnea(mask*((0.1*im)-min(0.1*(im)))))
print,min(0.1*im)
print,min(0.1*im-min(0.1*im))
proud=mnea(mask*imcurr)

signo1=mnea((abs(ffft(im)))*fiiltrr(3600))
signo2=mnea((abs(ffft(im))*(1-fiiltrr(3600))))
signo3=mnea(abs(ffft(im)))

absolute_result=[dlnIdlnV,proud,signo2,signo3]

return, absolute_result
end

pro saveu,f,dat,nonfo=nonfo
openw,3,f
writeu,3,dat
close,3
if keyword_set(nonfo) then begin
print,'saveu: why not.. :)'
end $
else $
begin
openw,4,f+'.nfo'

printf,4,size(dat)
printf,4,dat
close,4
end
end

function loadu, f
openr,5,f
status=fstat(5)
a=fltarr(3,status.size/12)
readu,5,a
close,5
return,a
end

function filelist,f
if not(keyword_set(f)) then f=dialog_pickfile(/read, /must_exist, /multiple_files, filter = '*.tf1')

as=fltarr(n_elements(f))
for i=0,n_elements(f)-1 do $
begin
fd=f(i)
strput,fd,'par',strpos(fd,'tf1')
d=loadstm(fd)
help,(d.parameters.voltageforward)
as(i)=(d.parameters.voltageforward)
endfor
ase=string(as(sort(as)))
f=f(sort(as))
print,transpose([[ase],[f]])

return,transpose([[ase],[f]])
end


function datadig,lst=lst,all=all
;reads the selected files and construct an array of (dI/dV)/(I/V)
goldpalette
if not(keyword_set(lst)) then f = dialog_pickfile(/read, /must_exist, /multiple_files, filter = '*.tf1') $
else $
begin
f = Content(/compress)
for i=0,n_elements(f)-1 do $
begin
fd=f(i)
strput,fd,'tf1',strpos(fd,'par')
f(i)=fd
end
end

ads=fltarr(n_elements(f),6)

print,'Main RUN>'

for i=0,n_elements(f)-1 do $
begin
imm=rd_int_img(f(i))
fd=f(i)
strput,fd,'tf0',strpos(fd,'tf1')
immcurr=rd_int_img(fd)

;tvscl,immcurr
if not(keyword_set(all)) then yu=takeit(imm,immcurr) else yu=takeit(imm,immcurr,/alll)
print,f(i),yu
ads(i,2:*)=yu
fd=f(i)
strput,fd,'par',strpos(fd,'tf1')
d=loadstm(fd)
ads(i,0)=d.parameters.voltageforward
ads(i,1)=d.parameters.currentforward
print,d.parameters.voltageforward
endfor

ads=ads(sort(ads(*,0)),*)
print, ads
ads=transpose(ads)
print, ads
saveu,'srac',ads

return, ads
end


function imagesequence,n,fact=fact,voltage=voltage,lst=lst
if (keyword_set(fact)) then print, 'Fine.' else fact=1 ;kvuli invertovanym obrazkum

if not(keyword_set(lst)) then f = dialog_pickfile(/read, /must_exist, /multiple_files, filter = '*.tf1') $
else $
begin
f = Content(/compress)
for i=0,n_elements(f)-1 do $
begin
fd=f(i)
strput,fd,'tf1',strpos(fd,'par')
f(i)=fd
end
end

n=370<n
n=n>20
m=n/2
ads=fltarr(n_elements(f))
ims=bytarr(n_elements(f),n,n)
imori=bytarr(n_elements(f),400,400)
print,'First cycle - Voltage reading, drift correcting>'

for i=0,n_elements(f)-1 do $
begin

iii=fact*rd_int_img(f(i))
;imori(i,*,*)=bytscl(removedrift(iii,n,/hard)) ;for Si(111)-7x7
imori(i,*,*)=bytscl(smooth(dewaveise(subtrplane(extremesexcluded(iii))),2)) ;for mosaic


iiii=reform(imori(i,*,*),400,400)
help,iiii
;tv,[tvscaled(iiii,mincolor=1),tvscaled(iii,mincolor=1)]
fd=f(i)
strput,fd,'par',strpos(fd,'tf')
d=loadstm(fd)
ads(i)=d.parameters.voltageforward

endfor

f=f(sort(ads))
imori(*,*,*)=imori(sort(ads),*,*)
ads=ads(sort(ads))


print, 'Second cycle>'
goldpalette
window, xsize=800, ysize=400

imr=intarr(400,400)
imrr=imr
for i=0,n_elements(f)-1 do $
begin
immo=imrr
imr(0:399,0:399)=imori(i,0:399,0:399)
;help,imr
;imr=extremesexcluded(superfilter(imm))
imrr=tvscaled(imr,mincolor=1)
;help,imrr
imrr(m:400-m,m)=0
imrr(m,m:-m+400)=0
imrr(m:-m+400,-m+400)=0
imrr(-m+400,m:-m+400)=0


tv,[imrr,immo]

print, 'Mark offset.'
print,'Voltage',ads(i)

xv=200
yv=200
window,1,xsize=n, ysize=n,xpos=100,ypos=100

while xv lt 400 do begin
xvd=xv
wset,0
cursor,xv,yv,/device

a=(xv lt 400-m) and (xv gt m) and (yv gt m) and (yv lt 400-m)

if a then ims(i,*,*)=(imr(xv-m:xv+m-1,yv-m:yv+m-1))
wset,1
tvscl,tvscaled((ims(i,*,*)),mincolor=1)
end

imrr(xvd,yv)=0
wset,0


endfor

print,'writing images'
s=size(ims)
window,1,xpos=400,ypos=100,xsize=s(2),ysize=s(3),retain=1
for i=0,n_elements(f)-1 do begin
print, '3f.'+strtrim(string(ads(i)),1)+'.tif'
tv,tvscaled((ims(i,*,*)),mincolor=1)
pps=strpos(string(ads(i)),'.')
print,pps
ppp=strmid(strtrim((ads(i))),pps-2,5)
print,ppp
if keyword_set(voltage) then xyouts,7,4,ppp+'V',/device,charsize=2,charthick=2, color=0
sv=tvrd(0,true=1)
;help,sv
write_tiff,'Si.'+strtrim(string(ads(i)),1)+'.tif',sv
end

return, ims
end

function lattice_vectors,im
imgf=fft(subtrplane(im))
absimgf=abs(imgf)
;imgfs=shft((absimgf*(1-fiiltrr(1800))))


;iii=bytscl((imgfs))


tvscale,shft(absimgf)
print, 'Mark two main spots in the first and second quadrant!'

cursor,e1,e2,/up,/device

cursor,f1,f2,/up,/device
return,[[e1-200.,e2-200.],[f1-200.,f2-200.]]
end

function hex_vect,x
x=float(x)
zxp1=(x(1,0)^2+x(0,0)^2)^0.5
zxp2=(x(1,1)^2+x(0,1)^2)^0.5

x(1,0)=!PI*200./zxp1*x(1,0)/zxp1

x(0,0)=!PI*200./zxp1*x(0,0)/zxp1

x(0,1)=!PI*200./zxp2*x(0,1)/zxp2

x(1,1)=!PI*200./zxp2*x(1,1)/zxp2

xp=[[-x(1,0),x(0,0)],[-x(1,1),x(0,1)],[-x(1,1)+x(1,0),x(0,1)-x(0,0)]]
xpp=[[xp],[-xp],[0,0]]
print,xpp
print,'------'
return,xpp
end


function lattice_vectors_2,im



s=size(im)
tvscale,congrid(subtrplane(im),s(1)*2,s(2)*2)
print, 'Mark the middle!'

cursor,e1,e2,/up,/device

print, 'Mark the upper lattice vector!'

cursor,f1,f2,/up,/device

print, 'Mark the lower lattice vector!

cursor,g1,g2,/up,/device

e1=e1/2
f1=f1/2
g1=g1/2
e2=e2/2
f2=f2/2
g2=g2/2


return,[[f1-e1,f2-e2],[g1-e1,g2-e2]]
end

function hex_vect_2,x
x=float(x)


xp=[[x(0,0),x(1,0)],[x(0,1),x(1,1)],[x(0,1)-x(0,0),x(1,1)-x(1,0)]]
xpp=[[xp],[-xp],[0,0]]
print,xpp
return,xpp
end


function cross_corr,f,g
ff=fft(f,-1)
fg=fft(g,-1)
return,fft(f*conj(g),1)
end

function circl,xs,ys,xc,yc,r
ghj=bytarr(xs,ys)

for i=xc-r,xc+r do $

for j=yc-r,yc+r do $
begin
if ((i-xc)^2+(j-yc)^2) le r^2 then ghj(i,j)=1
end

return,ghj
end

function give_masks,v,r

vs=size(v)
rdd=r

rdd=byte(2.*rdd)

masks=bytarr(rdd,rdd,vs(2))
for i=0,vs(2)-1 do $
begin
masks(*,*,i)=circl(rdd,rdd,rdd/2+v(0,i),rdd/2+v(1,i),round(r/5.))
end



return,masks
end

function cb,vect
u=1
vysl=0
for i=0,n_elements(vect)-1<7 do begin 
u=u*2 
vysl=vysl+vect(i)*u
end
return,vysl
end

function place,ar,x,y,xs,ys ;osetrit!
arr=intarr(xs,ys)
sz=size(ar)
arr(x-sz(1)/2:x-sz(1)/2+sz(1)-1,y-sz(2)/2:y-sz(2)/2+sz(2)-1)=ar(0:*,0:*)
return,arr
end

function sort_by_shape,c
h=intarr(13)

c_bin=cb(c)
case total(c) of
0:h(0)=1
1:h(1)=1
2:case c_bin of
    cb([1,0,0,1,0,0]):h(2)=1
    cb([0,1,0,0,1,0]):h(2)=1
    cb([0,0,1,0,0,1]):h(2)=1
    cb([1,1,0,0,0,0]):h(3)=1
    cb([0,1,1,0,0,0]):h(3)=1
    cb([0,0,1,1,0,0]):h(3)=1
    cb([0,0,0,1,1,0]):h(3)=1
    cb([0,0,0,0,1,1]):h(3)=1
    cb([1,0,0,0,0,1]):h(3)=1
    cb([1,0,1,0,0,0]):h(4)=1    
    cb([0,1,0,1,0,0]):h(4)=1    
    cb([0,0,1,0,1,0]):h(4)=1    
    cb([0,0,0,1,0,1]):h(4)=1
    cb([1,0,0,0,1,0]):h(4)=1    
    cb([0,1,0,0,0,1]):h(4)=1
    endcase
3:case c_bin of
    cb([0,1,0,1,0,1]):h(5)=1
    cb([1,0,1,0,1,0]):h(5)=1
    cb([1,1,1,0,0,0]):h(6)=1
    cb([0,1,1,1,0,0]):h(6)=1
    cb([0,0,1,1,1,0]):h(6)=1
    cb([0,0,0,1,1,1]):h(6)=1
    cb([1,0,0,0,1,1]):h(6)=1
    cb([1,1,0,0,0,1]):h(6)=1
    
    cb([1,0,1,1,0,0]):h(7)=1
    cb([0,1,0,1,1,0]):h(7)=1
    cb([0,0,1,0,1,1]):h(7)=1
    cb([1,0,0,1,0,1]):h(7)=1
    cb([1,1,0,0,1,0]):h(7)=1
    cb([0,1,1,0,0,1]):h(7)=1
    
    cb([1,1,0,1,0,0]):h(7)=1
    cb([0,1,1,0,1,0]):h(7)=1
    cb([0,0,1,1,0,1]):h(7)=1
    cb([1,0,0,1,1,0]):h(7)=1
    cb([0,1,0,0,1,1]):h(7)=1
    cb([1,0,1,0,0,1]):h(7)=1
        
    endcase
4:case c_bin of
    cb([1,1,0,0,1,1]):h(8)=1
    cb([1,1,1,0,0,1]):h(8)=1
    cb([1,1,1,1,0,0]):h(8)=1
    cb([0,1,1,1,1,0]):h(8)=1
    cb([0,0,1,1,1,1]):h(8)=1
    cb([1,0,0,1,1,1]):h(8)=1
    
    cb([1,1,0,1,1,0]):h(9)=1
    cb([0,1,1,0,1,1]):h(9)=1
    cb([1,0,1,1,0,1]):h(9)=1
    
    cb([0,1,0,1,1,1]):h(10)=1
    cb([1,0,1,0,1,1]):h(10)=1
    cb([1,1,0,1,0,1]):h(10)=1
    cb([1,1,1,0,1,0]):h(10)=1
    cb([0,1,1,1,0,1]):h(10)=1
    cb([1,0,1,1,1,0]):h(10)=1
    endcase
5:h(11)=1
6:h(12)=1
endcase
return,h
end

function mosaic_statistics,img,dis=dis,wdth=wdth,lmx=lmx,inv=inv

f='generic.tf0'
if not(keyword_set(img)) then begin

f=dialog_pickfile(/read, /must_exist, filter = '*')
if (f eq "") then return,0 
img=rd_int_img(f)
end

fd=f

fdt=f
fdt2=f
strput,fd,'.tif',strpos(fd,'.t')
strput,fdt,'.inf',strpos(fdt,'.t')
strput,fdt2,'.res',strpos(fdt2,'.t')
print,fd
print, fdt
print,fdt2



if keyword_set(inv) then img=-img
s=size(img)
print,s
img=subtrplane(img)
goldpalette
window,1,xpos=200,ypos=50,xsize=s(1)*2,ysize=s(2)*2

if keyword_set(byfft) then begin
x=lattice_vectors(img)
print,x
y=hex_vect(x)
end else begin
x=lattice_vectors_2(img)
print,x
ss=abs(x(0,0)*x(1,1)-x(0,1)*x(1,0))
y=float(hex_vect_2(x))
end


;tvscale,congrid(img,s(1)*2,s(2)*2),mincolor=1

plots,(y(0,*)+210)*2,(y(1,*)+190)*2,/device,color=0



rdius=(((y(0,0)^2+y(1,0)^2)^0.5+(y(0,1)^2+y(1,1)^2)^0.5))
print,'radius:',rdius

msk=give_masks(y,rdius)
tvscl,msk(*,*,0)+msk(*,*,1)+msk(*,*,2)+msk(*,*,3)+msk(*,*,4)+msk(*,*,5)

print,'search for atoms..'
img5=img
if (rdius/4 lt 3) then print,"Wow, such small atoms! That'll be tough.." else img5=boxcarfilter(img,width=rdius/4) 
if keyword_set(wdth) then begin 
print,'Overiding the automatic smoothing width!'
img5=boxcarfilter(img,width=wdth) 
end

help,img5
if keyword_set(lmx) then img5l=lmax(img5,round(lmx)) else img5l=lmax(img5,3)


if not(keyword_set(dis)) then dis=29
img5ld=discr(img5l,dis)/255
img5ldf=fft(img5ld,-1)
print,'creating autocorrelations..'
imgf=fft(img)
imgfc=fft(imgf*conj(imgf),1)
aimg5ldf=fft(imgf*conj(img5ldf),1) ;korelace pozic Pb atomu s celym obr. 

t=img5ld

tw=t
tw(0:rdius+1,*)=0
tw(*,0:rdius+1)=0
tw(s(1)-rdius-1:*,*)=0
tw(*,s(2)-rdius-1:*)=0

tvscl,congrid((1-t)*tvscaled(img5, mincolor=1),2*s(1),2*s(2))
tt=where(tw)


print,'Sorting by neighbours..'
resulimg=t*0
resul=intarr(13)
counter=0
for tti=0,n_elements(tt)-1 do $
begin
sracx=place(msk(*,*,6),tt(tti) mod s(1),tt(tti)/s(2),s(1),s(2))
if total(sracx*t) gt 1 then $
print, tti,':','This point is shit, removing..' $

else $

begin
    c=intarr(6)
    for p=0,5 do $
	begin
	srac=place(msk(*,*,p),tt(tti) mod s(1),tt(tti)/s(2),s(1),s(2))
    
	;tvscl,srac+t
	;wait,0.5
	c(p)=total(srac*t)
	if (c(p) gt 1) then c(p)=1
	end
    print,tti,':',c
    sor=sort_by_shape(c)
    gh=where(sor)
    print,gh
    resulimg(tt(tti))=gh(0)
    
    resul=resul+sor
    xyouts,2*(tt(tti) mod s(1)),2*(tt(tti)/s(2)),strtrim(gh,2),color=0,/device
    counter=counter+1
    end
end

ad=tvrd(0,true=1)
write_tiff,fd,ad

print,'Expected no. of lattice points:', (s(1)-2*(rdius+1))*(s(2)-2*(rdius+1))/float(ss) 
print,'Total points in the discretised image:',n_elements(tt)
print,'Sane points:',counter
print,'result',resul
print,'percentage result:',100*float(resul)/counter
print,'coverage:',float(counter)/((s(1)-2*(rdius+1))*(s(2)-2*(rdius+1))/float(ss))

openw,5,fdt
printf,5,'File:',f
printf,5,'Image size:',s(1),'x', s(2)
printf,5,'Expected no. of lattice points:', (s(1)-2*(rdius+1))*(s(2)-2*(rdius+1))/float(ss) 
printf,5,'Total points in the discretised image:',n_elements(tt)
printf,5,'Sane points:',counter
printf,5,'result',resul
printf,5,'percentage result:',100*float(resul)/counter
printf,5,'radius',rdius
printf,5,'vectors',x
printf,5,'coverage:',float(counter)/((s(1)-2*(rdius+1))*(s(2)-2*(rdius+1))/float(ss)) 

close,5


saveu,fdt2,resulimg,/nonfo

return,resulimg
end

