function factorize,sig,crv,nnn
;factorizes a signal with a given curve
;changing only amplitude
;initial guess

if not(keyword_set(nnn)) then nnn=1000L

sig=reform(sig)
crv=reform(crv)

sigmn=min(sig)
sigmx=max(sig)
sigm=mean(sig)

crvmn=min(crv)
crvmx=max(crv)
crvm=mean(crv)

amp=sigm/crvm
;help,amp
;help,sig
;help,crv
diff=total((sig-amp*crv)^2,/double)
;diff=total((sig-(amp*(crv)))^2,/double)
odiff=diff*0.99
off=0D
doff=sigm
factor=0.99

for i=0,nnn-1 do begin
	namp=amp*(1.+factor*(randomu(seed)-0.5))
	noff=off+randomn(seed)*doff*factor
	diff=total((sig-(namp*crv+noff))^2,/double)
	if diff lt odiff then begin
		amp=namp
		off=noff
		odiff=diff
;	print,'improving',amp,off,factor
;		plot,sig
;		oplot,amp*crv+off,color=128
;		wait,0.1
		factor*=0.99
	end
end

;plot,sig,xst=1
;oplot,amp*crv,color=255
;wait,.5
return,{fit:amp*crv+off,amp:amp,off:off}
end
