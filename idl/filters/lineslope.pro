function lineslope,img,speed
;removes slope for each line
;speed tells the division coeff
s=size(img)
imf=img
x=findgen(s(1))-s(1)/2
c=fltarr(s(1))+1.
if not(keyword_set(speed)) then speed=1. else speed=(speed>1)<(s(2)/2)
n=s(2)/(speed)
help,n

meanval=fltarr(n)
sl=fltarr(n)

for i=0,n-1 do begin
    lne=imf(*,i*s(2)/n)
    ab=LADFIT(x,lne)
    meanval(i)=ab(0)
    sl(i)=ab(1)
end

bkg=x#sl+c#meanval

if s(2) ne n then bkg=congrid(bkg,s(1),s(2),/interp)
imf=imf-bkg
    
help,imf
return,imf
end