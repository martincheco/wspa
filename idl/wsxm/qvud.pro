function palgen,filt,wc,ro=ro,bo=bo,go=go
;takes color pallettes specified in filter at index wc and returns as a structure

;getting palette number, inversions and gamma factors
	pal1=(fix((filt).par1[wc])<34)>(-34)
	gm1=abs((filt).par1[wc]-fix((filt).par1[wc]))
	l=((abs((filt).par2[wc] mod 1)>0.)<1.)
	sw=(abs((filt).par2[wc]-l))<50
	l=round((l*255>0))<255
	;help,l
	pal2=(fix((filt).par3[wc])<34)>(-34)
	gm2=abs((filt).par3[wc]-fix((filt).par3[wc]))
	if gm2 lt 0.0001 then gm2=0.5
	if gm1 lt 0.0001 then gm1=0.5
	gm2=(gm2>0.01)<0.99
	gm1=(gm1>0.01)<0.99
	i1=sgn(pal1)
	i2=sgn(pal2)
	ii1=sgn((filt).par1[wc])
	ii2=sgn((filt).par3[wc])


;original values, taking as default for pal1 and pal2
	rr=ro
	gg=go
	bb=bo
	r2=ro
	g2=go
	b2=bo    
;loading palettes
if pal1 ne 0 then begin
		if abs(pal1) eq 3 then goldpalette2,r=rr,g=gg,b=bb,/nomod else $
			if abs(pal1) eq 27 then magma,r=rr,g=gg,b=bb,/nomod else $
			if abs(pal1) eq 28 then plasma,r=rr,g=gg,b=bb,/nomod else $
			if abs(pal1) eq 29 then inferno,r=rr,g=gg,b=bb,/nomod else $
			if abs(pal1) eq 25 then owpalette,r=rr,g=gg,b=bb,/nomod else $
			if abs(pal1) eq 24 then rwpalette,r=rr,g=gg,b=bb,/nomod else $
			if abs(pal1) eq 23 then bwpalette,r=rr,g=gg,b=bb,/nomod else $
			if abs(pal1) eq 34 then drwpalette,r=rr,g=gg,b=bb,/nomod else $
			if abs(pal1) eq 33 then dbwpalette,r=rr,g=gg,b=bb,/nomod else $
			if abs(pal1) eq 30 then dgwpalette,r=rr,g=gg,b=bb,/nomod else $
			if abs(pal1) eq 31 then dowpalette,r=rr,g=gg,b=bb,/nomod else $
			if abs(pal1) eq 15 then bluepalette,r=rr,g=gg,b=bb,/nomod else $
			if abs(pal1) eq 13 then redpalette,r=rr,g=gg,b=bb,/nomod else begin
				loadct,abs(pal1)-1 
				tvlct,rr,gg,bb,/get
			end
end
if pal2 ne 0 then begin
		if abs(pal2) eq 3 then goldpalette2,r=r2,g=g2,b=b2,/nomod else $
			if abs(pal2) eq 27 then magma,r=r2,g=g2,b=b2,/nomod else $
			if abs(pal2) eq 28 then plasma,r=r2,g=g2,b=b2,/nomod else $
			if abs(pal2) eq 29 then inferno,r=r2,g=g2,b=b2,/nomod else $
			if abs(pal2) eq 25 then owpalette,r=r2,g=g2,b=b2,/nomod else $
			if abs(pal2) eq 24 then rwpalette,r=r2,g=g2,b=b2,/nomod else $
			if abs(pal2) eq 23 then bwpalette,r=r2,g=g2,b=b2,/nomod else $
			if abs(pal2) eq 34 then drwpalette,r=r2,g=g2,b=b2,/nomod else $
			if abs(pal2) eq 33 then dbwpalette,r=r2,g=g2,b=b2,/nomod else $
			if abs(pal2) eq 30 then dgwpalette,r=r2,g=g2,b=b2,/nomod else $
			if abs(pal2) eq 31 then dowpalette,r=r2,g=g2,b=b2,/nomod else $
			if abs(pal2) eq 15 then bluepalette,r=r2,g=g2,b=b2,/nomod else $
			if abs(pal2) eq 13 then redpalette,r=r2,g=g2,b=b2,/nomod else begin
				loadct,abs(pal2)-1 
				tvlct,r2,g2,b2,/get
			end
end
;inversion
if ii1 lt 0 then begin 
	rr=reverse(rr)
	gg=reverse(gg)
	bb=reverse(bb)
end
if ii2 lt 0 then begin 
	r2=reverse(r2)
	g2=reverse(g2)
	b2=reverse(b2)
end
;gamma corrections
if gm1 ne 0.5 then begin
	gm=(0.5/gm1)^1.5
	xgm=findgen(256)/255.
	xgmod=xgm^gm
	rr=round(interpol(rr,xgm,xgmod))
	gg=round(interpol(gg,xgm,xgmod))
	bb=round(interpol(bb,xgm,xgmod))
end

if gm2 ne 0.5 then begin
	gm=(0.5/gm2)^1.5
	xgm=findgen(256)/255.
	xgmod=xgm^gm
	r2=round(interpol(r2,xgm,xgmod))
	g2=round(interpol(g2,xgm,xgmod))
	b2=round(interpol(b2,xgm,xgmod))
end




if l gt 0 AND l lt 255 then begin
    w1=round(findgen(l)*255./l)<255
    w2=round(findgen(256.-l)*255./(256.-l))<255
    rr(0:l-1)=rr(w1)
    gg(0:l-1)=gg(w1)
    bb(0:l-1)=bb(w1)
    rr(l:255)=r2(w2)
    gg(l:255)=g2(w2)
    bb(l:255)=b2(w2)
end 

