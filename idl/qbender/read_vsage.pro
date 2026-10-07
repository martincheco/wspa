function getparams,stack

xunit="n/a"
yunit="n/a"
tunit="n/a"

xstart=getval(stack,"# Ramp start value","float",unit=xunit)
xunit="["+xunit+"]"
chan=getval(stack,"# Channel name and data unit","str",unit=yunit)

p=strpos(chan,"(")
p1=strpos(chan,")")
xax=strmid(chan,p+1,p1-p-1)
yax=strmid(chan,0,p)


dt=getval(stack,"# Raster time","float",unit=tunit)
pos=getval(stack,"# Sample position","str")
p=strpos(pos,",")
p1=strpos(pos,"[")

xpos=float(strmid(pos,0,p))
ypos=float(strmid(pos,p+2,p1-3-p))
punit=strmid(pos,p1)


return,{dt:dt,xpos:xpos,ypos:ypos,xax:xax,yax:yax,yunit:yunit,xunit:xunit,tunit:tunit,punit:punit}
end



function read_vsage,f
;structure definition
;x,y,yb - the data, yb is backward
;pars - parameters in the header
;f - original filename


if not(file_test(f)) then return,-1
a=read_ascii(f,data_start=16,header=h)
x=a.field1(0,*)
y=a.field1(1,*)

n=n_elements(x)

xb=x(n/2:*)
yb=y(n/2:*)
i=sort(xb)
xb=xb(i)
yb=yb(i)

x=x(0:n/2-1)
y=y(0:n/2-1)
i=sort(x)
x=x(i)
y=y(i)

pars=getparams(h)
pars=pars
if total((x - xb)^2) ne 0 then begin
    print,"Error, returning only first half of data from ",f
    return,{x:x,y:y,yb:y*0,header:h,pars:pars}
end

return,{x:x,y:y,yb:yb,header:h,f:f,pars:pars}
end
