function filter_edit,img,filt,target_self=target_self,OFFS=offs,DOFFS=doffs

;allows edition of a filter, now works only on linux
;if img is specified, the process is interactive
;if wi is specified, is used as the window index where to draw

;default filter
if not(keyword_set(filt)) then filt={type:["none"],par1:[0],par2:[0],par3:[0]}

if (keyword_set(img)) then imf=filter(img,filt)
s=size(imf)

scrres=GET_SCREEN_SIZE(RESOLUTION=resolution)

first_pass=0

pid=-8 ; just for sure, in order not to kill init :)
filter_save,'tmpfilt',filt
newfilt=filter_load('tmpfilt')
message="CANCEL"


;interactive vs. uninteractive
if keyword_set(img) then $
begin
    ;edits filter in a temporary file
    spawn, "xterm -exec mc -e tmpfilt &",pid=pid
    ;print, pid

    repeat begin
	
	;in case its the first cycle
	if first_pass eq 0 then begin
	    
	    if (keyword_set(target_self)) then $
	        begin
		    wno=!D.window
		    dwx=!D.x_vsize
		    dwy=!D.y_vsize
		    ;dwx=dwx>0
		    ;dwy=dwy>0
		end else $
		begin
		    dwy=s(2)+20
		    dwx=s(1)
		    window,5,xs=dwx,ys=dwy,title='Filter edit - click image to refresh',$
		    ;xpos=!MOUSE.x,ypos=!MOUSE.y
		    
		    wno=!D.window
		    print,'window no:',wno
		    tvscl,imf
		end
	    first_pass=1
	end else begin
		newfilt=filter_load('tmpfilt')
		imf=filter(img,newfilt)
		sd=s
		s=size(imf)
		;print,"filter_edit debug: ",dwx,dwy
;		if wno ge 32 then begin
;		    wdelete,wno
;		    window,/FREE,xs=dwx,ys=dwy,title='Filter edit - click image to refresh',$
;		    xpos=offs(0),ypos=offs(1)
;		    wno=!D.window
;		end else window,wno,xs=s(1)+dwx,ys=s(2)+dwy,title='Filter edit - click image to refresh',$
;		    xpos=offs(0),ypos=offs(1)
		
;		end


		tvscl,imf
	end
	
	tv,intarr(s(1),20),0,s(2)
	tv,intarr(150,s(2)),s(1),0
	xyouts,3,s(2)+3,message,/device,charsize=1.2
	xyouts,s(1)+3,3,message,/device,charsize=1.2
    
	message="Save&Exit"
	cursor,x,y,/up,/device
	;device,get_window_position=offs
;	offs=offs-doffs
    endrep until y gt s(2) or x gt s(1)
    
    spawn,"kill "+string(pid+1)
    if not(keyword_set(target_self)) then wdelete,wno
end else $
begin
    ;edits filter in a temporary file
    spawn, "xterm -exec mc -e tmpfilt"
    newfilt=filter_load('tmpfilt')
end
spawn,'rm tmpfilt'


return,newfilt
end
