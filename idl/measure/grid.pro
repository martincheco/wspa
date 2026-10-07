function vector,indexes,a,b
aa=a*real_part(indexes)+b*imaginary(indexes)
return,aa
end


function grid,img,x0,y0,x1,y1,x2,y2,dim=dim,cart=cart,target_self=target_self,patt=patt,unrel=unrel,col=col
;overlays the image with a grid specified by offset(x0,y0) and vectors(x1,y1,x2,y2)
;dim is the number of cells to be drawn
;cart specifies that x1,y1,x2,y2 are in cartesian instead of radial coords r1,a1,r2,a2
;patt is a pattern to plot
;unrel switches off relation of pattern to grid
;col color


i=complex(0.,1.)

device,decomposed=0
if not(keyword_set(col)) then col1=255 else col1=(col>0)<255

radiusz=abs(x1*x2)^0.5

if not(keyword_set(dim)) then dim=10
if not(keyword_set(cart)) then begin
    
    m=x1*exp(i*y1*!PI/180.)
    x1=real_part(m)
    y1=imaginary(m)
    n=x2*exp(i*y2*!PI/180.)
    x2=real_part(n)
    y2=imaginary(n)
end

s=size(img)
;sz=size(img)
print,s

if not(keyword_set(target_self)) then begin
    if s(1) eq 3 then window,/FREE,xs=s(2),ys=s(3) $
	else window,/FREE,xs=s(1),ys=s(2)
    wno=!D.WINDOW
end

if s(1) eq 3 then tv,img,true=1 else tvscl,img

ix=lindgen((dim*2)^2)
ii=ix / (2*dim)
jj=ix mod (2*dim)
ii=ii-dim
jj=jj-dim


if not(keyword_set(patt)) then patt=[complex(0.,1.),complex(0.,0.),complex(1.,0.)] else $
    if n_elements(patt) eq 1 then $
    if patt(0) lt 2 then patt=[complex(0.33,0.33),complex(0.66,-0.33),complex(0.33,-0.66),complex(-0.33,-0.33)] else $
    begin
	unrel=1
	rd=patt(0)>2
	inc=!PI/rd
	patt=complexarr(2*rd+1)
	for phi=0,rd*2 do patt(phi)=rd*exp(-complex(0.,1.)*phi*inc)
    end
print,patt

n=n_elements(patt)
va=complexarr(n)

v=vector(complex(ii,jj),complex(x1,y1),complex(x2,y2))+complex(x0,y0)
if keyword_set(unrel) then cpatt=patt else cpatt=vector(patt,complex(x1,y1),complex(x2,y2))

;device, set_graphics_function = 6; XOR graphics

for c=0L,n_elements(v)-1 do begin

    for j=0,n-2 do begin
    
	a=real_part(v(c))
	a=[a+real_part(cpatt(j)),a+real_part(cpatt(j+1))]
	b=imaginary(v(c))
	b=[b+imaginary(cpatt(j)),b+imaginary(cpatt(j+1))]
	plots,a,b,color=col1,/device
    
    
    
    end
end

plots,x0,y0,psym=6,/device

;device, set_graphics_function = 3; XOR graphics


imf=tvrd(0,true=1)
if not(keyword_set(target_self)) then close,wno
return,imf
end


function grid_ps,img,x0,y0,x1,y1,x2,y2,dim=dim,cart=cart,patt=patt,unrel=unrel
;modified for poscript output, asks for a filename, returns zero
;overlays the image with a grid specified by offset(x0,y0) and vectors(x1,y1,x2,y2)
;dim is the number of cells to be drawn
;cart specifies that x1,y1,x2,y2 are in cartesian instead of radial coords r1,a1,r2,a2
;patt is a pattern to plot
;unrel switches off relation of pattern to grid


i=complex(0.,1.)

col1=255

radiusz=abs(x1*x2)^0.5

if not(keyword_set(dim)) then dim=10
if not(keyword_set(cart)) then begin
    
    m=x1*exp(i*y1*!PI/180.)
    x1=real_part(m)
    y1=imaginary(m)
    n=x2*exp(i*y2*!PI/180.)
    x2=real_part(n)
    y2=imaginary(n)
