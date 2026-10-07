function vector,indexes,a,b
aa=a*real_part(indexes)+b*imaginary(indexes)
return,aa
end


function grids,img,x0,y0,x1,y1,x2,y2,dim=dim,cart=cart,patt=patt,unrel=unrel,center=center,autocol=autocol,circ=circ,scl=scl,cross=cross,dots=dots,pimg=pimg,mask=mask
;returns a grid specified by offset(x0,y0) and vectors(x1,y1,x2,y2)
;dim is the number of cells to be drawn
;cart specifies that x1,y1,x2,y2 are in cartesian instead of radial coords r1,a1,r2,a2
;patt is a pattern to plot
;unrel switches off relation of pattern to grid
;autocol autocolor(rotate spectrum by half)
;pimg image to convolve
;msk returns only mask
;scal is scale of the unrelated vector pattern


if keyword_set(cross) then patt=[complex(-1.,0.),complex(1.,0.),complex(0.,0.),complex(0,1.),complex(0,-1.)]

if keyword_set(circ) then begin
	f=findgen(33)/16.*!PI
	patt=[complex(cos(f),sin(f))]
end

if keyword_set(pimg) then begin
	dots=1
end

;imgn=img*0

i=complex(0.,1.)

device,decomposed=0
col1=255

;radiusz=abs(x1*x2)^0.5

if not(keyword_set(dim)) then dim=10
if not(keyword_set(cart)) then begin
    
    m=x1*exp(i*y1*!PI/180.)
    x1=real_part(m)
    y1=imaginary(m)
    n=x2*exp(i*y2*!PI/180.)
    x2=real_part(n)
    y2=imaginary(n)
end


if not(keyword_set(scl)) then scl=(abs(complex(x1,y1))*abs(complex(x2,y2)))^0.5/2.05


s=size(img)
;sz=size(img)
print,s

if keyword_set(center) then begin
	x0=x0+s(1)/2
	y0=y0+s(2)/2
end

ix=lindgen((dim*2)^2)
ii=ix / (2*dim)
jj=ix mod (2*dim)
ii=ii-dim
jj=jj-dim


if not(keyword_set(patt)) then patt=[complex(0.,1.),complex(0.,0.),complex(1.,0.)]

n=n_elements(patt)
va=complexarr(n)

v=vector(complex(ii,jj),complex(x1,y1),complex(x2,y2))+complex(x0,y0)
if keyword_set(unrel) then cpatt=patt*scl else cpatt=vector(patt,complex(x1,y1),complex(x2,y2))

;device, set_graphics_function = 6; XOR graphics
msk=img*0

vx=real_part(v)
vy=imaginary(v)
if keyword_set(dots) then begin
	ww=where(vx ge 0 and vx le s(1) and vy ge 0 and vy le s(2))
	if keyword_set(pimg) then begin
		msk(vx(ww),vy(ww))=col1
		msk=convol(msk,bytscl(pimg),/center)
		msk=bytscl(msk)
	end else  msk(vx(ww),vy(ww))=col1
end else $
for c=0L,n_elements(v)-1 do begin

    for j=0,n-2 do begin
    
	a=real_part(v(c))
	a=[a+real_part(cpatt(j)),a+real_part(cpatt(j+1))]
	b=imaginary(v(c))
	b=[b+imaginary(cpatt(j)),b+imaginary(cpatt(j+1))]
	;plots,a,b,color=col1,/device
	msk=drwline(msk,a[0]+1,b[0]+1,a[1]+1,b[1]+1,col=col1)
    end
end

;f keyword_set(dots) then begin
;w=where(imgn eq col1)
;imgg=img
;imgg(w)=((imgg(w)/2+196)) mod 255
;end
if keyword_set(mask) then return,msk

if keyword_set(autocol) then begin
	;w=where(msk ne 0)
	imgg=bytscl(4.*bytscl(img)+bytscl(msk))
;	imgg(w)=bytscl(imgg(w))/2+bytscl(msk(w))/2
end

if not(keyword_set(autocol)) then begin
	w=where(msk gt 0.)
	imgg=img
	imgg(w)=msk(w)
end
return,imgg
end
