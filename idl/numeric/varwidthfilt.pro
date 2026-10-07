function varwidthfilt,yy,a,b,edge_wrap=edge_wrap
;variable width filter, starts with width a, ends with b
;assumes a < b
y=reform(yy)

n=n_elements(y)
ix=dindgen(n)*double(b-a)/n+a
ny=y


if keyword_set(edge_wrap) then begin
	ny=dblarr(n+a+b)
	ny(a:-b-1)=y
	ny(0:a)=y(0)
	ny(-b:-1)=(y(-1))
help,y(-1)
	ix=(dindgen(n+a+b)-a)*double(b-a)/n+a


end

ffy=ny*0D
for w=a,b do begin
	fy=ftgauss1d(ny,double(w))
	wr=where(round(ix) eq w,count)
	if count ne 0 then ffy(wr)=fy(wr)
end

if keyword_set(edge_wrap) then begin
	ffy=ffy(a:n+b-1)
end

return,ffy
end
