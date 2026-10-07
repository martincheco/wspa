function conv,a,b
return,fft(fft(a,-1,/double)*fft(b,-1,/double),1,/double)

end
