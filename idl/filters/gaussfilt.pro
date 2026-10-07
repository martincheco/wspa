function gaussfilt,img,m,n

s=size(img)

if not(keyword_set(m)) then m=3 else m=(m>3)<(s(1)/2)
if not(keyword_set(n)) then n=m else if abs(n) lt 0.001 then n=m else n=(n>3)<(s(2)/2)

kernel = gauss2d(m,n,floor(m/2),floor(n/2),m/3,n/3)

;print,s(1),s(2)
;print,m,n


if s(1) gt m and s(2) gt n then imf=convol(img,kernel,/edge_truncate) else imf=img

return,imf

end
		  