function i_draw_line,mark=mark
;lets the user drag a line inside the actual win
;mark leaves the line in the window
    cursor,x1,y1,/down,/device
    device, set_graphics_function = 6; XOR graphics
    mbd=!mouse.button
    plots,[x1,x1],[y1,y1],/device
    x2d=x1
    y2d=y1
    mb=mbd
;    print,x1,y1
    repeat begin
	cursor,x2,y2,/change,/device
	if x2d ne x2 or y2d ne y2 then begin
	    plots,[x1,x2d],[y1,y2d],/device
	    plots,[x1,x2],[y1,y2],/device   
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

if not(keyword_set(mark)) then plots,[x1,x2],[y1,y2],/device   
;print,x1,y1,(x1^2+x2^2)^0.5

    device, set_graphics_function = 3; copy graphics

return,[x1,x2,y1,y2]
end