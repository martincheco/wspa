function dedouble,img,x,y,amp,iter
;x,y position of the ghost image
;iter number of interations
;amp amplitude of ghost image

;kern=fltarr()
s=size(img)
imgn=double(img)

;wrapping
if abs(2*x) lt s(1)-1 and abs(2*y) lt s(2)-1 then begin
imgn=shift(imgn,s(1)/2,s(2)/2)
imgn(s(1)/2-abs(x):s(1)/2+abs(x),*)=smooth(imgn(s(1)/2-abs(x):s(1)/2+abs(x),*),x)
imgn(*,s(2)/2-abs(y):s(2)/2+abs(y),*)=smooth(imgn(*,s(2)/2-abs(y):s(2)/2+abs(y),*),y)
imgn=shift(imgn,-s(1)/2,-s(2)/2)
end






imgs=amp*shift(double(imgn),x,y)
	m=min(imgs)

;	if x gt 0 and y gt 0 then imgs(0:x-1,*)=m
;	if x gt 0 and y gt 0 then imgs(*,0:y-1)=m
    
;	if x lt 0 and y lt 0 then imgs(x:s(1)-1,*)=m
;	if x lt 0 and y lt 0 then imgs(*,y:s(2)-1)=m

;	if x gt 0 and y lt 0 then imgs(0:x,*)=m
;	if x gt 0 and y lt 0 then imgs(*,y:s(2)-1)=m

;	if x lt 0 and y gt 0 then imgs(*,0:y)=0
;	if x lt 0 and y gt 0 then imgs(x:s(1)-1,*)=m

imgn=img
imgn=imgn-min(imgn)

    imgres=imgn

    for i=1,iter do begin
	imgres=imgres-imgs
	imgs=-amp*shift(imgs,x,y)
	
	m=min(imgs)
;	if x gt 0 and y gt 0 then imgs(0:x-1,*)=m
;	if x gt 0 and y gt 0 then imgs(*,0:y-1)=m
    
;	if x lt 0 and y lt 0 then imgs(x:s(1)-1,*)=m
;	if x lt 0 and y lt 0 then imgs(*,y:s(2)-1)=m

;	if x gt 0 and y lt 0 then imgs(0:x,*)=m
;	if x gt 0 and y lt 0 then imgs(*,y:s(2)-1)=m

;	if x lt 0 and y gt 0 then imgs(*,0:y)=m
;	if x lt 0 and y gt 0 then imgs(x:s(1)-1,*)=m

    end

;print,min(imgres)
;	if x gt 0 and y gt 0 then imgres(0:x-1,*)=0
;	if x gt 0 and y gt 0 then imgres(*,0:y-1)=0
    
;	if x lt 0 and y lt 0 then imgres(x:s(1)-1,*)=0
;	if x lt 0 and y lt 0 then imgres(*,y:s(2)-1)=0

;	if x gt 0 and y lt 0 then imgres(0:x,*)=0
;	if x gt 0 and y lt 0 then imgres(*,y:s(2)-1)=0

;	if x lt 0 and y gt 0 then imgres(*,0:y)=0
;	if x lt 0 and y gt 0 then imgres(x:s(1)-1,*)=0


return,imgres
end


function dedoublex,img,x,y,iter
;x,y position of the ghost image
;iter number of interations
;amp amplitude of ghost image

;iter=100
amparr=findgen(100)/100;*0+0.5

mns=fltarr(100)

;mns=fltarr(100,n_elements(img))


;for k=1,20 do begin

for j=0,99 do begin
amp=amparr[j]

;    imgs=amp*shift(double(img),x,y)
;    imgres=double(img)
;
;    for i=1,iter do begin
;	imgres=imgres-imgs
;	imgs=-amp*shift(imgs,x,y)
;    end
    
    imgres=dedouble(img,x,y,amp,iter)


mns(j)=min(imgres)
;mns(j,*)=imgres

end



w=where(mns(30:*) eq max(mns(30:*)))
print,w

print,amparr((w(0)>0)+30)
amp=amparr((w(0)>0)+30)

imgres=dedouble(img,x,y,amp,iter)

;end

return,imgres
end