;if l gt 0 AND l lt 255 then begin
;print,l
;    w1=findgen(l-1)*255./(l-1)
;    w2=findgen(256.-l-1)*255./(256.-l-1)
;    wi=findgen(256)
;    r0=rr(255)
;    g0=gg(255)
;    b0=bb(255)
;    rr(0:l-2)=round(interpol(rr,wi,w1))
;    gg(0:l-2)=round(interpol(gg,wi,w1))
;    bb(0:l-2)=round(interpol(bb,wi,w1))
;    rr(l+1:255)=round(interpol(r2,wi,w2))
;    gg(l+1:255)=round(interpol(g2,wi,w2))
;    bb(l+1:255)=round(interpol(b2,wi,w2))
;    rr(l-1)=r0
;    bb(l-1)=b0
;    gg(l-1)=g0
;    rr(l)=r2(0)
;    bb(l)=b2(0)
;    gg(l)=g2(0)
;end 




;overlap of the palettes
if sw ge 2 then begin
l1=((l-sw)>0)<255
l2=((l+sw-1)>0)<255
;print,rr(l1:l2)

rrs=smooth(rr,sw,/edge_truncate)
ggs=smooth(gg,sw,/edge_truncate)
bbs=smooth(bb,sw,/edge_truncate)
rr(l1:l2)=rrs(l1:l2)
gg(l1:l2)=ggs(l1:l2)
bb(l1:l2)=bbs(l1:l2)
end

return,{r:rr,g:gg,b:bb}
end


function sclgen,filt,i,imf,imxsize
	lngth=(filt.par1(i))
	s=size(imf)
        return,mkscl(imf,s(1)*lngth/imxsize)
end



function gridgen,filt,i,imf,dots=dots
	ax1=(decomp(filt.par1(i)))
        ax2=(decomp(filt.par2(i)))
        ax3=(decomp(filt.par3(i)))
        x0=real_part(ax1)
        a1=real_part(ax2)/10.
        r1=real_part(ax3)/10.
        y0=imaginary(ax1)
        a2=imaginary(ax2)/10.
        r2=imaginary(ax3)/10.
        print,x0,y0,r1,a1,r2,a2
        if not(keyword_set(dots)) then return,grids(imf,x0,y0,r1,a1,r2,a2,dim=15,/circ,/unrel,/autocol) else return,grids(imf,x0,y0,r1,a1,r2,a2,dim=50,/unrel,/dots) 

end



function gencomment,st,fctr,extended=extended

angle=getval(st.par,"Scan angle:","float");
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
yscandir=getval(st.par,'Y scanning direction:')
comments=(getval(st.par,"Comments:"))

xss=strtrim(string(xs,format='(F6.1)'),2)
yss=strtrim(string(ys,format='(F6.1)'),2)
runit=""
if st.runit ne "none" and st.runit ne "" then runit=st.runit

if not(keyword_set(extended)) then comm=xss+" x "+yss+runit+"!U2  !N"+biascurrent $
else comm="extended"
return,comm
end

common wspa_serverpath, serverpath

