function pad,img,px1,py1,px2,py2,missing=missing
;pads an image by px an py in corresponding directions on both sides
;maintains the type
s=size(img)
if not(keyword_set(missing)) then missing=0.
nimg=replicate(img(0)*missing,s(1)+px1+px2,s(2)+py1+py2)
nimg(px1:s(1)+px1-1,py1:s(2)+py1-1)=img
return,nimg
end
