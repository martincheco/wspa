function visualft,img,method,r1,r
s=size(img)

if n_params() le 2 then begin
r1=(s(1)+s(2))/100
r=1
end

ftimg=(shift((fft(img)),s(1)/2,s(2)/2))
fimg=(shift(abs(fft(img)),s(1)/2,s(2)/2))

if keyword_set(r) then begin
fimg(s(1)/2-r/2+0.5:s(1)/2+r/2+0.5,*)=0
ftimg(s(1)/2-r/2+0.5:s(1)/2+r/2+0.5,*)=0
end

if keyword_set(r1) gt 0 then begin
fimg(s(1)/2-r1+0.5:s(1)/2+r1+0.5,s(2)/2-r1+0.5:s(2)/2+r1+0.5)=0
ftimg(s(1)/2-r1+0.5:s(1)/2+r1+0.5,s(2)/2-r1+0.5:s(2)/2+r1+0.5)=0

end 
    
if keyword_set(method) then begin
;modulus
    if method eq 1 then return,fimg
;logarithm
    if method eq 2 then return,alog10(bytscl(fimg)+10)
;power spectrum
    if method eq 3 then return,bytscl(fimg^2)
;sqrt of modulus
    if method eq 4 then return,bytscl(fimg^0.5) ;else return,alog10(bytscl(fimg)+10.)
;phase
    if method eq 5 then return,(float(ftimg))
    if method eq 6 then return,(imaginary(ftimg))
end else return,alog10(bytscl(fimg)+10.)
    
end 