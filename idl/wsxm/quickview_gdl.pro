function gencomment,st,fctr,extended=extended

angle=getval(st.par,"Angle:","float");
ampsu=" "
voltsu=" "
volts=getval(st.par,"Topography Bias:","float",unit=voltsu)
amps=getval(st.par,"Set Point:","float",unit=ampsu)
;help,ampsu
xs=st.xsize*fctr(0)
ys=st.ysize*fctr(1)

date=getval(st.par,'Acquisition time:')
file=FILE_basename(getval(st.par,"Filename:"))
biascurrent="U = "+strtrim(string(volts,format='(I5)'),2)+voltsu+"  I = "+strtrim(string(amps,format='(F6.2)'),2)+ampsu
angle=strtrim(string(angle,format='(F03)'),2)
comments=(getval(st.par,"Comments:"))

xss=strtrim(string(xs,format='(F6.1)'),2)
yss=strtrim(string(ys,format='(F6.1)'),2)
runit=""
if st.runit ne "none" and st.runit ne "" then runit=st.runit

if not(keyword_set(extended)) then comm=xss+" x "+yss+runit+"!U2  !N"+biascurrent $
else comm="extended"
return,comm
end

pro quickview_gdl,pmdata,topofilt=topofilt,curfilt=curfilt,dump=dump,preprocess=preprocess,preselect=preselect
;filt general filter for topography
;curfilt - general filter for current
;dump(missing) - dumps everything automatically using the filters
;preprocess - makes the filtering before the viewing
;preselect - for omicron files, it is possible to choose only few channels, e.g. [Z,I]
;initial vars

heap_gc,/ptr
goldpalette,/pure
close,/all
minsize=600
charsz=1.
vtoff=2
htoff=5
lineh=20
menu=["Exit","", "Filter","Profile","Histogram","Save profile","Angle","Hex. drift","Subtrplane","Crop","Dump all PNG","Export PNG","Save WSXM","Palette","Scale on/off","Mark","Curves"]
menuitems=n_elements(menu)
menuw=90

scrres = GET_SCREEN_SIZE(RESOL=resol)
;posoffs=scrres/2-[minsize,minsize]/2
posoffs=[1,1]

window,0,xsize=minsize+menuw,ysize=minsize;,xpos=posoffs(0),ypos=posoffs(1)
xyouts,vtoff,htoff,'Welcome! Starting...',charsize=charsz,/device;,font=1

;dposoffs=[0,0]
;device,get_window_position=dposoffs

;dposoffs=dposoffs-posoffs ;calculating the correction
;posoffs=posoffs-dposoffs

pfl={z:-1} ;profile does not exist yet


;menu
help,minsize
window,4,xs=menuw,ys=round(minsize),/pixmap
	;tv,intarr(menuw,yd),xd,0 ;just a clear
	for u=0,menuitems-1 do begin
	    plots,[0,menuw],[(u+1)*lineh,(u+1)*lineh],/device
	    xyouts,0+htoff,u*lineh+vtoff,menu(u),/device,charsize=charsz;,font=1
	end
	    plots,[0,0],[0,minsize],/device
	tvmenu=tvrd(0)
wdelete,4
wset,0



;load data
if not(keyword_set(pmdata)) then pmdata=mloadwsxm(preselect=preselect)
n=n_elements(pmdata)
if not(ptr_valid(pmdata(0))) or n eq 0 then return
;help,n
;sort by date
print,"Sorting by date"
dts=strarr(n)
for i=0,n-1 do begin
    dts(i)=getval((*pmdata(i)).par,'Acquisition time:')
end
pmdata=pmdata(sort(dts))
dts=dts(sort(dts))


device,retain=2
DEVICE, DECOMPOSED = 0 
;setcurs

if not(keyword_set(topofilt)) then topofilt={type:["subtrplane","rowsequal","histxpand"],par1:[0.,0.,0.],par2:[0.,0.,0],par3:[0.,0.,0]}
if not(keyword_set(curfilt)) then curfilt={type:["histxpand"],par1:[0.],par2:[0.],par3:[0.]}
if not(keyword_set(curfiltneg)) then curfiltneg={type:["invert","histxpand"],par1:[0.,0.],par2:[0.,0.],par3:[0.,0.]}



