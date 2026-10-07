function mkscl,im,l
;makes a scalebar into the image
col=max(im)
col2=min(im)
s=size(im)
img=im

xx=0.05*s(1)
yy=0.05*s(2)

xx=((xx-1)>0)<(s(1)-1)
yy=((yy-1)>0)<(s(2)-1)
x2=((xx+l+1)<(s(1)-1))>xx
y2=((yy+1+double(s(2))/66.)<(s(2)-1))>yy

img(xx:x2,yy:y2)=col
img(xx:x2,yy)=col2
img(xx:x2,y2)=col2
img(xx,yy:y2)=col2
img(x2,yy:y2)=col2


return,img


end