end

s=size(img)
;sz=size(img)
print,s
if s(1) eq 3 then begin 
	xsz=s(2)
	ysz=s(3)
end else begin
	xsz=s(1)
	ysz=s(2)
end

pst=10000./s(1)
help,pst

SET_PLOT, 'PS'

DEVICE, /ENCAPSULATED, /color,BITS_PER_PIXEL=8,FILENAME = dialog_pickfile(title='PS file'),xsize=10,ysize=ysz*10/xsz
if s(1) eq 3 then tv,img,true=1 else tvscl,img
!P.THICK=0.5
ix=lindgen((dim*2)^2)
ii=ix / (2*dim)
jj=ix mod (2*dim)
ii=ii-dim
jj=jj-dim


if not(keyword_set(patt)) then patt=[complex(0.,1.),complex(0.,0.),complex(1.,0.)] else $
    if n_elements(patt) eq 1 then begin
	unrel=1
	rd=patt(0)>2
	inc=!PI/rd
	patt=complexarr(2*rd+1)
	for phi=0,rd*2 do patt(phi)=rd*exp(-complex(0.,1.)*phi*inc)
    end
print,patt

n=n_elements(patt)
va=complexarr(n)

v=vector(complex(ii,jj),complex(x1,y1),complex(x2,y2))+complex(x0,y0)
if keyword_set(unrel) then cpatt=patt else cpatt=vector(patt,complex(x1,y1),complex(x2,y2))

;device, set_graphics_function = 6; XOR graphics

for c=0L,n_elements(v)-1 do begin

    for j=0,n-2 do begin
    
	a=real_part(v(c))
	a=[a+real_part(cpatt(j)),a+real_part(cpatt(j+1))]
	b=imaginary(v(c))
	b=[b+imaginary(cpatt(j)),b+imaginary(cpatt(j+1))]
	plots,pst*a,pst*b,color=col1,/device
    
    
    
    end
end

plots,pst*x0,pst*y0,psym=6,/device,symsize=1./pst,color=255

;device, set_graphics_function = 3; XOR graphics
device,/close
set_plot,'X'
return,0
end


function grid_product,img,par,dim=dim,draw=draw
;returns a total product of grid and img


x0=par(0)
y0=par(1)
x1=par(2)
y1=par(3)
x2=par(4)
y2=par(5)

;print,x0,y0,x1,y1,x2,y2

i=complex(0.,1.)

col1=255

radiusz=abs(x1*x2)^0.5

if not(keyword_set(dim)) then dim=10

s=size(img)

ix=lindgen((dim*2)^2)
ii=ix / (2*dim)
jj=ix mod (2*dim)
ii=ii-dim
jj=jj-dim

v=vector(complex(ii,jj),complex(x1,y1),complex(x2,y2))+complex(x0,y0)

;device, set_graphics_function = 6; XOR graphics
a=real_part(v)
b=imaginary(v)

w=where(a gt 0 and a lt s(1) and b gt 0 or b lt s(2))

;plots,a,b,psym=4,/device


if w(0) ne -1 then v=v(w) else return,0
a=real_part(v)
b=imaginary(v)

if keyword_set(draw) then begin
tvscl,img
plots,a,b,psym=3,/device
plots,x0,y0,psym=4,/device
end

return,mean(img(a,b))
end

pro grid_fit,img
lim=100000
a=[298.,282.,15.,8.,15.,-8.]

t=grid_product(img,a,dim=50)
print,t
cc=0
drw=1

repeat begin
cc=cc+1
;coef=randomu(seed,1)
da=randomn(seed,6)/2.
da(0:1)=a(0:1)
;da(3)=da(3)/10.
;da(5)=da(5)/10.


anew=a+da
;print,anew
tnew=grid_product(img,anew,dim=50,draw=drw)
drw=0
;print,tnew

if tnew lt t then begin
	print,a
	print,anew
	print,t
	a=anew
	t=tnew
	print,t
	print,cc
	cc=0
	drw=1
end

endrep until cc gt lim

end