filt=ptrarr(n)
topo=intarr(n)
bias=fltarr(n)
acqchan=strarr(n)
filtname=strarr(n)
filename=strarr(n)
marked=bytarr(n)
scale_on=0

for i=0,n-1 do begin
    filename(i)=getval((*pmdata(i)).par,"Filename:")
    bias(i)=getval((*pmdata(i)).par,"Topography Bias:","float")
    filtname(i)=filename(i)+'.flt'
    acqchan(i)=(getval((*pmdata(i)).par,"Acquisition channel:"))
    
    if file_test(filtname(i)) then $
	filt(i)=ptr_new(filter_load(filtname(i))) $
    else $
	case acqchan(i) of
	    "Z": filt(i)=ptr_new(topofilt)
	"Topography": filt(i)=ptr_new(topofilt)
	    "I": if bias(i) lt 0 then filt(i)=ptr_new(curfiltneg) else filt(i)=ptr_new(curfilt)
	    "Current": if bias(i) lt 0 then filt(i)=ptr_new(curfiltneg) else filt(i)=ptr_new(curfilt)
	    else: filt(i)=ptr_new(curfilt)
	endcase
end	

;print,file_dirname(filename(0))+"/useful.lst"
    
    if file_test(file_dirname(filename(0))+"/useful.lst") then begin
	useful=loadlist(file_dirname(filename(0))+"/useful.lst")
	;print,useful
	buseful=file_basename(useful)
	;print,buseful
	for i=0,n-1 do begin
	    wwb=where(buseful eq file_basename(filename(i)))
	    if wwb(0) ne -1 then marked(i)=1
	    ;print,buseful(where(buseful eq file_basename(filename(i)))),filename(i)
	end
    end

IF KEYWORD_SET(preprocess) then begin
    print,'Preprocessing...'
    
    npmdata=ptrarr(n)
    for i=0,n-1 do begin
	current= (getval((*pmdata(i)).par,"Acquisition channel:")) eq "Current"
	imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr)
	temp={img:imf,xsize:fctr(0)*(*pmdata(i)).xsize,ysize:fctr(1)*(*pmdata(i)).ysize}
	npmdata(i)=ptr_new(temp)
    end

end

xd=0
yd=0
i=0
zom=1.
maxsize=1000


repeat begin ; menu loop
    
    repeat begin ; image loop
    
;    loopstart:
    
	acqchan=(getval((*pmdata(i)).par,"Acquisition channel:"))
	angle=getval((*pmdata(i)).par,"Angle:","float")
	ampsu=" "
	voltsu=" "
	volts=getval((*pmdata(i)).par,"Topography Bias:","float",unit=voltsu);
	amps=getval((*pmdata(i)).par,"Set Point:","float",unit=ampsu);
	fctr=[1.,1.]
	if not(keyword_set(preprocess)) then begin
	    imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr) 
	    print,"fctr",fctr
	    xs=(*pmdata(i)).xsize*fctr(0)
	    ys=(*pmdata(i)).ysize*fctr(1)
	end $
	    else $ 
	begin
	    imf=(*npmdata(i)).img
	    xs=(*npmdata(i)).xsize
	    ys=(*npmdata(i)).ysize
	end
	
	s=size(imf)
	

	print,"----------------------------------------"
	print,"Date&time:",dts(i)
	print,FILE_basename(filename(i))
	print,"Channel: ",acqchan
	print,"U = "+strtrim(string(volts),2)+voltsu+"  I = "+strtrim(string(amps),2)+ampsu
	print,"Size: "+strtrim(string(xs),2)+" x "+strtrim(string(ys),2)+",  Angle:"+strtrim(string(angle),2)
	print,"Comments: "+(getval((*pmdata(i)).par,"Comments:"))

;	if s(1) lt minsize or s(2) lt minsize then begin
;	    print,'clearing'
;	    tv,bytarr(minsize,minsize)
;	end else print,'not clearing'
	
	if s(1) ne xd or s(2) ne yd then begin
	    xd=(s(1)>minsize)<maxsize
	    yd=(s(2)>minsize)<maxsize
	    ;print,xd,yd
	    xps=posoffs(0)
	    yps=posoffs(1)
	    window,0,xsize=(xd>minsize)+menuw,ysize=(yd>minsize),title="Quick WSxM viewer 1.0"

