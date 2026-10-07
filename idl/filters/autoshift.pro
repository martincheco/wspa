function autoshift,ref,img,coords=coords
;function automatically adjusts offsets of an images
;ref is reference image, img the image
;supposed to have same dimensions
;
im=img
cr=ccor(im,ref)
s=size(ref)
w=where(cr eq max(cr))
;help,w
x=0
y=0
if w(0) ne -1 then begin
    x=w(0) MOD s(1)
    y=w(0) / s(1)
end

if keyword_set(coords) then coords=[x,y] 

im=shift(im,x,y)

return,im
end
