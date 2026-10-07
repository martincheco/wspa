pro pnom,x,a,f
f=a(0)+a(1)*x+a(2)*x^2+a(3)*x^3+a(4)*x^4+a(5)*x^5
end

pro ljpot,x,a,f
;for dipole+dz fitting
f0=1e6 ;resonance freq.
k0=1e6 ;stiffness
z0=double(a(0))
zo=double(a(1))
U0=double(a(2))

f=-0.5*f0/k0*U0*( 156*(z0^12/(x-zo)^14) - 84*(z0^6/(x-zo)^8) )

end

pro ljpoty,x,a,f
;for dipole+dz fitting
f0=1e6 ;resonance freq.
k0=1e6 ;stiffness
z0=double(a(0))
zo=double(a(1))
U0=double(a(2))

f=-0.5*f0/k0*U0*( 156*(z0^12/(x-zo)^14) - 84*(z0^6/(x-zo)^8) )+a(3)

end

pro parab,x,a,f

f=a(0)+a(1)*x+a(2)*x^2
end

pro gausovky,x,a,f
;for dipole+dz fitting
w=double(a(0)) ;resonance freq.
z1=double(a(1))
z2=double(a(3))
amp1=double(a(2))
amp2=double(a(4))
f=amp1*exp(-(x-z1)^2/2D/w^2)+amp2*exp(-(x-z2)^2/2D/w^2)


end



pro ljalt,x,a,f
;for dipole+dz fitting
f0=1e6 ;resonance freq.
k0=1e6 ;stiffness
z0=double(a(0))
zo=double(a(1))
U0=double(a(2))



f=-0.5*f0/k0*U0*( 156*(z0^12/(x-zo)^14) - 84*(z0^6/(x-zo)^8) + exp(a(3)*(x-zo)))

end




pro repp,x,a,f
common shr,fcm
;pv=a(0)
dz=a(0)
pv=a(1)
f=pv/x^3+dz*fcm
end

pro fitfunct_vis,x,y,fy
plot,x,y,psym=1
oplot,x,y,psym=1,color=128

oplot,x,fy

end


function fitfunct,t,f,pars=pars,z=z,dz=dz,d0=d0,vis=vis
;fits a curve by a specified function (must be compiled before)
;returns arrray fitted values; stores parameters into pars keyword
;pars will transfer the fitted values
;f is the given function
common shr,fcm


if not(keyword_set(pars)) then begin
	if f eq 'ljpot' then pars=[9.8D-10,-1.12e-9,-3e-19]
	if f eq 'ljalt' then pars=[9.8D-10,-1.12e-9,-3e-19,-1e10]
	if f eq 'ljpoty' then pars=[9.8D-10,-1.12e-9,-3e-19,0]
	if f eq 'parab' then pars=[0D,0D,0D]
	if f eq 'pnom' then pars=[0.,0.,0.,0.,0.,0.]
	if f eq 'gausovky' then begin
		n=n_elements(t)
		w=n/10.
		z1=w*2
		z2=n-w*2
		amp1=max(t)/2.
		amp2=amp1	
		pars=[w,z1,amp1,z2,amp2]
	end
end

tf=reform(t)
n=n_elements((tf))
if keyword_set(dz) then z=dindgen(n)*dz
if not(keyword_set(z)) and not(keyword_set(dz)) then z=dindgen(n)
if keyword_set(d0) then z=z+d0
wg=dblarr(n)+1.

w=where(finite(tf))

if n_elements(w) gt n_elements(pr) then begin 
	ft=curvefit(z(w),tf(w),wg(w),pars,function_name=f,/noderivative,/double,itmax=1000,status=status,tol=1E-4) 
end
if keyword_set(vis) then fitfunct_vis,z,tf,ft
if status eq 0 then return,ft else return,tf
end
