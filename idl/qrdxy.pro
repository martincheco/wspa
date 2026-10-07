function qrdxy,file

y=read_ascii(file,header=head,data_start=16)

xunit='V'
yunit='nA'


xx=(y.(0)(0,*))
yy=(y.(0)(1,*))*1E9
nc=1
n=n_elements(yy)
help,yy
help,n
nc=n_elements(where(xx eq xx(1)))
if nc gt 1 then begin
n=n/nc
xx=(reform(xx,n,nc))
yy=(reform(yy,n,nc))
end 

return, {x:xx, y:yy, xunit:xunit, yunit:yunit, n_points: n, n_curves: nc}
end