function ramanstick_read

f=dialog_pickfile(/must_exist)
t=read_ascii(f)
tt=t.(0)
x=reform(tt(0,*))
y=reform(tt(1,*))

return,{x:x,y:y,f:f}
end


function ramanstick_gauss_irr,d,w

cm=max(d.x)
n=n_elements(d.x)

xn=dindgen(cm)
yn=xn*0

for i=0,n-1 do begin
	g=gauss1d(cm,d.x(i),w)*d.y(i)
	yn+=g
end



return,{x:xn,y:yn,xo:d.x,yo:d.y,yn:yn/max(yn),f:d.f}
end

function ramanstick_gauss,d,w
g=gauss1d(n_elements(d.x),4*w,w)

yn=shift(real_part(conv(g,d.y)),-4*w)

return,{x:d.x,y:d.y,yn:yn/max(yn),f:d.f}
end


pro ramanstick_exp,ff,d
openw,1,ff
for i=0,n_elements(d.x)-1 do printf,1,d.x(i),d.y(i),d.yn(i)
close,1

end


pro ramanstick_convert,w,plt=plt,irr=irr
;plt keyword plots the spectrum
;irr serves for irregular data (vib intensities of individual modes only)
print,'reading'
d=ramanstick_read()
print,'gaussing'
if keyword_set(irr) then $
	dd=ramanstick_gauss_irr(d,w) $
else $
	dd=ramanstick_gauss(d,w)
print,'reexporting'
ramanstick_exp,dd.f+'.dat',dd
if keyword_set(plt) then plot,dd.x,dd.yn,xtit='Energy (cm^-1)',ytit='Intensity'

end
