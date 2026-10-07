function gauss2d,nx,ny,x,y,xfwhm,yfwhm

xehwd=float(xfwhm)/2.0/(alog(2.0))^0.5
yehwd=float(yfwhm)/2.0/(alog(2.0))^0.5

ix=findgen(nx)+1 ;lets see how this works
iy=findgen(ny)+1
onex=replicate(1.0,nx)
oney=replicate(1.0,ny)

xarr=((ix-x)/xehwd)^2 # oney
yarr=onex # ((iy-y)/yehwd)^2

rsq=xarr+yarr
array=fltarr(nx,ny)

big=where(rsq le 87.3,count)
if count ne 0 then array(big)=exp(-rsq[big])

return,array
end
