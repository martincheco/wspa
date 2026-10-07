function i_subtrplane,img,target_self=target_self
;interactive plane subtracting, e.g. invoked from quickview
;returns vector of two numbers, slopex and slopey
;target_self does not create a window and skips tvscl (can return coordinates out of img range!)

if not(keyword_Set(target_self)) then begin
    if n_elements(img) eq 0 then begin
	print,'nothing to do'
	return,[0,0,0,0]
    end
    
    s=size(img)
    window,/FREE,xs=s(1),ys=s(2)
    wno=!D.window
    ;tvscl,img
end

s=size(img)
maxrange=variance(img)^0.5
print,maxrange
slopex=0D
slopey=0D
imf=img
imf=bytscl(imf)
    imf(s(1)/2,*)=0
    imf(*,s(2)/2)=0
    tv,imf
repeat begin
    
    cursor,xc,yc,/up,/device
    if xc ge s(1) then begin
	exx=1
	goto,skip
    end $
    else exx=0
    xc=(xc>0)<s(1)
    yc=(yc>0)<s(2)
    incsx=((s(1)/2-xc))
    incsy=((s(2)/2-yc))
    if incsx ne 0D then incsx=(double(incsx)/s(1)*4.)^3
    if incsy ne 0D then incsy=(double(incsy)/s(2)*4.)^3
    print,incsx,incsy,slopex,slopey
    slopex=slopex+incsx
    slopey=slopey+incsy
    imf=subtrplane(img,slopex=slopex,slopey=slopey)
    imfb=bytscl(imf)
    imfb(s(1)/2,*)=0
    imfb(*,s(2)/2)=0
    tv,imfb
    plot,imf(s(1)/2,*),/noerase
    oplot,imf(*,s(2)/2)
    skip:
endrep until exx eq 1

    
    if not(keyword_Set(target_self)) then wdelete,wno
    return,[slopex,slopey]
end