function giessibl_m,n,w
	ii=mreplicate(indgen(n)+1,n)
	jj=reverse(transpose(ii))
	wd=double(w)
	jjd=double(jj)
	iid=double(ii)
	aa=1D - (2D*(iid-jjd)/(2D*wd+1D))
	bb=1D - (2D*(iid-jjd+1D)/(2D*wd+1D))
	m=-sqrt(1D - aa^2)+sqrt(1D - bb^2)
	m(where(((iid-jjd) gt 2*wd) or ((iid-jjd) lt 0D)))=0D
	return,m
end

function giessibl_expand,sig,n
;expands the signal to wrap against weird effects
s=size(sig)
ext=sig(-1,*,*) ;seems to work for 1Da nd 2D
nsig=sig
for i=0,n-1 do nsig=[nsig,ext]
help,nsig
return,nsig
end


function giessibl_1d,sig,rev=rev,n=n,k=k,f0=f0,dz=dz,m=m
;converts df to force or back using giessibl's matrix
;input values: df [Hz] or F [N]
;ext extends the signal to avoid edge effects
;df to F conversion is default
;rev - if set, the routine makes a df to F conversion
;obligatory parameters:
;dz - step in Z [m]
;f0 - resonance freq.
;k - sensor stiffness
;n - amplitude in multiples of dz

	nn=(size(sig))(1)
	if not(keyword_set(m)) then begin
		m=f0/k/!PI/dz/n*giessibl_m(nn,n)
		if keyword_set(rev) then m=la_invert(m,/double)
	end
	res=m##sig
	return,reform(res)
end

function giessibl,osig,rev=rev,n=n,k=k,f0=f0,dz=dz,m=m,ext=ext
;a wrapper function which can work on array of df curves
;osig can be 1D, 2D or 3D

	if keyword_set(ext) then sig=giessibl_expand(osig,2*n) else sig=osig
	s=size(sig)
	res=sig*(-0./0.)
	if s(0) eq 1 then res=giessibl_1d(sig,rev=rev,dz=dz,k=k,n=n,f0=f0,m=m)
	if s(0) eq 2 then for i=0,s(2)-1 do $
		res(*,i)=giessibl_1d(sig(*,i),rev=rev,dz=dz,k=k,n=n,f0=f0,m=m)
	if s(0) eq 3 then for i=0,s(2)-1 do begin
		for j=0,s(3)-1 do res(*,i,j)=giessibl_1d(sig(*,i,j),rev=rev,dz=dz,k=k,n=n,f0=f0,m=m)
	end
	if keyword_set(ext) then res=res(0:-2*n-1,*,*)
	return,res
end
