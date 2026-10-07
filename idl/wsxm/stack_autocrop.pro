function stack_autocrop,st
s=size(st)
r=total((st),1)
tvscl,finite(r)
help,r
lnx=total(finite(r),2)
lny=total(finite(r),1)
;plot,lny
wx=where((lnx))
wy=where((lny))

if wx(0) ne -1 and wy(0) ne -1 then begin
	res=st(*,wx(0):wx(-1),wy(0):wy(-1))
end else res=-1


return,res

end
