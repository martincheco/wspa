function add2,xx1,yy1,xx2,yy2,subtract=subtract
x1=double(reform(xx1))
y1=double(reform(yy1))
y2=double(reform(yy2))
x2=double(reform(xx2))

;sorting
s1=sort(x1)
s2=sort(x2)

x1=x1(s1)
y1=y1(s1)
x2=x2(s2)
y2=y2(s2)

;searching for the overlap
mnx=max([min(x1),min(x2)])
mxx=min([max(x1),max(x2)])

;step
xdx1=(x1-shift(x1,1))
xdx2=(x1-shift(x1,1))
dx1=min(xdx1(1:*))
dx2=min(xdx2(1:*))
help,dx1
help,dx2
dx=min([dx1,dx2])
;no of points
nn=double(mxx-mnx)/dx

;new x vector
x=(mxx-mnx)*dindgen(nn)/nn+mnx

;resampling using the new x vector
y1n=interpol(y1,x1,x)
y2n=interpol(y2,x2,x)

if keyword_set(subtract) then y=y1n-y2n else y=y1n+y2n

return,{x:x,y:y}
end
