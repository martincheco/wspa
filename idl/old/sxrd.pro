function rmbkgirr,I,x,y

ang=getangle(x,y)
r=getrad(x,y)
return,1
end

function pxmap,I,xp,x,y
xp=xp+1
img=(reform(I,xp,fix(n_elements(I)/xp)))
imgang=(reform(x,xp,fix(n_elements(I)/xp)))
imgrad=(reform(y,xp,fix(n_elements(I)/xp)))

return,{img:img,ang:imgang,rad:imgrad}
end

function hex2rect,h,k
a=complex(1.,0)
b=complex(1.,sqrt(3))/2
return,a*h+b*k
end

function getangle,x,y
return,atan(y/x)*180/!PI
end

function getrad,x,y
return,(x^2+y^2)^0.5
end


function rd_sxrd,f
dt=read_ascii(f)

f=dt.(0)
h=f(0,*)
k=f(1,*)
I=double(f(2,*))
I=bytscl(I-min(I))
return,{h:reform(h),k:reform(k),I:reform(I)}
end

pro sxrd,f
st=rd_sxrd(f)
t=hex2rect(st.h,st.k)
x=float(t)
y=imaginary(t)
I=st.I

xmx=max(x)
ymx=max(y)
xmn=min(x)
ymn=min(y)

device,decomposed=0
device,retain=2

wx=800
wy=600
x0=0
y0=0
x1=0
y1=0
pal=-1
hx=0
hi=0
lo=0
pts=0
sq=0
inv=0
bkg=0
pxm=0
rot=0
srt=0

if File_test('sxrd.txt') then begin
    param=loadparam('sxrd.txt')
    wx=getval(param,'xwinsize','int')
    wy=getval(param,'ywinsize','int')
    x0=getval(param,'xstart','float')
    x1=getval(param,'xend','float')
    y0=getval(param,'ystart','float')
    y1=getval(param,'yend','float')
    pal=getval(param,'palette','int')
    hx=getval(param,'histexpand','int')
    hi=getval(param,'hival','float')
    lo=getval(param,'loval','float')
    pts=getval(param,'showpoints','int')    
    sq=getval(param,'reform','int')    
    inv=getval(param,'invert','int')    
    bkg=getval(param,'background','float')    
    raw=getval(param,'pixmap','int')
    pxm=getval(param,'linewidth','int')
    rot=getval(param,'rotate','int')
    srt=getval(param,'sort','int')

end

if pal gt -1 and pal le 31 then loadct,pal else goldpalette,/pure


if hx eq 1 then $
    if hi ne lo then begin
	;print,'hx lohi'
	I=histxpand(I,limits=[lo,hi]) 
    end else I=histxpand(I)


    
    if pxm gt 0 then begin
	st=pxmap(I,fix(pxm),x,y)
	I=st.img
	x=st.ang
	y=st.rad
	s=size(I)
	Ic=I
	if bkg gt 0 then begin
	    print,'background'
	    for ii=0,s(2)-1 do Ic(*,ii)=fitbkg(reform(I(*,ii)),bkg)
	    I=Ic-min(Ic)
	end
	if bkg lt 0 then begin
	    for ii=0,s(1)-1 do Ic(ii,*)=fitbkg(reform(I(ii,*)),abs(bkg))
	    I=Ic-min(Ic)
	end

    end

if sq eq 1 then begin 
    r=getrad(x,y)
    ang=getangle(x,y)
    y=r
    x=ang
end
    
    xrng=[x0,x1]
    yrng=[y0,y1]
    


if x0 ne 0 and x1 ne 0 then begin
    xmx=x1
    xmn=x0
end
    
if y0 ne 0 and y1 ne 0 then begin
    ymx=y1
    ymn=y0
end
    

if raw gt 0 then begin
	window,1,xs=(s(1)>100)<800,ys=(s(2)>100)<600
	tvscl,I
end $
else $
begin
    if wx gt 0 and wy gt 0 then window,1,xs=(wx<1280)>100,ys=(wy<1024)>100

    if rot eq 1 then begin
	sw=y
	y=x
	x=sw
    end

    contour,(I),x,y,/irregular,nlevels=60,/cell_fill,background=0,color=255,xst=1,yst=1,iso=1-((sq>0)<1)

    if pts eq 1 then oplot,x,y,psym=3,color=255

end

if inv eq 1 then begin
a=tvrd(0)
tvscl,255-a
end
a=tvrd(0,true=1)

f=dialog_pickfile(filter='*.png',/overwrite_prompt)
if f ne "" then write_png,f,a

end