; Checks whether raw_file belongs to a dataset directory marked by .wspa_localdir
function is_local_dir_gdl, raw_file
    common wspa_serverpath, serverpath
    if n_elements(raw_file) eq 0 then return, 0
    clean_path = repstr(repstr(raw_file, '\ ', ' '), '\', '/')
    if n_elements(serverpath) ne 0 then if serverpath ne '' then if strmid(clean_path, 0, 1) ne '/' then clean_path = serverpath + '/' + clean_path

    dir = file_dirname(clean_path)
    while dir ne '' and dir ne '.' and dir ne '/' do begin
        if file_test(dir + '/.wspa_localdir') then return, 1
        parent = file_dirname(dir)
        if parent eq dir then break
        dir = parent
    endwhile
    return, 0
end

; Resolves filter file path (.flt): in-place if local dataset, shadow directory otherwise
function get_meta_path_gdl, raw_file, session_dir, for_write=for_write
    common wspa_serverpath, serverpath
    if n_elements(raw_file) eq 0 then return, ''
    clean_fn = repstr(repstr(raw_file, '\ ', ' '), '\', '/')
    if n_elements(serverpath) ne 0 then if serverpath ne '' then if strmid(clean_fn, 0, 1) ne '/' then clean_fn = serverpath + '/' + clean_fn

    if is_local_dir_gdl(clean_fn) then return, clean_fn + '.flt'

    username = 'admin'
    if keyword_set(session_dir) then begin
        u_parts = strsplit(session_dir, '/', /extract)
        for k = 0, n_elements(u_parts)-1 do begin
            if u_parts(k) eq 'users' and k+1 lt n_elements(u_parts) then username = u_parts(k+1)
        endfor
    endif

    p_data = strpos(clean_fn, 'data/')
    if p_data ne -1 then rel_path = strmid(clean_fn, p_data + 5) else rel_path = file_basename(clean_fn)

    prefix = ''
    if n_elements(serverpath) ne 0 then if serverpath ne '' then prefix = serverpath + '/'

    shadow_file = prefix + 'users/' + username + '/shadow/' + rel_path + '.flt'
    shadow_dir = file_dirname(shadow_file)
    if not file_test(shadow_dir) then file_mkdir, shadow_dir

    return, shadow_file
end

pro qvud,f,preprocess=preprocess
common wspa_serverpath, serverpath

t0_start = systime(1)
help,!GDL,/struct


cmdargs=command_line_args() ;read args from the launcher
if n_elements(cmdargs) ge 2 then serverpath=cmdargs(1) else serverpath=file_dirname(file_dirname(file_dirname(filepath('qvud.pro'))))
print,'CMDARGS: ',cmdargs
;preventive cleanup
heap_gc,/ptr,/verbose
goldpalette,r=r,g=g,b=b,/pure
;tvlct,r,g,b,/get
close,/all

;temporary
if keyword_set(f) then begin
print,"list of files obtained: ",f
f=loadlist(f)
;help,f
end else $
begin
print,"no input data specified"
exit
end


;load data

print,'*********File loading***********'
t0_fileload = systime(1)

;for the files that have spaces (handled natively by GDL)
nf=n_elements(f)
;for i=0,nf-1 do begin
;    f(i)=strjoin(strsplit(f(i), ' ', /extract), '\ ')
;end

if not(keyword_set(pmdata)) then pmdata=mloadwsxm(f)
n=n_elements(pmdata)
if not(ptr_valid(pmdata(0))) or n eq 0 then return
;help,n
;sort by date
print,"Sorting by date"
dts=strarr(n)
dur=fltarr(n)

for i=0,n-1 do begin
    dts(i)=getval((*pmdata(i)).par,'Acquisition time:')
end

mgsrt=mg_sort(dts)
pmdata=pmdata(mgsrt)
dts=dts(mgsrt)
t1_fileload = systime(1)


;predefined filters
;if not(keyword_set(topofilt)) then topofilt={type:["subtrplane","",""],par1:[0.,0.,0.],par2:[0.,0.,0],par3:[0.,0.,0]}
if not(keyword_set(topofilt)) then topofilt={type:[""],par1:[0.],par2:[0.],par3:[0.]}
if not(keyword_set(curfilt)) then curfilt={type:[""],par1:[0.],par2:[0.],par3:[0.]}
if not(keyword_set(curfiltneg)) then curfiltneg={type:["invert",""],par1:[0.,0.],par2:[0.,0.],par3:[0.,0.]}
if not(keyword_set(freqfilt)) then freqfilt={type:["color"],par1:[1.],par2:[0.],par3:[0.]}


filt=ptrarr(n)
topo=intarr(n)
bias=fltarr(n)
acqchan=strarr(n)
filtname=strarr(n)
filename=strarr(n)
bfname=strarr(n)
yscandir=strarr(n)
xscandir=strarr(n)

marked=bytarr(n)
scale_on=0
;cretaing scale and histogram bkg
hi=indgen(256)
sclimg=intarr(256,15)
histimg=intarr(256,50)



for i=0,14 do sclimg(*,i)=hi

print,'*********Filter loading***********'
for i=0,n-1 do begin
    par_arr = (*pmdata(i)).par
    raw_fn = getval(par_arr,"Filename:")
    if strmid(raw_fn, 0, 1) ne '/' and strpos(raw_fn, '/') eq -1 and strpos(raw_fn, '\') eq -1 then begin
        src_dir = file_dirname(f(0))
        filename(i) = src_dir + '/' + raw_fn
    end else begin
        filename(i) = raw_fn
    endelse
    bias(i)=getval(par_arr,"Topography Bias:","float")
    filtname(i)=get_meta_path_gdl(filename(i), cmdargs(0))
    xscandir(i)=getval(par_arr,'X scanning direction:')
    yscandir(i)=getval(par_arr,'Y scanning direction:')
    acqchan(i)=(getval(par_arr,"Acquisition channel:"))
    dur(i)=getval(par_arr,'Duration:','float')

    ffff={type:["none"],par1:[0],par2:[0],par3:[0]}
    has_flt = file_test(filtname(i))
    ;print,"Filtname: "+filtname(i)
    ;help,has_flt
    if has_flt then begin
	ffff=filter_load(filtname(i))
	;print,ffff
	filt(i)=ptr_new(ffff)
    end else begin
	if strmatch(acqchan(i),'*freq*',/fold) or strmatch(acqchan(i),'*df*',/fold) or strmatch(acqchan(i),'*shift*',/fold) then begin
	    filt(i)=ptr_new(freqfilt)
	end else case acqchan(i) of
	    "Z": filt(i)=ptr_new(topofilt)
	    "Topography": filt(i)=ptr_new(topofilt)
	    "I": if bias(i) lt 0 then filt(i)=ptr_new(curfiltneg) else filt(i)=ptr_new(curfilt)
	    "Current": if bias(i) lt 0 then filt(i)=ptr_new(curfiltneg) else filt(i)=ptr_new(curfilt)
	    else: filt(i)=ptr_new(curfilt)
	endcase
    end
end

print,'*********Writing channel files***********'
openw,1,'chan.dat'
openw,2,'acqchan.dat'
openw,3,'imgoffs.dat',width=2000
for i=0,n-1 do begin
    par_arr = (*pmdata(i)).par
    printf,1,filename(i)
    printf,2,acqchan(i)+" "+yscandir(i)+" "+xscandir(i)
    xo=getval(par_arr,"X Offset:",'float')
    yo=getval(par_arr,"Y Offset:",'float')
    sxize=getval(par_arr,"X Amplitude:",'float')
    syize=getval(par_arr,"Y Amplitude:",'float')
    angl=getval(par_arr,"Scan angle:","float")
    lout = strtrim(string(i),2)+';'+filename(i)+';'+acqchan(i)+';'+strtrim(string(xo,format='(E16.8)'),2)+';'+strtrim(string(yo,format='(E16.8)'),2)+';'+strtrim(string(sxize,format='(E16.8)'),2)+';'+strtrim(string(syize,format='(E16.8)'),2)+';'+strtrim(string(angl,format='(E16.8)'),2)+';'+dts(i)
    printf,3,lout
    bfnamex=file_basename(filename(i))
    bfnamex=strsplit(bfnamex,'.',/extract)
    nbfn=n_elements(bfnamex)
    if nbfn eq 1 or nbfn eq 2 then bfname[i]=bfnamex[0] ;omicron and other
    if nbfn ge 3 then bfname[i]=strjoin(bfnamex[0:(nbfn-3)],'.') ;nanonis, nanotec
    if nbfn eq 3 then if bfnamex[2] eq 'dat' then bfname[i]=strjoin(bfnamex[0:1],'.')
end
close,1
close,2
close,3

;print,bfname

print,'*********Useful list loading***********'

;print,file_dirname(filename(0))+"/useful.lst"

    if file_test(file_dirname(filename(0))+"/useful.lst") then begin
	useful=loadlist(file_dirname(filename(0))+"/useful.lst")
	;help,useful

	buseful=file_basename(useful)
	;help,buseful
	;help,buseful
	;help,filename

	if 1 eq 0 then for kl=0,n-1 do begin
		wb=where(buseful eq file_basename(filename(kl)))
		if wb(0) ne -1 then marked(kl)=1
	end
    end


IF KEYWORD_SET(preprocess) then begin
print,'*********Preprocessing***********'
    t0_prep = systime(1)
    voidimg=intarr(3,8,8)+255*200
	voidimg(0,*,*)=voidimg(0,*,*)*0
	voidimg(1,*,*)=voidimg(1,*,*)*0

    write_png,'imvoid.png',voidimg ; special empty image for flat channels, to improve speed
    npmdata=ptrarr(n)
    for i=0,n-1 do begin
	print,'processing image '+strtrim(string(i+1),2)+' of '+strtrim(string(n),2)
	ftype=(*filt(i)).type
	;print,ftype
	;help,ftype
	if ftype(0) ne "" or n_elements(ftype) gt 1 then $  
		imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr) $
	else begin
		imf=(*pmdata(i)).img
		fctr=[1D,1D]
	end
	if (size(imf))(0) ne 2 then imf=reform(imf,n_elements(imf),1)
	temp={img:imf,xsize:fctr(0)*(*pmdata(i)).xsize,ysize:fctr(1)*(*pmdata(i)).ysize}
	npmdata(i)=ptr_new(temp)
	
	si=strtrim(string(i),2)
	;	help,imf
	;smm=size(imf)
	;if smm(2) eq 1 then imfb=bytscl([[imf],[imf]]) else imfb=bytscl(imf)
	;	help,imfb

	rr=r
	gg=g
	bb=b
	
	if ftype(0) ne "" or n_elements(ftype) gt 1 then begin ;speedup 
		;special color filter
		wc=where((*filt(i)).type eq "color")
		if wc(0) ne -1 then begin 
		    pal=palgen((*filt(i)),wc(0),ro=r,bo=b,go=g)
		    rr=pal.r
		    gg=pal.g
		    bb=pal.b
		end
		;special filter grids
		wg=where((*filt(i)).type eq "grid")
		if wg(0) ne -1 then imf=gridgen((*filt(i)),wg(0),imf)
		wg=where((*filt(i)).type eq "dots")
		if wg(0) ne -1 then imf=gridgen((*filt(i)),wg(0),imf,/dots)
		wg=where((*filt(i)).type eq "scale")
		if wg(0) ne -1 then imf=sclgen((*filt(i)),wg(0),imf,(*pmdata(i)).xsize)

	end




;	write_png,'tmp'+si+'.png',imfb,rr,gg,bb
;	write_png,'scl'+si+'.png',sclimg,rr,gg,bb
	if file_test('tmp'+si+'.png') and (ftype(0) eq "" or n_elements(ftype) eq 0) then begin
		;print, 'skipping PNG save for image '+si+' (cached preview available)'
	end else if min(imf) eq max(imf) then begin
		file_copy,'imvoid.png','tmp'+si+'.png',/overwrite	
	end else begin	
		png_save,'tmp'+si+'.png',imf,r=rr,g=gg,b=bb
	end
;	png_save,'scl'+si+'.png',sclimg,r=rr,g=gg,b=bb

;	wh=histogram(imfb,min=0,max=256)
;	mxc=max(wh)>1
;	wh=(round(wh*46/mxc)>0)<46
;	histimg=histimg*0
;	hi=indgen(256)
;	histimg(hi,wh(hi))=hi
;	histimg=histimg+shift(histimg,0,1)
;	histimg(findgen(11)/10*255<255,45:49)=255
;	histimg(findgen(11)/10*255<255,0:4)=255
	;write_png,'hist'+si+'.png',histimg,rr,gg,bb

    end

    t1_prep = systime(1)
    dur_fileload = t1_fileload - t0_fileload
    dur_prep = t1_prep - t0_prep
    dur_total = systime(1) - t0_start
    print, '*** FILE LOADING DURATION: ', dur_fileload, ' s ***'
    print, '*** PREPROCESS DURATION: ', dur_prep, ' s ***'
    print, '*** TOTAL INITIALIZATION DURATION: ', dur_total, ' s ***'
end

i=0


heap_gc,/ptr,/verbose

print,"READY"
;******************************LOOP************************************
comm='none'

repeat begin ; menu loop

	si=strtrim(string(i),2)

;    parameters read
	;acqchan=(getval((*pmdata(i)).par,"Acquisition channel:"))
	angle=getval((*pmdata(i)).par,"Scan angle:","float")
;	yscandir=getval((*pmdata(i)).par,'Y scanning direction:')
	;help,yscandir
	ampsu=" "
	voltsu=" "
	volts=getval((*pmdata(i)).par,"Topography Bias:","float",unit=voltsu);
	amps=getval((*pmdata(i)).par,"Set Point:","float",unit=ampsu);
	fctr=[1.,1.]
	if not(keyword_set(preprocess)) then begin
	    imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr) 
	    print,"factor",fctr
	    xs=(*pmdata(i)).xsize*fctr(0)
	    ys=(*pmdata(i)).ysize*fctr(1)
	    runit=(*pmdata(i)).runit
	    zunit=(*pmdata(i)).zunit
	end $
	    else $ 
	begin
	    imf=(*npmdata(i)).img
	    xs=(*npmdata(i)).xsize
	    ys=(*npmdata(i)).ysize
	    runit=(*pmdata(i)).runit
	    zunit=(*pmdata(i)).zunit
	end
	
	s=size(imf)
	sr=size((*npmdata(i)).img)
	s1=strtrim(string(sr(1)),2)
	s2=strtrim(string(sr(2)),2)
	mnf=min(imf)
	mxf=max(imf)
	avf=mmean(imf)
	avf=avf>mnf
	avf=avf<mxf
	avfp=mmean((*pmdata(i)).img)
;	avfp=avfp>mnf
;	avfp=avfp<mxf

	stats=string(mnf,format='(E11.4)')+"/"+string(avf,format='(E11.4)')+"/"+string(mxf,format='(E11.4)')+"/("+string(avfp,format='(E11.4)')+")"
	
	msg=strarr(9)
	if strpos(filename(i),serverpath) eq 0 then msg(0)=strmid(filename(i),strlen(serverpath)+1) else msg(0)=filename(i)
	cd,current=mydir
	msg(2)="Creation: "+dts(i)
	;msg(2)=FILE_basename(filename(i))
	msg(1)="Slice: "+string(i+1)+" of "+string(n)
	msg(3)="Channel: "+acqchan(i)+" ["+zunit+"]  "+yscandir(i)+"-"+xscandir(i)
	msg(4)="U = "+strtrim(string(volts),2)+voltsu+"  Setpoint = "+strtrim(string(amps),2)+" "+ampsu
	msg(5)="Size: "+strtrim(string(xs),2)+" x "+strtrim(string(ys),2)+" "+runit+" ("+s1+"x"+s2+")"+"  Angle:"+strtrim(string(angle),2)
	msg(6)="Comments: "+(getval((*pmdata(i)).par,"Comments:"))
	msg(7)="MIN/AVG/MAX(AVG): "+stats
;	msg(8)="Matrix identifier: "+(getval((*pmdata(i)).par,"Matrix identifier:"))
	if marked(i) eq 1 then $
	    begin
		msg(8)="MARKED"
	    end


		;special color filter
		wc=where((*filt(i)).type eq "color")
		rr=r
		gg=g
		bb=b
		if wc(0) ne -1 then begin 
		    pal=palgen((*filt(i)),wc(0),ro=r,bo=b,go=g)
		    rr=pal.r
		    gg=pal.g
		    bb=pal.b
		end


;redrawing - can be skipped if no change occured
    redraw:
	if finite(imf(0)) and comm eq "filter" then begin
		;imfb=bytscl(imf)
		;png_save,'tmp'+si+'.png',imf,r=rr,g=gg,b=bb

		;redrawing of histogram and scale - can be skipped if no change occured
		si=strtrim(string(i),2)
		;imfb=bytscl(imf)
		
		;special filter grids
		wg=where((*filt(i)).type eq "grid")
		help,wg
		if wg(0) ne -1 then begin 
			print,'Applying grid..'
	    		imf=gridgen((*filt(i)),wg(0),imf)
		end
		wg=where((*filt(i)).type eq "dots")
		if wg(0) ne -1 then imf=gridgen((*filt(i)),wg(0),imf,/dots)

		wg=where((*filt(i)).type eq "scale")
		if wg(0) ne -1 then begin
			print,"applying scale to the image.."
			imf=sclgen((*filt(i)),wg(0),imf,(*pmdata(i)).xsize)
		end




;		write_png,'tmp'+si+'.png',imfb,rr,gg,bb
;		write_png,'scl'+si+'.png',sclimg,rr,gg,bb
		png_save,'tmp'+si+'.png',imf,r=rr,g=gg,b=bb
		png_save,'scl'+si+'.png',sclimg,r=rr,g=gg,b=bb

		wh=histogram(bytscl(imf),min=0,max=256)
		mxc=max(wh)>1
		wh=(round(wh*46/mxc)>0)<46
		histimg=histimg*0
		hi=indgen(256)
		histimg(hi,wh(hi))=hi
		histimg=histimg+shift(histimg,0,1)
		histimg(findgen(11)/10*255<255,45:49)=255
		histimg(findgen(11)/10*255<255,0:4)=255
		png_save,'hist'+si+'.png',histimg,r=rr,g=gg,b=bb
	end

;writing of the file with parameters

	
	openw,1,'tmp.dat'
	    for kl=0,n_elements(msg)-1 do printf,1,msg(kl)
;	    for kl=0,n_elements(msg2)-1 do printf,1,msg2(kl)
	    msg=""
	    msg2=""
;	    printf,1,"READY"
	close,1


	

	;menu
	
    ;reading the command!!

	comm=""
	read,comm
	print,"You wrote:",comm
	command=strlowcase(strtrim(comm,2))
	commands=strsplit(command,/extract)
	comm=commands(0)
	ncomm=n_elements(commands)
	;print,command
	;print,ncomm

			


case comm of


    "prev":	i=(i-1)>0 
    "next":	i=(i+1)<(n-1)
    "prevs":	begin
		    ;skips to the previous measurement
		    buniq=bfname(uniq(bfname))
		    bn=n_elements(buniq)
		    w=where(buniq eq bfname(i))
		    wx=where(bfname eq bfname(i)) ;first channel in the row
		    plusch=i-wx(0) ;channel number in the row
		    help,i
		    help,plusch
		    ww=where(bfname eq buniq((w(0)-1)>0))
		    ww2=where(bfname eq bfname((w(0)+1)<(bn-1)))
		    ;maxchi=(wx(0)-ww(0)-1)>0 ;number of channels in the prev row
		    maxchi=(n_elements(ww2)-1)>0 ;number of channels in the next row
		    help,maxchi
		    i=(ww(0)+(plusch<maxchi))>0
		end

    "nexts":	begin
		    ;skips to the next measurement
		    buniq=bfname(uniq(bfname))
		    bn=n_elements(buniq)
		    w=where(buniq eq bfname(i))
		    wx=where(bfname eq bfname(i)) ;first channel in the row
		    plusch=i-wx(0) ;channel number in the row
		    help,i
		    help,plusch
		    ww=where(bfname eq buniq((w(0)+1)<(bn-1)))
		    ww2=where(bfname eq bfname((w(0)+1)<(bn-1)))
		    maxchi=(n_elements(ww2)-1)>0 ;number of channels in the next row
		    help,maxchi
		    i=(ww(0)+(plusch<maxchi))<(n-1)

		end
    "prevch":	begin
		    wacq=where(acqchan+xscandir eq acqchan(i)+xscandir(i))
		    if wacq(0) ne -1 then begin
			wwacq=where(wacq lt i)
			if wwacq(0) ne -1 then i=wacq(wwacq(N_elements(wwacq)-1))
		    end
		end
    "nextch":	begin
		    wacq=where(acqchan+xscandir eq acqchan(i)+xscandir(i))
		    if wacq(0) ne -1 then begin
			wwacq=where(wacq gt i)
			if wwacq(0) ne -1 then i=wacq(wwacq(0))
		    end
		end
    "move":	if ncomm gt 1 then if isnumeric(commands(1)) then i=(round(i+commands(1))>0)<(n-1) else print,"You have to put number here"
    "goto":	if ncomm gt 1 then if isnumeric(commands(1)) then i=(round(commands(1)-1)>0)<(n-1) else print,"You have to put number here"
;    "color":	begin 
;		    if ncomm gt 1 then if isnumeric(commands(1)) then cpal=(round(commands(1))>0)<(32) else print,"You have to put number here"
;		    if round(cpal) eq 0 then goldpalette,/pure else loadct,cpal-1
;		    tvlct,r,g,b,/get
;		end
    "filter": 	begin ;rereads a filter edited in the gui, acts only on the image
		    heap_free,temp,/verbose
		    temp=filter_load('tmp.flt')
		    ptr_free,filt(i)
		    filt(i)=ptr_new(temp)
		    if (keyword_set(preprocess)) then $
		    begin
			fctr=[1D,1D]
			imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr)
			temp={img:imf,xsize:fctr(0)*(*pmdata(i)).xsize,ysize:fctr(1)*(*pmdata(i)).ysize}
			ptr_free,npmdata(i) ;avoid memory leaks
			npmdata(i)=ptr_new(temp)
		    end
		    ;saving filters
		    filtname(i)=get_meta_path_gdl(filename(i), cmdargs(0), /for_write)
		    filter_save,filtname(i),*filt(i)
		end

    "process": 	begin ;rereads processors and applies them, works on the whole structure
		    proct=proc_load('tmp.plt')
			;help,proct,/struct
			;print,proct
		    if (keyword_set(preprocess)) then begin
			fct=(*npmdata(i)).xsize/(*pmdata(i)).xsize
			fct=[fct,fct]
			imp=process(*pmdata(i),imf,proct,fctr=fct,r=rr,g=gg,b=bb) ;imf and fctr are both needed for a case of resizing, fctr can begin at <>1.0
		    end else $
			imp=process(*pmdata(i),imf,proct,fctr=fctr,r=rr,g=gg,b=bb) ;imf and fctr are both needed for a case of resizing, fctr can begin at <>1.0
		    ;imp is for nothing at this moment
		    ;saving processors
		    procname=getval((*pmdata(i)).par,"Filename:")+'.plt'
		    proc_save,procname,proct
		    ptr_free,proct
		end



