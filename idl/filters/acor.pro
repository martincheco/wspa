function acor,im
print, 'Creating autocorrelation..'
temp=fft(im,-1)
imf=fft(temp*CONJ(temp),-1)
return, imf
end

