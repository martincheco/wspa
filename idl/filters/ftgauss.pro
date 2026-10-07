function ftgauss,img,m,n,style
;style - 0 gauss lowpass, 1 lowpass at 0.5 -1, highpass at 0.5, -2 gauss lowpass
;filter that applies arbitrary gaussian kernel
;min value 3
s=size(img)

if not(keyword_set(m)) then m=0.5 else if abs(m) lt 0.1 then m=m else m=(m>0.1)<10
if not(keyword_set(n)) then n=m else if abs(n) lt 0.1 then n=n else n=(n>0.1)<10
if not(keyword_set(style)) then begin 
    style=0
    ;print,"setting style 0"
end

;print,m,n
if m lt 0.001 then m=m*s(1)*100
if n lt 0.001 then n=n*s(2)*100

kernel = gauss2d(s(1),s(2),floor(s(1)/2),floor(s(2)/2),m*s(1),n*s(2))
if abs(style) eq 1 then kernel=round(kernel)
if style lt 0 then kernel=max(kernel)-kernel

kernel=shift(kernel,floor(s(1)/2),floor(s(2)/2))


imf=fft(img,1)
imf=(imf)*kernel        
imf=real_part(fft(imf,-1))

return,imf

end
