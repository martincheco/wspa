function badlines,img,dt
;removes well single lines that are bad
;has to be modified for multiple adjacent bad lines
;dt is the strength of the filter 0.5..

s=size(img)
if not(keyword_set(dt)) then dt=1. else $
    if dt eq 0 then dt=1. $
	else $
	    dt=(dt>0.5)<10.

test=(img-$
(0.5*shift(img,0,-1)+shift(img,0,-2)+shift(img,0,1)+0.5*shift(img,0,2))/3.$
)
tot=total(test^2,1)

w=where(tot gt dt*mean(tot))
if w(0) eq -1 then return,img 
im=img
wu=w-1
wd=w+1

    im(*,w)=round(min(img)-1.)
    kernel=bytarr(5,5)
    kernel(2,*) = [15,127,255,127,15]

;help,dt
                     
; Values of 255 are flagged as invalid (missing)  
; and replaced by 0 if there are no valid values  
; within the kernel  
if isgdl() then $
	im = CONVOL( im, kernel, /EDGE_WRAP) $
else $
	im = CONVOL( im, kernel, INVALID=round(min(img)-1.), MISSING=round(min(img)-1.), $  
	/NORMALIZE, /EDGE_WRAP )

res=img
res(*,w)=im(*,w)

return,res>min(img)
end