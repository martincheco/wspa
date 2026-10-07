function stuff,img,fact,missing=missing,pad=pad
;increases size of the image but does not scale the image, the original is centered within
;missing parameter specifies the value on the added area
;pad 

s=size(img)
if not(keyword_set(fact)) then fact=2^0.5
if not(keyword_set(missing)) then missing=median(img)
fact=(fact>1.)<4.
imf=replicate(missing,s(1)*fact,s(2)*fact)
xoff=round((fact-1)*s(1)/2)
yoff=round((fact-1)*s(2)/2)
;print,s
;print,xoff,yoff
;help,img
;help,imf(xoff:s(1)+xoff-1,yoff:s(2)+yoff-1)
imf(xoff:s(1)+xoff-1,yoff:s(2)+yoff-1)=img

return,imf
end