;window,0,xsize=(xd>minsize)+menuw,ysize=(yd>minsize),title="Quick WSxM viewer 1.0",xpos=xps,ypos=yps
	    ;device,get_window_position=posoffs
	    ;posoffs=posoffs-dposoffs
	end
    print,s(1),s(2)
    
    redraw:
	print,"redrawing"
	wset,0
	if finite(imf(0)) then begin
	    help,imf
	    help,imfd
	    help,finite(imf)
	    if zom ne 1.0 then begin
		imfd=congrid(imf(xc-s(1)/zm:xc+s(1)/zm,yc-s(2)/zm:yc+s(2)/zm),s(1),s(2),cubic=-0.5)
		tvscl,imfd
	    end else begin
		imfd=imf
		tvscl,imf
	    end
	    
	    
	end
	
	if scale_on eq 1 then begin
	    xyouts,0,0,gencomment((*pmdata(i)),fctr/zom),charsize=s(1)*2./512.,/device;,font=1
	end

    menu:
	print,"menu"
	tv,tvmenu,xd,0
	
	if marked(i) eq 1 then $
	    begin
		tv,bytarr(16,16)+255,xd+1,yd-16
		tv,bytarr(12,12),2+xd+1,2+yd-16
	    end $
	else $
		tv,bytarr(16,16),xd+1,yd-16
	
	print,"everything drawn"

    cursortest:
	    wset,0
	    cursor,x,y,/up,/device
	    ;print,"CLICK"
	    
	    if !mouse.button eq 4 and x lt xd-1 and y lt yd-1 and x gt 0 and y gt 0 then begin
		if zom ne 1. then zom=1. else begin 
		    zom=4.
		    zm=zom*2.
		    xc=(x>(s(1)/zm))<((zm-1)*s(1)/zm-1)
		    yc=(y>(s(2)/zm))<((zm-1)*s(2)/zm-1)
		    print,"Coordinates:",xc,yc    
		end
		goto,redraw
	    end
	    
	    if !mouse.button then if y lt (yd>minsize)-1 and x lt (xd>minsize)-1 then begin
		if zom ne 1. then begin
		    zom=1.
		    goto,redraw
		    end $
			else $
		    if x lt (xd>minsize)/2 then i=(i-1)>0 $
		    	    else $
				if x gt (xd>minsize)/2 then i=(i+1)<(n-1)
			
	    end 

	    ;device,get_window_position=posoffs
	    ;posoffs=posoffs-dposoffs

    endrep until x gt xd>minsize and !mouse.button ne 4
	
