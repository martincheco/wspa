function crop,img,cx,cy,xdia,ydia
;crops sqr region
;CAUTION DOES NOT PRESERVE DIMENSIONS
;cx,cy center
;xdia,ydia size
;max. 2x bigger or dia 10px

if not(keyword_set(ydia)) then ydia=xdia

s=size(img)
xdia=((abs(xdia))>10)<2*max([s(1),s(2)])
ydia=((abs(ydia))>10)<2*max([s(1),s(2)])

;help,xdia
;help,ydia

nimg=replicate(img(0)*0,xdia,ydia)

;help,nimg

xs=indgen(xdia)+cx-xdia/2
ys=indgen(ydia)+cy-ydia/2

;help,xs
;help,ys

;print,s

wx=where(xs ge 0 and xs le s(1)-1)
wy=where(ys ge 0 and ys le s(2)-1)

;help,wx
;help,wy

if wx(0) ne -1 then xs=xs(wx) else return,intarr(10,10)

if wy(0) ne -1 then ys=ys(wy) else return,intarr(10,10)

;help,xs
;help,ys

nimg=img(min(xs):max(xs),min(ys):max(ys))
;help,nimg
return,nimg

end