function gauss1d,nx,x,xfwhm

xehwd=double(xfwhm)/2.0/(alog(2.0))^0.5

ix=findgen(nx)

xarr=((ix-x)/xehwd)^2

rsq=xarr
array=dblarr(nx)

big=where(rsq le 87.3,count)
;help,big
if count ne 0 then array(big)=exp(-rsq[big])

return,array
end
