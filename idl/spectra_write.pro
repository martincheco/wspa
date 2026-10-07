pro spectra_write,f,x,y
;writes spectrum into file, x is in nm, y in arb units
;columns are: nm, eV, intensity, corrected intensity
ex=1239.841984/x
yc=y*1239.841984/ex^2


openw,1,f

for i=0,n_elements(x)-1 do $
	printf,1,x(i),ex(i),y(i),yc(i)
close,1

end