;    "exit": print,"Exiting.."
    
    "bug": bug=bug(0:10)

    "wsxmsave":$
	begin 
	    wf=filename(i)
	    ;wfd=file_dirname(wf)
	    ;wfb=file_basename(wf)
	    ;cd,wfd,current=wd_old
	    fnm=wf+'.stp';dialog_pickfile(file="mod_"+wfb,/write,/overwrite_prompt)
	    print,'Exporting to WSXM'
	    print,fnm
	    ;if fnm ne "" then begin
	    ;help,imf
	    imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr) 
	    ;help,imf
	    xs=(*pmdata(i)).xsize*fctr(0)
	    ys=(*pmdata(i)).ysize*fctr(1)

		savedata=(*pmdata(i))
		savedata.xsize=xs
		savedata.ysize=ys
		savewsxm,refitwsxm(savedata,imf),fnm
		;savewsxm,savedata,fnm

	    ;end
	    
	    ;cd,wd_old
	end
    "gplsave":$
	begin 
	    wf=filename(i)
	    fnm=wf+'.txt';dialog_pickfile(file="mod_"+wfb,/write,/overwrite_prompt)
	    print,'Exporting to txt matrix for Gnuplot use'
	    print,fnm
	    imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr) 
		savegnuplot,fnm,imf
	end


    "mark": begin
		marked(i)=(marked(i)+1) mod 2
		;print,marked(i)
		w=where(marked ne 0)
		if w(0) ne -1 then uselist=file_basename(filename(w)) else uselist=""
		savelist,file_dirname(filtname(0))+"/useful.lst",uselist
    	    end
    "markall": begin
		marked=marked*0+1
		;print,marked(i)
		w=where(marked ne 0)
		if w(0) ne -1 then uselist=file_basename(filename(w)) else uselist=""
		savelist,file_dirname(filtname(0))+"/useful.lst",uselist
    	    end
    "marknone": begin
		marked=marked*0
		;print,marked(i)
		w=where(marked ne 0)
		if w(0) ne -1 then uselist=file_basename(filename(w)) else uselist=""
		savelist,file_dirname(filtname(0))+"/useful.lst",uselist
    	    end



    "pngsave":$ ;save current img as png file
	begin 
		    pngf=filename(i)
		    if not file_test(file_dirname(pngf), /write) then begin
		        meta_flt = get_meta_path_gdl(pngf, cmdargs(0), /for_write)
		        pngf = strmid(meta_flt, 0, strlen(meta_flt) - 4)
		    endif
		    IF not(KEYWORD_SET(preprocess)) then begin
			imf=filter((*pmdata(i)).img,*filt(i),fctr=fctr)
		    end else imf=(*npmdata(i)).img
		    print,pngf+".png"

		;special filter grids
		wg=where((*filt(i)).type eq "grid")
		;bimf=bytscl(imf)
		if wg(0) ne -1 then begin 
	    		imf=gridgen((*filt(i)),wg(0),imf)
		end
		wg=where((*filt(i)).type eq "dots")
		if wg(0) ne -1 then imf=gridgen((*filt(i)),wg(0),imf,/dots)
		wg=where((*filt(i)).type eq "scale")
		if wg(0) ne -1 then imf=sclgen((*filt(i)),wg(0),imf,(*pmdata(i)).xsize)



		    png_save,pngf+".png",imf,r=rr,g=gg,b=bb
	    print,"Finished."
	end


    "dump":$ ;dumps all marked, as png files
	begin 
	    wm=where(marked)
	    if wm(0) ne -1 then begin
	    pngf=filename(wm(0))
	    print,"Writing PNG files:"
	    for ii=0,n-1 do begin
		if marked(ii) eq 1 then begin
		
		    pngf=filename(ii)
		    if not file_test(file_dirname(pngf), /write) then begin
		        meta_flt = get_meta_path_gdl(pngf, cmdargs(0), /for_write)
		        pngf = strmid(meta_flt, 0, strlen(meta_flt) - 4)
		    endif
		    IF not(KEYWORD_SET(preprocess)) then begin
			imf=filter((*pmdata(ii)).img,*filt(ii),fctr=fctr)
		    end else imf=(*npmdata(ii)).img
		    print,pngf+".png"

		    wc=where((*filt(ii)).type eq "color")
		    rr=r
		    gg=g
		    bb=b
		    if wc(0) ne -1 then begin 
			pal=palgen(*filt(ii),wc(0),ro=r,bo=b,go=g)
			rr=pal.r
			gg=pal.g
			bb=pal.b
		    end
		;special filter grids
		wg=where((*filt(i)).type eq "grid")
		;bimf=bytscl(imf)
		if wg(0) ne -1 then begin 
	    		imf=gridgen((*filt(i)),wg(0),imf)
		end
		wg=where((*filt(i)).type eq "dots")
		if wg(0) ne -1 then imf=gridgen((*filt(i)),wg(0),imf,/dots)
		wg=where((*filt(i)).type eq "scale")
		if wg(0) ne -1 then imf=sclgen((*filt(i)),wg(0),imf,(*pmdata(i)).xsize)




		    png_save,pngf+".png",imf,r=rr,g=gg,b=bb
		end
	    end
	    print,"Finished."
	    end
	end

    "imgstartepoch":$
	;flushes image epoch times into a file
	begin
	    openw,1,"imgstartepochs"
	    for iii=0,n-1 do begin
		spawn,'date -d "'+dts(iii)+'" +%s',epoch
		printf,1,long(epoch(0))
	    end
	    close,1
	end

    "imgendepoch":$
	;flushes image epoch times into a file
	begin
	    openw,1,"imgendepochs"
	    for iii=0,n-1 do begin
		;duration of the measurement
		spawn,'date -d "'+dts(iii)+'" +%s',epoch
		printf,1,long(epoch(0))+long(dur(iii))
	    end
	    close,1
	end

    "sts":$
	;creates a global sts map and flushes files with epochs and coordinates
	begin
	    print,'Creating global STS map'
	    uniqd=uniq(dts)
	    tuniq=dts(uniqd)
	    tn=n_elements(tuniq)
	
            stsdir=file_dirname(filename(0))
	    nsts=0
	    if File_Test(stsdir,/directory) then begin
		;read files with sts, headers only
		stsf=getfiles(stsdir,mask='*.dat')
		print,"working dir: ",stsdir
		help,stsf
		print,stsf

		if strlen(strtrim(stsf(0),2)) ne 0 then begin
		    nsts=n_elements(stsf)
		    xap=dblarr(nsts)
		    yap=dblarr(nsts)
		    ;pepoch=lonarr(nsts)
		    strpepoch=strarr(nsts)
	
		    for si=0,nsts-1 do begin
			    ststmp=loadnanonis_sts(stsf(si),/head)
			    xap(si)=double(ststmp.p.x)

			    help,ststmp.p.x
			    yap(si)=double(ststmp.p.y)
			    strpepoch(si)=ststmp.p.date
		    end
		end	
	    end
	   
	    print,'finished reading sts headers and dates'
 	
	    print,'cycling image indices'		
	    
	    for mmi=0,tn-1 do begin
		mi=uniqd(mmi)
		help,mi
	    	w=where(tuniq eq dts(mi))
	    	wwn=where(dts eq tuniq((w(0)+1)<(tn-1)))
	    	wwp=where(dts eq tuniq((w(0))>0))
		print,dts(w(0))
		print,dts(wwp(0))
		print,dts(wwn(0))
		xsmi=(*pmdata(mi)).xsize*fctr(0)
		ysmi=(*pmdata(mi)).ysize*fctr(1)
		srmi=size((*pmdata(mi)).img)
		xa=0
		ya=0
		stsi=0
	
	    	xo=getval((*pmdata(mi)).par,"X Offset:",'float')
		yo=getval((*pmdata(mi)).par,"Y Offset:",'float')
		sxize=getval((*pmdata(mi)).par,"X Amplitude:",'float')
		syize=getval((*pmdata(mi)).par,"Y Amplitude:",'float')
		angl=getval((*pmdata(mi)).par,"Scan angle:","float");
		rang=angl/180.*!PI
		ic=dcomplex(0,1)
		centerpoint=dcomplex(xo,yo)+dcomplex(sxize/2,syize/2)*exp(-ic*rang)
		xc=real_part(centerpoint)
		yc=imaginary(centerpoint)

	    	if nsts ne 0 then for si=0,nsts-1 do begin
			if dts(mi) eq dts(wwn(0)) then dtswwn=strpepoch(si) else dtswwn=dts(wwn(0))

			if strpepoch(si) ge dts(wwp(0)) and strpepoch(si) le dtswwn then begin
			    stsi=[stsi,si]
			    xa=[xa,xap(si)]
			    ya=[ya,yap(si)]
			end
		end
		print,"finished cycling sts"

		if n_elements(stsi) gt 1 then begin
			stsi=stsi(1:*)

			xa=xa(1:*)-xc ;TODO:rotation needed!!
			ya=ya(1:*)-yc ;TODO:rotation needed!!
			vct=dcomplex(xa,ya)*exp(ic*rang)
			xa=real_part(vct)+sxize/2
			ya=imaginary(vct)+syize/2

			xp=(((1E9*xa/xsmi)+0.5)*float(srmi(1)))
			yp=((0.5+(1E9*ya/ysmi))*float(srmi(2)))

			raw_map_file = stsdir + '/' + bfname(mi) + '.map'
			if file_test(stsdir, /write) then begin
			    fnm = raw_map_file
			end else begin
			    fnm = get_meta_path_gdl(raw_map_file, cmdargs(0), /for_write)
			endelse
			openw, 1, fnm
			print,"writing "+fnm
			for kl=0, n_elements(stsi)-1 do begin
				printf,1,xp(kl),yp(kl),srmi(2)
				printf,1,file_basename(stsf(stsi(kl)))
			endfor
			close, 1
		end else print, "No matching STS found for "+bfname(mi)
		
	    end

	end
	   
    "imgoffs": $
	begin
	;writes centers of the images and detailed image offset metadata
		    openw,4,"stsxc"
		    openw,5,"stsyc"
		    openw,6,"imgoffs.dat",width=2000
			
		    for iii=0,n-1 do begin
			    xo=getval((*pmdata(iii)).par,"X Offset:",'float')
			    yo=getval((*pmdata(iii)).par,"Y Offset:",'float')
			    sxize=getval((*pmdata(iii)).par,"X Amplitude:",'float')
			    syize=getval((*pmdata(iii)).par,"Y Amplitude:",'float')
			    angl=getval((*pmdata(iii)).par,"Scan angle:","float");
			    rang=angl/180.*!PI
				ic=dcomplex(0,1)
				centerpoint=dcomplex(xo,yo)+dcomplex(sxize/2,syize/2)*exp(-ic*rang)
				
			    printf,4,real_part(centerpoint),format='(E16.8)'
			    printf,5,imaginary(centerpoint),format='(E16.8)'
			    lout = strtrim(string(iii),2)+';'+filename(iii)+';'+acqchan(iii)+';'+strtrim(string(xo,format='(E16.8)'),2)+';'+strtrim(string(yo,format='(E16.8)'),2)+';'+strtrim(string(sxize,format='(E16.8)'),2)+';'+strtrim(string(syize,format='(E16.8)'),2)+';'+strtrim(string(angl,format='(E16.8)'),2)+';'+dts(iii)
			    printf,6,lout
		    end
		    close,4	
		    close,5
		    close,6
			print,'image centers written to file'	
	end


