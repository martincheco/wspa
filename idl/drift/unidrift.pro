function repair_points,y
;tries to move the points in the appropriate quadrants
;print,y
if real_part(y(0)) lt 0 then y(0)=-y(0)
if real_part(y(1)) lt 0 then y(1)=-y(1)
if imaginary(y(0)) lt imaginary((1)) then begin
y=reverse(y)
end
;print,y
return,y
end

function ttrans,yf,yif,p,q ; gets the transformation matrix

y1x=float(yf(0))
y1y=imaginary(yf(0))

y2x=float(yf(1))
y2y=imaginary(yf(1))

i1x=float(yif(0))
i1y=imaginary(yif(0))

i2x=float(yif(1))
i2y=imaginary(yif(1))

b=(q*y1x-p*y1y)/(y2y*y1x-y2x*y1y)

a=(p-y2x*b)/y1x

m=a*yif(0)+b*yif(1)

return,m
end


function userpoints,im,zm=zm,target_self=target_self
;zm defines the zoom
if not(keyword_set(zm)) then zm=8. else zm=(zm>2.)<16.
zom=1
device,retain=2
s=size(im)
xdim=s(1)
ydim=s(2)
;print,s
if not(keyword_set(target_self)) then begin
    window,/FREE,xs=s(1),ys=s(2),title="Select unit cell.."
    goldpalette,/pure
end

wno=!D.window
;goldpalette,/pure
tvscl,(im)

cursortest:
    cursor,x1,y1,/down,/device
    ;print,!mouse.button
    if !mouse.button eq 4 and x1 lt xdim-1 and y1 lt ydim-1 and x1 gt 0 and y1 gt 0 then begin
	if zom ne 1 then begin
	    zom=1
	    tvscl,(im)
	    goto,cursortest
	end $
	else begin
	    x1=(x1>(xdim/zm))<((zm-1)*xdim/zm-1)
	    y1=(y1>(ydim/zm))<((zm-1)*ydim/zm-1)
	    tvscl,congrid(im(x1-xdim/zm:x1+xdim/zm,y1-ydim/zm:y1+ydim/zm),xdim,ydim,cubic=-0.7)
	    ;print,"Coordinates:",x1,y1
	    zom=zm
	    xc=x1 ; centre
	    yc=y1
	    goto,cursortest
	end
    end

    device,set_graphics_function = 6; XOR graphics
    mbd=!mouse.button
    x2d=x1
    y2d=y1
    mb=mbd

    ;the axes
    plots,[0,s(1)],[y1,y1],/device,color=255
    plots,[x1,x1],[0,s(2)],/device,color=255
    
    repeat begin
	cursor,x2,y2,/change,/device
	if x2d ne x2 or y2d ne y2 then begin
	    plots,[2*x1-x2d,x2d],[2*y1-y2d,y2d],/device,color=255
	    plots,[2*x1-x2,x2],[2*y1-y2,y2],/device,color=255
	    x2d=x2
	    y2d=y2    
	end
	
	mb=!mouse.button
	if mb ne mbd then $
	if mbd eq 0 and mb eq 1 then begin
	    mb=99 ;exit code
	end else begin
	    mbd=mb
	end
	
    endrep until mb eq 99

    x2d=x1
    y2d=y1
    mb=mbd
    mbd=!mouse.button
    repeat begin
	cursor,x3,y3,/change,/device
	if x2d ne x3 or y2d ne y3 then begin
	    plots,[2*x1-x2d,x2d],[2*y1-y2d,y2d],/device,color=255
	    plots,[2*x1-x3,x3],[2*y1-y3,y3],/device,color=255
	    x2d=x3
	    y2d=y3    
	end
	
	mb=!mouse.button
	if mb ne mbd then $
	if mbd eq 0 and mb eq 1 then begin
	    mb=99 ;exit code
	end else begin
	    mbd=mb
	end
	
    endrep until mb eq 99



;plots,[x1,x2],[y1,y2],/device   

device, set_graphics_function = 3; copy graphics

if not(keyword_set(target_self)) then wdelete,wno

a=complex(x2-x1,y2-y1)
b=complex(x3-x1,y3-y1)





;print,zom
return,[a,b]/zom
end



function inventpoints,y,matrix,orient=orient
;fixes the triangle
a=y(0)
b=y(1)
;the point of crossing (x)
a1=float(a)
a2=imaginary(a)
b1=float(b)
b2=imaginary(b)
k=a2/(a2-b2)
x=a1-k*(a1-b1)
;x=complex(x,0)
;the ratio between the arms
alpha=abs(a-x)/abs(a-b)
;help,alpha

