function drwline, img, x1, y1, x2, y2,col=col
;draws a line into the image as fast as possible
;col specifies a hard color to draw the line


if not(keyword_set(col)) then col=255

x1=long(x1)
x2=long(x2)
y1=long(y1)
y2=long(y2)


s=size(img)
imgn=img

     if abs(x2-x1) gt abs(y2-y1) then begin
;       print,'x rulez'
       x=sgn(x2-x1)*lindgen(abs(x2-x1)>1)
       y=x
       y=long(x*double(y2-y1)/(x2-x1))
	y=y+y1
	x=x+x1
     end else begin
;       print, 'y rulez'
        y=sgn(y2-y1)*lindgen(abs(y2-y1)>1)
        x=y
	x=long(y*double(x2-x1)/(y2-y1))
	x=x+x1
	y=y+y1

     end       

imgn((x>0)<s(1)-1,(y>0)<s(2)-1)=col
return,imgn
end

