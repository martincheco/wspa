function combine,x1,y1,x2,y2,exclude=exclude,resample=resample
;inserts 2nd curve into the 1st, assumes sampling is the same
;exclude - cuts the part of 1st curve which overlaps with the second curve
;resample - resamples the rougher curve to match the finer one
if n_elements(x1) lt 2L or n_elements(x2) lt 2L then return,{x:[x1,x2],y:[y1,y2]}
xmn=min([x1,x2])
xmx=max([x1,x2])

xmn2=min(x2)
xmx2=max(x2)

n1=n_elements(x1)
n2=n_elements(x2)
dx2=double(max(x2)-min(x2))/n2
dx1=double(max(x1)-min(x1))/n1

dx=min([dx1,dx2])
nn=(xmx-xmn)/dx
help,nn
nx=dindgen(nn)*dx+xmn
ny=dblarr(nn)*(-0./0.)

if keyword_set(resample) then begin
	if dx1 gt dx2 then begin
		nx1=interpolate(x1,dindgen(n1*dx1/dx2)*dx2/dx1)
		ny1=interpolate(y1,dindgen(n1*dx1/dx2)*dx2/dx1)
		nx2=x2
		ny2=y2
	end else begin
		nx2=interpolate(x2,dindgen(n2*dx2/dx1)*dx1/dx2)
		ny2=interpolate(y2,dindgen(n2*dx2/dx1)*dx1/dx2)
		nx1=x1
		ny1=y1
	end
end else begin
ny1=y1
nx1=x1
nx2=x2
ny2=y2
end

for i=0L,nn-1 do begin
	w1=where(abs(nx(i)-nx1) eq min(abs(nx(i)-nx1)))
	w2=where(abs(nx(i)-nx2) eq min(abs(nx(i)-nx2)))
	if (abs(nx(i)-nx1(w1(0))) gt abs(nx(i)-nx2(w2(0)))) or ((keyword_set(exclude)) and (nx(i) lt xmx2) and (nx(i) gt xmn2)) then ny(i)=ny2(w2(0)) else ny(i)=ny1(w1(0))

end


return,{x:nx,y:ny}
end
