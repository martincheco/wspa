function bkg_twist,img
;removes a background that is twisted, leading lines are top and bottom line
help,img
imf=img
s=size(img)
alne=imf(*,s(2)-1)
a=LADFIT(dindgen(s(1)),alne)
blne=imf(*,0)
b=LADFIT(dindgen(s(1)),blne)

sa=a(1)
sb=b(1)
oa=a(0)
ob=b(0)

la=sa*dindgen(s(1))+oa
lb=sb*dindgen(s(1))+ob
k=(la-lb)/s(2)

for i=0,s(1)-1 do begin
    imf(*,i)=imf(*,i)-dindgen(s(2))*k(i)-lb(i)
end

return,imf
end