;    "stsmap":$
;	;creates sts map for current file, at this moment supports only nanonis, qplus maybe in the future
;	begin
;		print,'Creating sts map'
;	    stsdir=file_dirname(filename(i))
;	    if File_Test(stsdir,/directory) then begin
;		;find out which is the next imageset by time
;		tuniq=dts(uniq(dts))
;		tn=n_elements(tuniq)
;		w=where(tuniq eq dts(i))
;		wwn=where(dts eq tuniq((w(0)+1)<(tn-1)))
;		wwp=where(dts eq tuniq((w(0)-1)>0))
;		;help,ww
;		;read files with sts, headers only
;		spawn,'ls '+stsdir+'/*.dat',stsf
;		help,stsf
;		stsi=-1
;		xa=0
;		ya=0
;		la=0
;		if stsf(0) ne "" then begin
;		    nsts=n_elements(stsf)
;			    spawn,'date -d "'+dts(i)+'" +%s',epoch1
;			    epoch1=long(epoch1(0))
;
;		    stsdur=0
;		    for si=0,nsts-1 do begin
;		        ststmp=loadnanonis_sts(stsf(si),/head)
;			if dts(i) eq dts(wwn(0)) then dtswwn=ststmp.p.date else dtswwn=dts(wwn(0))
;		        ;print,wwn(0),wwp(0)
;
;			if ststmp.p.date ge dts(wwp(0)) and ststmp.p.date le dtswwn then begin
;			    ;ststmp=loadnanonis_sts(stsf(si))
;			    nstspts=size(ststmp.data)
;			    stsdur=stsdur+(ststmp.p.settime+ststmp.p.inttime)*nstspts(2)*(ststmp.p.bwd+1)
;			    stsi=[stsi,si]
;			    xa=[xa,ststmp.p.x]
;			    ya=[ya,ststmp.p.y]
;			    spawn,'date -d "'+ststmp.p.date+'" +%s',epoch
;			    spawn,'date -d "'+dtswwn+'" +%s',epoch2
;			    ;print,epoch,epoch1,epoch2
;			    epoch=long(epoch(0))
;			    epoch2=long(epoch2(0))
;			    epochx=epoch-epoch1
;			    help,epoch
;			    help,epoch1
;			    help,epoch2
;			    help,epochx
;			    help,dur(i)
;			    help,stsdur
;			    la=[la,double(epochx)]
;			end
;		    end
;		
;		    if n_elements(stsi) gt 1 then begin
;			stsi=stsi(1:*)
;			xo=getval((*pmdata(i)).par,"X Offset:",'float')
;			yo=getval((*pmdata(i)).par,"Y Offset:",'float')
;			xa=xa(1:*)-xo
;			ya=ya(1:*)-yo
;			la=(la(1:*)*double(s(2))/(epoch2-epoch1))
;			xp=(((1E9*xa/xs)+0.5)*float(sr(1)))
;			yp=((0.5+(1E9*ya/ys))*float(sr(2)))
;			wf=stsdir+'/'+bfname(i)
;			fnm=wf+'.map'
;			openw,1,fnm
;			;help,stsi
;			;print,stsi
;			nstsi=n_elements(stsi)
;			for kl=0,n_elements(stsi)-1 do printf,1,xp(kl),yp(kl),la(kl),file_basename(stsf(stsi(kl)))
;			close,1
;			print,file_basename(stsf(stsi))
;		    end $
;		    else print, "No matching STS found" 
;		end
;	    end
;	end

    else: begin
	    print,"Unassociated command"
	end

endcase

	
endrep until comm eq "exit"  ;exit
    
;    print,file_dirname(filename(i))
    ptr_free,filt
    ptr_free,pmdata
    if keyword_set(npmdata) then ptr_free,npmdata
    
end


