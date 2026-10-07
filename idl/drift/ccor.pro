function ccor,im1,im2,nan=nan
;print, 'Creating crosscorrelation..'
im1t=im1
im2t=im2
if keyword_set(nan) then begin
    w=(where(finite(im1,/nan)))
    if w(0) ne -1 then im1t(w)=0
    w=(where(finite(im2,/nan)))
    if w(0) ne -1 then im2t(w)=0
end
temp1=fft(im1t,-1)
temp2=fft(im2t,-1)
imf=fft(temp1*CONJ(temp2),-1)
return, imf
end
