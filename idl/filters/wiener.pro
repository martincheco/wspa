function wiener,y,h,sigma,gamma,alpha
;
; wienerFilter(y,h,sigma,gamma,alpha);
;
; Generalized Wiener filter using parameter alpha. When
; alpha = 1,(The noise Power) it is the Wiener filter. It is also called
; Regularized inverse filter.
;

h=fltarr(6,6)
h(0,5)=1.
;h(3,0)=.6
h(2,0)=0.9

s = size(y)
sh = size(h)
Yf = fft(y,-1)		; Fourier transform of original image N by filter function
hh=complexarr(s(1),s(1)) ; stuff the kernel
hh(0:sh(1)-1,0:sh(2)-1)=h                     
Hf = (fft((hh),-1))           ; Fourier transform of filter function
Pyf = abs(Yf)^2/s(1)^2
print,max(Pyf)

sHf = Hf*(abs(Hf) gt 0.)+1./gamma*(abs(Hf) eq 0.)   ;Fourier transform of filter function + its inverse
iHf = 1./sHf         ;inverse

iHf = iHf*((abs(Hf)*gamma) gt 1.)+gamma*abs(sHf)*iHf*((abs(sHf)*gamma) le 1.)
;array element increases if bigger than noise variance, decreases if below noise variance. 
;iHf is the Power Spectral Frequency Fourier Transform


Pyf = Pyf*(Pyf gt sigma^2)+sigma^2*(Pyf le sigma^2)    ;Pyf is the noise power spectrum..increased for 
;pyf bigger than noise mean, if signal is small pyf will be made smaller.


Gf = iHf*(Pyf-sigma^2)/(Pyf-(1-alpha)*sigma^2);   ;Gf is the esitmated image Fourier Transform
;Gf is basically the filter functions effect on Pyf-the transformed signal N

; Restored image 
eXf = Gf*Yf	;The filter multiplies each pixel in the Fourier image(Yf) by this filter(Gf)

ex = real_part(fft(eXf,/inverse))     
 ;inverse fourier tranform of the filtered Fourier transform of the new image yields 
 ;the hopefully noise free result.

alt=Yf/Hf

;return,fft(alt,/inverse)

return,ex
end

