function skew,img,a,b
;produces a skewed image from array
;replacement for a warp_tri which is not supported in gdl at this moment
;a,b define a vector of movement for the upper right corner

b=b
absa=abs(round(a))<1000

s=size(img)

x=(s(1))
y=(s(2))


;safe limits

nx=((x+absa))
ny=((abs(y+b))>20)<2000
;help,nx
;help,ny
;help,img


imgt=congrid(img,x,ny,/interp)
;help,imgt
imgn=replicate(img(0),nx,ny)
;help,imgn
xincr=double(absa)/double(ny)
;help,imgn

if a ge 0 then $
    for i=0,ny-1 do begin
        line=imgt(*,i)
        k=xincr*double(i)
;	print,k,k+x-1,x-1
	ofs=(x-1)
;	print,k,ofs,x-1
;	print,ofs
;	help,imgn(k:k+ofs,i)

	imgn(k:ofs,i)=line(0:x-1)
    end $
else $
    for i=0,ny-1 do begin
        line=imgt(*,i)
        k=(xincr*double(i))
	ofs=round(double(absa)-k)
	imgn(ofs:ofs+x-1D,i)=line(0:x-1D)
    end


return,imgn
end
