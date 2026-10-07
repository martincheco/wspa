function criterion,ff
;ffy=extremesexcluded(ff)
ffy=ff-min(ff)
return,where(ffy gt mean(ffy))

;ffy=ff
;yh=histogram(ffy,nbins=10,locations=b)
;pos=b(where(yh eq max(yh)))
;var=variance(ffy)
;print,pos,var

;return,where(abs(ffy-pos(0)) lt var*2)




end

function get_profile,img,x0,y0,r,rp
;get a profile from image
;x0 y0 initial position
im=img
s=size(im)
;print,x0-rp,x0+rp,y0-r,y0+r
cut=im(x0-rp:x0+rp,y0-r:y0+r)
cut=total(cut,1)
;help,cut
;im(x0,y0-r:y0+r)=0
;tvscl,histxpand(im)
cut=cut-min(cut)

pfl=cut

return,pfl-min(pfl)
end


function get_distance,ff,tolerance

;determines the beginning and the end of the profile

;selects the points over the limit
n=n_elements(ff)
;criterion
;w=(where(ff gt max(ff)/2))
;pfl2(where((median(pfl)-pfl) lt variance(pfl)))=0
w=criterion(ff)


if w(0) eq -1 then return,[0,0]


ww=intarr(n)	
ww(w)=1	;construct an array of valid points
wwm=shift(ww,1)
ww=ww-wwm ;derivate

if ww(0) eq -1 then begin 
    ww(0)=0
    ww(n-1)=-1
end

if ww(0) eq 1 and ww(n-1) eq 1 then begin 
    ww(0)=1
    ww(n-1)=-1
end

dst1=where(ww eq 1)
dst2=where(ww eq -1)

if dst1(0) eq -1 then return,[0,0] 

;help,dst1
;help,dst2
;print,dst1
;print,dst2


if keyword_set(tolerance) then begin
    for i=1,n_elements(dst1)-1 do begin
	if dst1(i)-dst2(i-1) lt tolerance then begin
	    dst2(i-1)=-1
	    dst1(i)=-1
	end
    end
    
    dst2=dst2(where(dst2 ne -1))
    dst1=dst1(where(dst1 ne -1))
end

;help,dst1
;help,dst2
;print,dst1
;print,dst2



;dst1=dst1(where(dst1 lt n/2)>0)
;dst2=dst2(where(dst1 lt n/2)>0)

;dst2=dst2(where(dst2 gt n/2)>0)
;dst1=dst1(where(dst2 gt n/2)>0)




;ww1=dst1(where(abs(n/2-dst1) eq min(abs(n/2-dst1))))
;ww2=dst2(where(abs(dst2-n/2) eq min(abs(dst2-n/2))))



www=where(dst2 gt n/2 and dst1 lt n/2)
if www(0) ne -1 then begin
    ww1=dst1(www(0))
    ww2=dst2(www(0))
    print,ww1,ww2
end else $
begin
    ww1=0
    ww2=0
end




return,[ww1(0),ww2(0)]
end


function find_row,img,x0,y0,r,rp,angle,recenter=recenter
;finds the angle of best line overlay of a linear structure and returns the profile
;x0 y0 initial position
;r,rp dimensions of the mask, angle its orientation
;recenter tells how many times to recenter before returning an angle and length

s=size(img)
tot=dblarr(5)
if not(keyword_set(recenter)) then recenter=0

imgb=shift([[img,img*0],[img*0,img*0]],s(1)/2,s(2)/2)
mask=linear_mask(angle,r,rp,s(1)*2,s(2)*2)
;contour, img,/fill,nlevels=15,/iso,xst=1,yst=1
;plots,x0,y0,psym=5

for c=0,recenter do begin

basemask=shift(mask,-s(1)/2+x0,-s(2)/2+y0)

    xsh=-s(1)/2+x0
    ysh=-s(2)/2+y0
    ;print,xsh,ysh

    msx=[0,-1,1,0,0]
    msy=[0,0,0,-1,1]

    for i=0,4 do tot(i)=total(imgb*(shift(basemask,msx(i),msy(i))))

    w=where(tot eq max(tot))

    x0=x0+msx(w(0))
    x0=x0+msy(w(0))

    ;print,x0,y0
    ;print,c



end

return,[x0,y0]
end

function linear_mask,angle,r,rp,xs,ys
r=r<min([xs,ys])
rp=rp<min([xs,ys])
msk=intarr(xs,ys)
msk(xs/2-r:xs/2+r,ys/2-rp:ys/2+rp)=1
msk=rot(msk,angle,missing=0)
return,msk
end


function i_distance,im,r,x,y
s=size(im)

pfl=get_profile(im,x,y,r,3)

sp=size(pfl)

dsts=get_distance(pfl,6)

return,dsts
end


function prodhist,img,r,points=points

setcurs
device,set_graphics=3
goldpalette,/pure
contour,img,/fill,nlevels=30,/iso,xst=1,yst=1
ns=0
device,set_graphics=6
;contour,img,/fill,nlevels=30,/iso,xst=1,yst=1,/nodata
if keyword_set(points) then begin
    points=points(*,where(points(0,*)))
    ns=n_elements(points)/4
    for i=0,ns-1 do plots,[points(0,i),points(1,i)],[points(2,i),points(3,i)],psym=-3
    ns=n_elements(points)/4
    help,points
    points=transpose([transpose(points),transpose(intarr(4,1000))])
end else points=intarr(4,1000)

cs=fltarr(1000)
s=size(img)
i=0

inside=1
res=0
xd=0
yd=0
dsts=[0,0]

while inside do begin
    
cursor,x,y,/data,/up
if (x gt r and x lt s(1)-r and y gt r and y lt s(2)-r) then inside=1 else inside=0


    if not(inside) then begin
	if res gt 0 then begin
	    i=(i-1)>0
	    cs(i)=0
	    points(*,i+ns)=0
	    print,cs(where(cs)>0)
	end
	plots,[xd,xd],[yd-r+dsts(0),yd-r+dsts(1)],psym=-3,/data
	cursor,x,y,/up
	if (x gt r and x lt s(1)-r and y gt r and y lt s(2)-r) then inside=1 else inside=0
        if not(inside) then begin
	    device,set_graphics=3
	    return,cs(where(cs)>0)
	end
    end 
    
    dsts=i_distance(img,r,x,y)
    res=dsts(1)-dsts(0)
    if res gt 0 then begin
	cs(i)=res
	points(*,i+ns)=[x,x,y-r+dsts(0),y-r+dsts(1)]
	print,cs(where(cs)>0)
	i=i+1
	if i gt 999 then begin
	    device,set_graphics=3
	    return,cs(where(cs)>0)
	end
    end
    plots,[x,x],[y-r+dsts(0),y-r+dsts(1)],psym=-3,/data
;    plots,x,y,psym=7
    xd=x
    yd=y

end

device,set_graphics=3
device,/cursor_crosshair
end