menuindex=(y/lineh)<(n_elements(menu)-1)
case strtrim(menu(menuindex),2) of

    "Crop":	begin
		    temp=*filt(i)

		    cp=long(i_rect(/target_self))
		    cp=cp>[0,0,0,0]
		    cp=cp<[s(1)-1,s(1)-1,s(2)-1,s(2)-1]
		    print,cp
		    ntemp={type:[temp.type,"cropx"],par1:[temp.par1,cp(0)*10000.+cp(1)],par2:[temp.par2,cp(3)+10000.*cp(2)],par3:[temp.par3,0.]}
		    filt(i)=ptr_new(ntemp)
		    imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr)
		    
		    if (keyword_set(preprocess)) then $
		    begin
			temp={img:imf,xsize:fctr(0)*(*pmdata(i)).xsize,ysize:fctr(1)*(*pmdata(i)).ysize}
			npmdata(i)=ptr_new(temp)
		    end
		    
		    filter_save,filtname(i),*filt(i)

		end

    "Subtrplane":begin
		    temp=*filt(i)

		    slope=(i_subtrplane(imf,/target_self))
		    ntemp={type:[temp.type,"subtrplane"],par1:[temp.par1,slope(0)],par2:[temp.par2,slope(1)],par3:[temp.par3,0.]}
		    filt(i)=ptr_new(ntemp)
		    imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr)
		    if (keyword_set(preprocess)) then $
		    begin
			temp={img:imf,xsize:fctr(0)*(*pmdata(i)).xsize,ysize:fctr(1)*(*pmdata(i)).ysize}
			npmdata(i)=ptr_new(temp)
		    end
		    
		    filter_save,filtname(i),*filt(i)

		end

    
    "Hex. drift":	begin
		    ;hexagonal
		    r3=3.^0.5/2.
		    matrix=[[r3,0.5],[r3,-0.5]]
		    temp=*filt(i)
		    drift=0
		    imf=unidrift(imf,matrix,drift=drift,/target_self)
		    ;print,"drift returned",drift
		    
		    ntemp={type:[temp.type,"drift"],par1:[temp.par1,drift(0)],par2:[temp.par2,drift(1)],par3:[temp.par3,0.]}
		    filt(i)=ptr_new(ntemp)
		    imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr)
		    
		    if (keyword_set(preprocess)) then $
		    begin
			temp={img:imf,xsize:fctr(0)*(*pmdata(i)).xsize,ysize:fctr(1)*(*pmdata(i)).ysize}
			npmdata(i)=ptr_new(temp)
		    end
		    
		    filter_save,filtname(i),*filt(i)
		    
		end


    "Filter": 	begin
		    temp=filter_edit((*pmdata(i)).img,*filt(i),/target_self);,offs=posoffs,doffs=dposoffs)
		    filt(i)=ptr_new(temp)
		    if (keyword_set(preprocess)) then $
		    begin
			imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr)
			temp={img:imf,xsize:fctr(0)*(*pmdata(i)).xsize,ysize:fctr(1)*(*pmdata(i)).ysize}
			npmdata(i)=ptr_new(temp)
		    end
		    ;saving filters
		    filter_save,filtname(i),*filt(i)
		    wset,0
		end

    "Exit": print,"Exiting.."

    "Palette": 	begin
		    xloadct,/block
		    ;if finite(imf(0)) then tv,tvscaled(imf)
		end

    "Export PNG":$
	begin 
	    pngf=filename(i)
	    pngfd=file_dirname(pngf)
	    pngfb=file_basename(pngf)
	    pngfb=pngfb+'.png'
	    cd,pngfd,current=fd_old
	    fnm=dialog_pickfile(file=pngfb,/write,/overwrite_prompt)
	    window,4,xs=s(1),ys=s(2)+scale_on*s(1)*20./512.,/pixmap
	    tv,tvscaled(imf),0,scale_on*s(1)*20./512.
	    if scale_on then xyouts,0,0,gencomment((*pmdata(i)),fctr),charsize=s(1)*2./512.,/device
	    
	    ;device,font=1
	    imp=tvrd(0,0,s(1),s(2),true=1)
	    wdelete,4
	    if fnm ne "" then write_png,fnm,imp else print,"Invalid filename!"
	    cd,fd_old
	end

    "Dump all PNG":$
	begin 
	    wm=where(marked)
	    if wm(0) eq -1 then goto,cursortest
	    pngf=filename(wm(0))
	    pngfd=file_dirname(pngf)
	    cd,pngfd,current=fd_old
	    fnd=dialog_pickfile(path=pngfd,/dir)
	    if fnd eq "" then goto,cursortest
	    print,"Writing PNG files:"
	    for ii=0,n-1 do begin
		if marked(ii) eq 1 then begin
		    pngf=filename(ii)
		    pngfb=file_basename(pngf)
		    imf=filter((*pmdata(ii)).img,*filt(ii),fctr=fctr)
		    sz=size(imf)
		    window,4,xs=sz(1),ys=sz(2)+scale_on*sz(1)*20./512.,/pixmap
		    tv,tvscaled(imf),0,scale_on*sz(1)*20./512.
		    if scale_on then xyouts,0,0,gencomment((*pmdata(ii)),fctr),charsize=sz(1)*2./512.,/device;,font=1
		    imp=tvrd(0,0,sz(1),sz(2),true=1)
		    wdelete,4
		    print,fnd+"/"+pngfb+".png"
		    write_png,fnd+"/"+pngfb+".png",imp
		end
	    end
	    print,"Dump finished."
	    cd,fd_old
	end

    "Save WSXM":$
	begin 
	    wf=filename(i)
	    wfd=file_dirname(wf)
	    wfb=file_basename(wf)
	    cd,wfd,current=wd_old
	    fnm=dialog_pickfile(file="mod_"+wfb,/write,/overwrite_prompt)
	    if fnm ne "" then begin
	    imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr) 
	    xs=(*pmdata(i)).xsize*fctr(0)
	    ys=(*pmdata(i)).ysize*fctr(1)

		savedata=(*pmdata(i))
		savedata.xsize=xs
		savedata.ysize=ys
		savewsxm,refitwsxm(savedata,imf),fnm
	    end
	    
	    cd,wd_old
	end
    
    "Scale on/off": begin
		if scale_on eq 1 then scale_on=0 else scale_on=1 
		goto, redraw
	    end
    
    "Profile":	begin
		    pfl=mprofile(imfd,/manual,/mark,latscl=xs/zom)
		    ;help,pfl,/struct
		    if pfl.z(0) ne -1 then begin
			xps=posoffs(0)-300
			yps=0
			window,2,xs=600,ys=200,title="Profile",xpos=xps,ypos=yps
			plot,pfl.r,pfl.z,xstyle=1,ystyle=2,xtitle=(*pmdata(i)).runit,ytitle=(*pmdata(i)).zunit
			;wset,0 ;not necessary
			pflf=filename(i)
			pflfd=file_dirname(pflf)
			pflfb=file_basename(pflf)
			pflfb=pflfb+'.dat'
			print,"ANGLE:",pfl.angle,";   DISTANCE:",max((pfl.r))
		    end
		    goto,cursortest ;brutal method
		end

    "Histogram":begin
		    print,xs,ys
		    nbs=(s(1)*s(2))^0.5
		    hist = HISTOGRAM(imfd,nbins=nbs)
		    bins = DINDGEN(N_ELEMENTS(hist))/nbs*(MAX(imfd)-MIN(imfd)) + MIN(imfd) 
			xps=posoffs(0)-300
			yps=0
			window,2,xs=600,ys=200,title="Histogram",xpos=xps,ypos=yps
			plot,bins,hist,xtitle=(*pmdata(i)).zunit,ytitle="Density", xstyle=1,ystyle=1
			;wset,0 ;not necessary
			print,"MIN",min(imfd)
			print,"MAX",max(imfd)
			print,"AVG",mean(imfd)
			print,"RMS",stddev(imfd)
			goto,cursortest ;brutal method
		end


    "Angle":	begin
			ang=i_angle(/mark)
			print,"ANGLE:",ang
		    goto,cursortest ;brutal method
		end


    "Save profile": $
		begin
		    if pfl.z(0) ne -1 then begin
			cd,pflfd,current=fd_old
			fnm=dialog_pickfile(file=pflfb,/write,/overwrite_prompt)
			if fnm ne "" then begin
			    openw,1,fnm
			    for ii=0,n_elements(pfl.z)-1 do printf,1,pfl.r(ii),pfl.z(ii)
			    close,1
			end else print,"Invalid filename!"
			cd,fd_old
		    end
		    goto,cursortest ;brutal method
;		    print,"ANGLE: ",i_angle(/mark)
;		    goto,cursortest ;brutal method
		end

    "Mark": begin
		marked(i)=(marked(i)+1) mod 2
		print,marked(i)
		w=where(marked ne 0)
		if w(0) ne -1 then uselist=file_basename(filename(w)) else uselist=""
		savelist,file_dirname(filtname(0))+"/useful.lst",uselist
		goto,menu
    	    end

    "Curves": begin
		qbender,conversion=[xs,s(1)/xs,ys,s(2)/ys]
		goto,cursortest ;brutal method
    	    end


    else: begin
	    print,"Unassociated"
	    goto,cursortest ;brute method
	end

endcase

;device,get_window_position=posoffs
;posoffs=posoffs-dposoffs

	
endrep until menuindex eq 0 ;exit
    
    print,file_dirname(filename(i))
    ptr_free,pmdata
    if keyword_set(npmdata) then ptr_free,npmdata
    wdelete,0
    ;wdelete,1
    
end


