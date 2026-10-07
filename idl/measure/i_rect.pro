function i_rect,img,target_self=target_self
;interactive rectangle draw, e.g. invoked from quickview
;returns vector of four numbers
;target_self does not create a window and skips tvscl (can return coordinates out of img range!)


if not(keyword_Set(target_self)) then begin
    if n_elements(img) eq 0 then begin
	print,'nothing to do'
	return,[0,0,0,0]
    end
    
    s=size(img)
    window,/FREE,xs=s(1),ys=s(2)
    wno=!D.window
    tvscl,img
end

    s=size(img)


    ;central point
    cursor,xc,yc,/down,/device

    device, set_graphics_function = 6; nastaveni XOR grafiky
    ms=!mouse.button
    if !mouse.button eq 4 then rect=1 else rect=0

    msd=ms
    
    x=xc
    y=yc
    xd=x
    yd=y
    x1=xc
    y1=yc
    x2=x1
    y2=y1
    
    repeat begin

	if (x NE xd) or (y NE yd) then begin
	    if x1 ne xc or y1 ne yc then plots, [x1, x2, x2, x1, x1,x2], [y1, y1, y2, y2, y1,y2], /device
	    dx=abs(xc-x)
	    dy=abs(yc-y)
	    if rect then begin
		dx=max([dx,dy])
		dy=dx
	    end
	    x1=xc-dx
	    y1=yc-dy
	    x2=xc+dx
	    y2=yc+dy
	    plots, [x1, x2, x2, x1, x1,x2], [y1, y1, y2, y2, y1,y2], /device
	end
	cursor,x,y,/change,/device

	ms=!mouse.button
	if ms ne msd then $
	if msd eq 0 and (ms eq 1 or ms eq 4) then begin
	    ms=99 ;exit code
	end else begin
	    msd=ms
	end

    ;print,ms,msd
    endrep until ms eq 99
    
    device, set_graphics_function = 3; obnoveni prekreslovaci grafiky
    if not(keyword_Set(target_self)) then wdelete,wno
    return,[x1,x2,y1,y2]
end