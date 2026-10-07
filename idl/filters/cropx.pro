
function cropx,img,x1,x2,y1,y2,comp=comp,swap=swap
;crops the image, conforms behaviour according to number of parameters
;compress says first two pars contain multiples 10000L*x1+x2 and 10000L*y1+y2 CAUTION MUST BE LONG
;swap reorders input values as x1,y1,x2,y2


    x=indgen(4)*10


if keyword_set(comp) then begin
    ;points given in two values as 10000*x1+x2 etc.
    if n_params() eq 3 then begin
	;print,'multiplicators,2 values'
	x=intarr(4)
	x(3)=x2 mod 10000.
	x(2)=x2/10000.
	x(1)=x1 mod 10000.
	x(0)=x1/10000.
    
	if keyword_set(swap) then begin
	    x=x([0,2,1,3])
	end

    end else return,img
end else $
;badly specified parameters

if n_params() lt 5 or n_elements(img) le 1  then begin
    print,'crop:too few params.'
    return,img
end

;points given as four values
if n_params() eq 5 then begin
    ;print,'4 values'
    x(3)=y2
    x(2)=y1
    x(1)=x2
    x(0)=x1
end

imf=reform(img)

s=size(imf)
;print,s
s(1)=s(1)-1
s(2)=s(2)-1
x=abs(x)

if x(0) gt x(1) then x=x([1,0,2,3])
if x(2) gt x(3) then x=x([0,1,3,2])


x(1)=x(1)>(x(0)+10)
x(3)=x(3)>(x(2)+10)

;print,(x(0)>0)<s(1),(x(1)>0)<s(1),(x(2)>0)<s(2),(x(3)>0)<s(2)
imf=imf((x(0)>0)<s(1):(x(1)>0)<s(1),(x(2)>0)<s(2):(x(3)>0)<s(2))
help,imf
s=size(imf)
if s(0) ne 2 then begin
    print,'crop:badly specified boundaries!!'
    return,img 
end else begin 
    return,imf
end
end
