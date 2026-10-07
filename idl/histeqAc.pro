function histeqAc,img,w
s=size(img)
nimg=img
rimg=img
for i=w+1,s(1)-w-1 do begin
 p=histogram(nimg(i-w:i+w,1:2*w+1))
 for k=1,n_elements(p)-1 do p(k)=p(k)+p(k-1) ;integrate
   print,i

  for j=w+1,s(2)-w-2 do begin
   adp=histogram(nimg(i-w:i+w,j+w+1))
   for k=1,n_elements(adp)-1 do adp(k)=adp(k)+adp(k-1) ;integrate
   sbp=histogram(nimg(i-w:i+w,j-w))
   for k=1,n_elements(sbp)-1 do sbp(k)=sbp(k)+sbp(k-1) ;integrate
   p=p+adp-sbp
   rimg(i,j)=p(nimg(i,j))
 endfor

endfor
return,rimg
end
