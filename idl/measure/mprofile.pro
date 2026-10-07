function is_out,v,xs,ys

if v(0) lt 0 or v(0) gt xs then return,-1
if v(1) lt 0 or v(1) gt xs then return,-1
if v(2) lt 0 or v(2) gt ys then return,-1
if v(3) lt 0 or v(3) gt ys then return,-1
return,1
end




function i_draw_line,mark=mark,markimg=markimg
;lets the user drag a line inside the actual win
;mark leaves the line in the window
    cursor,x1,y1,/down,/device
    device, set_graphics_function = 6; XOR graphics
    mbd=!mouse.button
    plots,[x1,x1],[y1,y1],/device,color=255
    x2d=x1
    y2d=y1
    mb=mbd
    repeat begin
	cursor,x2,y2,/change,/device
	if x2d ne x2 or y2d ne y2 then begin
	    plots,[x1,x2d],[y1,y2d],/device,color=255
	    plots,[x1,x2],[y1,y2],/device,color=255
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

    cursor,x2,y2,/change,/device

if not(keyword_set(mark)) then plots,[x1,x2d],[y1,y2d],/device,color=255

    device, set_graphics_function = 3; copy graphics

return,[x1,x2d,y1,y2d]
end


function mprofile, img, x1, x2, y1, y2, manual=manual,latscl=latscl,mark=mark,offset=offset,markimg=markimg ;makes a profile of image
;latscl (means the real lateral scale of X dimension of img) allows recalibrating the output to physical coordinates [nm] [A] etc. and returns a structure
;specfies the img width in phys. coords
;manual tells that it should be marked manually
;offset puts the first point az zero
;markimg is image for marking the profile

if not(keyword_set(mark)) then mark=0


if keyword_set(manual) then begin
    coords=i_draw_line(mark=mark)
    x1=coords(0)
    x2=coords(1)
    y1=coords(2)
    y2=coords(3)
end

x1=long(x1)
x2=long(x2)
y1=long(y1)
y2=long(y2)

aa=complex(x2-x1,y2-y1)
a0=complex(1,0)
angle=imaginary(alog((aa/abs(aa))/a0))/!PI*180.

s=size(img)
if keyword_set(latscl) then pfl={z:0,x:0,y:0,r:0,angle:0} else pfl=-1
if is_out([x1,x2,y1,y2],s(1),s(2)) eq -1 then begin
    return,pfl  
end

ef=round(((x2-x1)^2+(y2-y1)^2)^0.5)   ;expansion factor

if x1 ne x2 or y1 ne y2 and keyword_set(img) then begin
    s=size(img)
   
     if abs(x2-x1) gt abs(y2-y1) then begin
       ;print,'x rulez'
       sg=sgn(x2-x1)
       pfl=dblarr(abs(x2-x1)+1)
       x=pfl
       y=pfl
       for i=x1,x2,sg do begin
;       print,'offset',i-x1
       pfl(abs(i-x1))=img(i,(i-x1)*(y2-y1)/(x2-x1)+y1)
       x(abs(i-x1))=double((i-x1))
       y(abs(i-x1))=double((i-x1)*(y2-y1)/(x2-x1))
       end 
     end else begin
       ;print, 'y rulez'
       sg=sgn(y2-y1)
       pfl=dblarr(abs(y2-y1)+1)
	x=pfl
	y=pfl
       for i=y1,y2,sg do begin
;       print,'offset',i-y1
	pfl(abs(i-y1))=img((i-y1)*(x2-x1)/(y2-y1)+x1,i)
        x(abs(i-y1))=double((i-y1)*(x2-x1)/(y2-y1))
        y(abs(i-y1))=double((i-y1))
       end 
     end       
   
   
 ;  end

    if keyword_set(offset) then pfl=pfl-pfl(0)
    if keyword_set(markimg) then begin
    mxmarkimg=max(markimg)
    ;	markimg(x,(y-1)>0)=0
    ;	markimg((x-1)>0,y)=0
    ;	markimg((x+1)<(s(1)-1),y)=0
    ;	markimg(x,(y+1)<(s(2)-1))=0
    	markimg(x+x1,y+y1)=mxmarkimg
    end
    if keyword_set(latscl) then begin
	    scl=double(latscl)/s(1)
	    return, {z:pfl,x:scl*x,y:scl*y,r:scl*((x^2+y^2)^0.5),angle:angle}
    end else $
	    return, congrid(pfl,ef)

end else if keyword_set(latscl) then return, {z:0,x:0,y:0,r:0,angle:0} else return,-1

end

