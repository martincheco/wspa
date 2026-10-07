function find_uniq,x,y,xtol=xtol,ytol=ytol
;x periodicity
;y appangle
;for sure
xr=reform(x)
yr=reform(y)

u=sparse_uniq(xr,tol=xtol)
print,"uniq"
print,xr(u)

tot=0L

for i=0,n_elements(u)-1 do begin
    ix=where(abs(xr - xr(u(i))) lt xtol)
    print,"apps:",yr(ix)
    wu=sparse_uniq(yr(ix),tol=ytol)
    print,x(u(i)),":",y(ix(wu))
    tot=[tot,ix(wu)]
end

return,tot(1:*)

end