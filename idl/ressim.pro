
function ressim_tristate,n,tr


pr1=-alog(randomu(seed,n))*tr(0)
pr2=-alog(randomu(seed,n))*tr(1)
pr3=-alog(randomu(seed,n))*tr(2)
pr4=-alog(randomu(seed,n))*tr(3)
pr=randomu(seed,n)

T=0D
c=0D

pt=(1./tr(2))/((1./tr(2))+(1./tr(3))) 

for i=1L,n do begin

	dt=1D-12*pr1(i-1) ;charge injection
	T+=dt
	dt=1D-12*pr2(i-1) ;charge capture
	T+=dt

	if pr(i-1) le pt then begin
		dt=1D-12*pr3(i-1)
		c++ ;count of emitted photons
	end else begin ;quench
		dt=1D-12*pr4(i-1)
		
	end
	T+=dt
end

print,c
return,c/T ;returns average EMMISSION rate

end


function ressim,n,tr

y=gauss1d(50,25,10)
y2=gauss1d(50,25,10)
plot,gauss1d(50,25,10)
oplot,gauss1d(50,25,10),psym=-2
emrate=dblarr(50)

for i=0,49 do begin
	print,i
	emrate(i)=ressim_tristate(n,[tr(0)/y(i),tr(1),tr(2)/y2(i),tr(3)])
end


oplot,emrate/max(emrate),color=255
print,max(emrate)
return,emrate
end

