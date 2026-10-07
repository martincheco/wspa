function i_angle,mark=mark
;lets the user drag a line inside the actual win
;mark leaves the line in the window
    cursor,x1,y1,/down,/device
    device, set_graphics_function = 6; XOR graphics
    mbd=!mouse.button
    plots,[x1,x1],[y1,y1],/device,color=255
    x2d=x1
    y2d=y1
    mb=mbd
;    print,x1,y1
    repeat begin
	cursor,x2,y2,/change,/device
	if x2d ne x2 or y2d ne y2 then begin
	    plots,[x1,x2d],[y1,y2d],/device,color=255
	    plots,[x1,x2],[y1,y2],/device,color=255 
	    x2d=x2
	    y2d=y2    
	end
	
	mb=!mouse.button
	if mb ne mbd then $
	if mbd eq 0 and mb eq 1 then begin
	    mb=99 ;exit code
	end else begin
	    mbd=mb
	end
	
    endrep until mb eq 99
    
    plots,[x1,x2],[y1,y2],/device,color=255

    mbd=!mouse.button
    x3d=x2
    y3d=y2
    mb=mbd



    repeat begin
	cursor,x3,y3,/change,/device
	if x3d ne x3 or y3d ne y3 then begin
	    plots,[x1,x3d],[y1,y3d],/device,color=255
	    plots,[x1,x3],[y1,y3],/device,color=255 
	    x3d=x3
	    y3d=y3    
	end
	
	mb=!mouse.button
	if mb ne mbd then $
	if mbd eq 0 and mb eq 1 then begin
	    mb=99 ;exit code
	end else begin
	    mbd=mb
	end
	
    endrep until mb eq 99

    cursor,x3,y3,/change,/device

if not(keyword_set(mark)) then plots,[x1,x2],[y1,y2],/device,color=255

if not(keyword_set(mark)) then plots,[x1,x3d],[y1,y3d],/device,color=255   

;print,x1,y1,(x1^2+x2^2)^0.5

    device, set_graphics_function = 3; copy graphics

a=complex(x2-x1,y2-y1)
b=complex(x3d-x1,y3d-y1)

ang=imaginary(alog((b/abs(b))/(a/abs(a)))/!PI*180.)

return,ang
end
