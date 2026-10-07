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


pro repp,x,a,f
common shr,fcm
;pv=a(0)
dz=a(0)
pv=a(1)
f=pv/x^3+dz*fcm
end


function stackfitz,t,f=f,pr=pr,pars=pars,dz=dz,com=com,d0=d0
;fits a stack(z,x,y) by a specified function (must be compiled before)
;returns stack of fitted values; stores parameters into pars keyword
;com transfers a common stack from which one column is passed to the fitting f
;pars will transfer the fitted values
;f is the given function
common shr,fcm

if not(keyword_set(f)) then begin 
	f='pnom'
	pr=[0.,0.,0.,0.,0.,0.]
end
pr=double(pr)
s=size(t)
nt=dblarr(s(1),s(2),s(3))*(-0./0.)
if keyword_set(dz) then z=dindgen(s(1))*dz else z=dindgen(s(1))
if keyword_set(d0) then z=z+d0
wg=dblarr(s(1))+1.
pars=dblarr(n_elements(pr),s(2),s(3))*(-0./0.)
for i=0,s(2)-1 do for j=0,s(3)-1 do begin
	prr=pr	
	tf=reform(t(*,i,j))
	w=where(finite(tf))
	if keyword_set(com) then fcm=reform(com(w,i,j))
	if n_elements(w) gt n_elements(pr) then begin 
		ft=curvefit(z(w),tf(w),wg(w),prr,function_name=f,/noderivative,/double,itmax=500,status=status,tol=1E-4) 
		nt(w,i,j)=ft
		if status eq 0 then pars(*,i,j)=prr	
	end

end

return,nt
end