;get the vectors from matrix and find the crossing point
a0=complex(matrix(0,0),matrix(1,0))
b0=complex(matrix(0,1),matrix(1,1))
;print,a0
;print,b0
x0=(b0-a0)*alpha+a0
x0angle=x0/abs(x0) ;the angle for rotation
;print,x0angle
;rotate and expand so that x0 aligns with x
;if orient is set, only expand
;help,x

anew=(a0/x0angle)*(x/abs(x0))
bnew=(b0/x0angle)*(x/abs(x0))

if keyword_set(orient) then begin
;works a bit weird
anew=a0*x/abs(x0)
bnew=b0*x/abs(x0)
end

return,[anew,bnew]
end

function unidrift,imf,matrix,n=n,orient=orient,recut=recut,drift=drift,target_self=target_self,points=points
;removes drift by asking the user for the axes and uses the X axis as the most reliable
;imf - the image
;matrix - the periodicity vectors
;n - expansion of the canvas; max. expansion 2x
;orient - the angle between the first vector and the X axis in degrees in the result, if not set, no correction done
;the same could be achieved with warp_tri though
;if drift is set, wps is calculated and then warped directly, if the variable is empty, returns the right values
;recut removes automatically empty spacing around
;target_self uses an already created window (if its badly sized, maybe does not matter)
;points directly specify what is otherwise obtained by interactive window, skip any imaging events, 

if isgdl() then begin
    ;print,'resorting to unidrift without warp_tri'
    imm=unidrift_gdl(imf,matrix,drift=drift,target_self=target_self,points=points)
    return,imm
end

im=imf ;make a copy
s=size(im)

r3=3.^0.5/2.

if not(keyword_set(matrix)) then begin
;print,"No matrix given, using the hexagonal symmetry"
matrix=[[r3,0.5],[r3,-0.5]]
end


if not(keyword_set(drift)) or n_elements(drift) ne 2 then begin 
    ;vectors: real part x, imaginary is y, have to be one above the X axis, second below; otherwise you get nonsense
    if keyword_set(points) then y=points else y=userpoints(im,target_self=target_self)
    y=repair_points(y)
    ;print,y

    ;define the correct vectors, needs to be calculated
    if keyword_set(orient) then $
	yi=inventpoints(y,matrix,/orient) else yi=inventpoints(y,matrix)
end

if not(keyword_set(n)) then begin
    n=2.0
    im=filter(im,{type:["stuff"],par1:[n]})
end else $
begin
    ;limit the expansion
    n=n<2.0
    ;expand the borders of the image
    im=filter(im,{type:["stuff"],par1:[n]})
end

;help,n
;help,im

gx=[0.,s(1)*n,0.,s(1)*n]
gy=[0.,0.,s(2)*n,s(2)*n]

if (n_elements(drift) eq 2) then $
    begin
	gix=[0.,s(1)*n,drift(0)*n,(s(1)+drift(0))*n]
	giy=[0.,0.,(s(2)+drift(1))*n,(s(2)+drift(1))*n]
    end $
    else $
    begin
	ggg=ttrans(y,yi,gx,gy)
	;returns the coordinates of the new image corners
	gix=float(ggg)
	giy=float(imaginary(ggg))
	drift=[gix(2)/n,giy(2)/n-s(2)]
    end


;print,ggg



;need to be centered ...? check it then

gix=gix-mean(gix)+n*s(1)/2
giy=giy-mean(giy)+n*s(2)/2 

gixh=(gix-mean(gix))/2+n*s(1)/2
giyh=(giy-mean(giy))/2+n*s(2)/2 



imm=warp_tri(gix,giy,gx,gy,im); no filtering
;imm=skew(im,drift(0),drift(1)); temporary replacement for gdl


;print,gixh
;print,giyh

;recut
xmn=min(gixh)>0
xmx=max(gixh)<(n*s(1)-1)
ymn=min(giyh)>0
ymx=max(giyh)<(n*s(2)-1)


;print,xmn,xmx,ymn,ymx
;help,imm

if keyword_set(recut) then imm=imm(xmn:xmx,ymn:ymx)
;imm=zooom(imm,1./n)


;obsolete
;if keyword_set(wps) then begin 
;wps=[[gix],[giy],[gx],[gy]] ;after the check test if division by n successful
;print,"passed"
;print,wps
;end

return,imm
end