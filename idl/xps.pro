function savg,y,width
;savitzky-golay filter, operates on regular grid only
y=reform(y)
if not keyword_set(width) then width = n_elements(y)/10
width=abs(width)

if width gt n_elements(y) then message, 'Filter width should be smaller than the no. of data points', /continue
;filter generation
filter = savgol(width,width,0,2)
n = n_elements(y)
yf = convol(y, filter, /edge_truncate)

return,yf
end

function fitbkg,y,boundsize,type=type
;should subtract a line bkg(or more?) from the data
;boundsize specifies width on the sides (percentage) where to catch the line
;does not need regular data
n=n_elements(y)
if boundsize lt 0.4 then begin
x=indgen(n)
yw=[y(0:boundsize*n),y(n*(1-boundsize)-1:n-1)]
xw=[x(0:boundsize*n),x(n*(1-boundsize)-1:n-1)]
end else return,y
R = LADFIT(xw,yw) 
yn=y-(R(0)+R(1)*x)
return,yn
end


function loadregion,f
;loads one two-column file into a structure
if not(keyword_set(f)) then f=dialog_pickfile(/must_exist)
if f eq "" then return,-1
data=read_ascii(f)
x=reform(data.field1[0,*])
y=reform(data.field1[1,*])
dat={name:file_basename(file_dirname(f)),subname:file_basename(f),x:x,y:y}
return,dat
end

pro saveregion,data,f
;saves one file corresponding to one region
if not(keyword_set(f)) then f=dialog_pickfile(/overwrite_prompt,file=data.subname,/write)
if f eq "" then return

openw,LUN,f,/get_lun
    for i=0,n_elements(data.x)-1 do begin
        printf,LUN,data.x[i],data.y[i]
    end
close,LUN
end

function cpystruct,pmdat
    n=n_elements(pmdat)
    pmdata=ptrarr(n)
    for i=0,n-1 do begin
	pmdata(i)=ptr_new(*pmdat(i))
    end
return,pmdata
end

function recut,data,range,blind=blind
    if not(keyword_set(range)) then begin
	if not(keyword_set(blind)) then drawmulti,data,offset=0.25
	cursor,x1,y,/up
	cursor,x2,y,/up
	range=[x1,x2]
    end

;print, range

dis1=abs(data.x-range(0))
dis2=abs(data.x-range(1))


ix=[where(dis1 eq min(dis1)),where(dis2 eq min(dis2))]
;print,ix

nwdata={name:data.name,subname:data.subname,x:data.x[min(ix):max(ix)],y:data.y[min(ix):max(ix)]}

return, nwdata
end


function recutmulti,mdata,range
n=n_elements(mdata)

nwslice=recut(mdata(0),range,/blind)

nwdata=replicate(nwslice,n)

for i=1,n-1 do nwdata(i)=recut(mdata(i),range)

return,nwdata
end

function recutmultip,pmdat,range
pmdata=cpystruct(pmdat)
n=n_elements(pmdata)

for i=0,n-1 do (*pmdata(i))=recut((*pmdata(i)),range)

return,pmdata
end

function loadmulti,f
;load entire list of files into a structure, MUST BE THE SAME SIZE
if not(keyword_set(f)) then f=dialog_pickfile(/multiple_files,/must_exist)
n=n_elements(f)
mdata=replicate(loadregion(f(0)),n)
    for i=1,n-1 do begin
	mdata(i)=loadregion(f(i))
    end
return,mdata
end

pro savemulti,mdata
n=n_elements(mdata)
d=dialog_pickfile(/directory)
if d eq "" then return

cd,d,current=old

    for i=0,n-1 do begin
	slice=mdata(i)
	saveregion,slice
    end

cd,old
end


function loadmultip,f
;load entire list of files into a structure, DOES NOT HAVE TO BE THE SAME SIZE
if not(keyword_set(f)) then f=dialog_pickfile(/multiple_files,/must_exist)
n=n_elements(f)
pmdata=ptrarr(n)
    for i=0,n-1 do begin
	pmdata(i)=ptr_new(loadregion(f(i)))
    end
return,pmdata
end

pro savemulti,mdata
n=n_elements(mdata)
d=dialog_pickfile(/directory)
if d eq "" then return

cd,d,current=old

    for i=0,n-1 do begin
	slice=mdata(i)
	saveregion,slice
    end

cd,old
end

pro drawmultip,pmdat,offset=offset,sg=sg,oplot=oplot,nonames=nonames,epssave=epssave,$
pngsave=pngsave,identify=identify,colors=colors,psm=psm,bkg=bkg,lim=lim,normfactor=normfactor,allnorm=allnorm,crosssect=crosssect

; in testing
;plots multiple data into one plot, respects the order of files; can save images
;sg - applies savitzky-golay, can be array
;offset - offsets the data by percentage specified
;oplot - allows overplot
;nonames - disables descriptions
;epssave/pngsave - plots to eps/png file, exclusive, png use current window size, eps roughly, too
;identify - array of strings, names of elements, whose spectral lines will be shown in the plot
;color - colors version of the plot
;psm - type of plot symbol, default circle
;bkg - remove background by subtracting minimum (1) or median (2) or line fit of the base (4) : (3) is reserved
;lim - 2-element vector of the recut limits
;allnorm - normalizes all curves by one of three following methods: 1 - by max, 2 - by max-min, 3 by total area
;	negative value is used to return the coeficients only and draw curves without actual normalization
;normfact - variable where normalization coeficients are returned, if allnorm is used

;copy the structure first to avoid changing it
;    n=n_elements(pmdat)
;    pmdata=ptrarr(n)
;    for i=0,n-1 do begin
;	pmdata(i)=ptr_new(*pmdat(i))
;    end

    pmdata=cpystruct(pmdat)


subtitl="Curves are"
titl=""

;recut if the limits are set
    if keyword_set(lim) then if lim(0) ne 0 then pmdata=recutmultip(pmdata,lim)

    device,decomposed=0
    device,retain=2
    if keyword_set(colors) then $
	begin
;	    colpal=[254,200,191,175,113,95,70,33,255,90,0]
	    colpal=[254,200,175,95,70,33,255,90,0]
	    ncl=n_elements(colpal)-3
	    loadct,39,/silent
	end $
	    else $
	begin
	    colpal=[0,255,128,0]
	    ncl=1
	    loadct,0,/silent
	end

    n=n_elements(pmdata)
    mxpts=intarr(n)
    for i=0,n-1 do mxpts(i)=n_elements((*pmdata(i)).y)/2

    if not(keyword_set(psm)) then psm=8
    
    if keyword_set(sg) then $
	begin	
	    if n_elements(sg) ne n then $
		sg=replicate(sg(0),n)
	    
	    for i=0,n-1 do if sg(i) lt 0 or sg(i) gt mxpts(i) then sg(i)=-1
	end

    rmarg=3
    if not(keyword_set(nonames)) then rmarg=25
    if keyword_set(bkg) then $
	if bkg eq 3 then $
	    for i=0,n-1 do (*pmdata(i)).y=(*pmdata(i)).y $
	else $
	    if bkg eq 2 then $
		for i=0,n-1 do begin
		    (*pmdata(i)).y=(*pmdata(i)).y-mean((*pmdata(i)).y) 
		    end $
	    else $
		if bkg eq 4 then $
			for i=0,n-1 do $
			    begin
				yf=fitbkg((*pmdata(i)).y,0.1)
				(*pmdata(i)).y=yf
				(*pmdata(i)).subname=(*pmdata(i)).subname+"!CI="+strtrim(string(total(yf)),2)
			    end $
		else $
		    for i=0,n-1 do begin
			(*pmdata(i)).y=(*pmdata(i)).y-min((*pmdata(i)).y)
		    end


;subtitle
	if allnorm eq 0 and keyword_set(normfactor) then subtitl=subtitl+" normalized"
	if allnorm gt 0 then subtitl=subtitl+" the REFERENCE normalized"
	if allnorm lt 0 then subtitl=subtitl+" the REFERENCE"


		
;cross-section if set
	if keyword_set(crosssect) then begin
	    subtitl=subtitl+" cross-sectioned"
	    if n_elements(crosssect) ne n then crosssect=replicate(crosssect(0),n)
	    for i=0,n-1 do (*pmdata(i)).y=(*pmdata(i)).y/crosssect(i)
	end



;normalization factor calculation
	if abs(allnorm) gt 0 then begin
	    normfactor=dblarr(n)+1.
	    if abs(allnorm) eq 1 then for i=0,n-1 do normfactor(i)=max((*pmdata(i)).y)
	    if abs(allnorm) eq 2 then for i=0,n-1 do normfactor(i)=max((*pmdata(i)).y)-min((*pmdata(i)).y)
	    if abs(allnorm) eq 3 then begin
		for i=0,n-1 do normfactor(i)=total((*pmdata(i)).y)/n_elements((*pmdata(i)).x)
	    end
	end
	
;normalization only for non negative allnorm or when not set
;help,normfactor
	if allnorm ge 0 or not(keyword_set(allnorm)) and keyword_set(normfactor) then begin
	    
	    for i=0,n-1 do (*pmdata(i)).y=(*pmdata(i)).y/normfactor(i)
	    
	end

print,allnorm


    if keyword_set(epssave) then begin
        if pngsave ne "auto" then $
	    fnm=dialog_pickfile(/write,/overwrite_prompt,filter='*.eps',file=(*pmdata(0)).name+".eps") $
	else $
	    fnm=(*pmdata(0)).name+".eps"


	if fnm eq "" then return
	xsze=!D.X_VSIZE/!D.X_PX_CM
	ysze=!D.Y_VSIZE/!D.Y_PX_CM

	SET_PLOT, 'ps'
	DEVICE,/ENCAPSUL, BITS_PER_PIXEL=8, /times,/narrow,/COLOR, FILENAME=fnm,xsize=xsze,ysize=ysze
        rmarg=1
	if not(keyword_set(nonames)) then rmarg=25
	
	
    end

    A = FINDGEN(17) * (!PI*2/16.)  
    USERSYM, COS(A), SIN(A), /FILL  

    if not(keyword_set(offset)) then offset=0.

    mxs=dblarr(n)
    mns=dblarr(n)
    meds=dblarr(n)

    xmxs=dblarr(n)
    xmns=dblarr(n)
    names=strarr(n)
    for i=0,n-1 do $
	begin
	    mxs(i)=max((*pmdata(i)).y)
	    xmxs(i)=max((*pmdata(i)).x)
	    
	    meds=median((*pmdata(i)).y)
	    
	    mns(i)=min((*pmdata(i)).y)
	    xmns(i)=min((*pmdata(i)).x)
	    
	    names(i)=(*pmdata(i)).name
	end 

    mx=max(mxs) 
    mn=min(mns(0))

    xmx=max(xmxs) 
    xmn=min(xmns)

    
    ui=uniq(names) ;needs a rewrite
    titl=titl+" /"
    
    if subtitl eq "Curves are" then subtitl=""
print,subtitl
    
    if ui(0) ne -1 then $
	for i=0,n_elements(ui)-1 do titl=titl+names(i)+"/"


    if not(keyword_set(oplot)) then $
	offstep=(mx-mn)*offset
	gmx=(mx+(n-1)*offstep)*1.1
	plot,(*pmdata(0)).x,(*pmdata(0)).y,psym=psm,yrange=[mn,gmx],xmargin=[8,rmarg],$
	yst=1,xst=1,title=titl,/nodata,background=colpal[ncl],font=0,color=colpal[ncl+2],xrange=[xmx,xmn],$
	xtitle="Binding Energy [eV]",ytitle="arb. units",subtitle=subtitl



	if keyword_set(identify) then $
	    begin
		tbl=read_tbl()
		tp=size(identify,/type)
	    	    if tp eq 7 then $
    			begin
			    tbl=find_energy(identify,tbl)
			end $
		    else $
			begin
			    e=(xmx+xmn)/2.
			    tol=abs(xmx-xmn)/2.
			    tbl=find_element(e,tbl,tol)
			end
	
	    nel=n_elements(tbl.energy)
	    xcord=[[tbl.energy],[tbl.energy]]
	    xcord=reform(transpose(xcord),nel*2)
	    ycord=[[replicate(gmx,nel)],[replicate(mn,nel)]]
	    ycord=reform(transpose(ycord),nel*2)
	    for i=0,nel-1 do begin
		plots,[xcord(2*i),xcord(2*i+1)],[ycord(2*i),ycord(2*i+1)],color=colpal[ncl+1],noclip=0
;		xyouts,tbl.energy(i),mn+0.01*(gmx-mn),tbl.element(i)+" "+tbl.descr(i),color=colpal[ncl],orientation=90,noclip=0,charthick=3.
;		xyouts,tbl.energy(i),mn+0.01*(gmx-mn),tbl.element(i)+" "+tbl.descr(i),color=colpal[ncl+2],orientation=90,noclip=0
		xyouts,tbl.energy(i),gmx-0.01*(gmx-mn),tbl.element(i)+" "+tbl.descr(i),color=colpal[ncl],orientation=-90,noclip=0,charthick=3.
		xyouts,tbl.energy(i),gmx-0.01*(gmx-mn),tbl.element(i)+" "+tbl.descr(i),color=colpal[ncl+2],orientation=-90,noclip=0

	    end
	end





    for i=0,n-1 do begin
	if keyword_set(colors) then pntcol=colpal(i mod ncl) else pntcol=colpal[ncl+1]
	oplot,(*pmdata(i)).x,(*pmdata(i)).y+offstep*i,psym=psm,symsize=0.5,color=pntcol
	if keyword_set(sg) then begin
	    sgdatay=savg((*pmdata(i)).y,sg(i))+offset*i*(mx-mn)
	    oplot,(*pmdata(i)).x,sgdatay,color=colpal(i mod ncl)
	end
	if not(keyword_set(nonames)) then begin
	    xp=xmn-0.01*(xmx-xmn)
	    if keyword_set(offset) then $
		if keyword_set(sg) then yp=sgdatay(n_elements(sgdatay)*0.9) else yp=(*pmdata(i)).y(n_elements((*pmdata(i)).y)-1)+offstep*i $
		
	    else $
		yp=mn+(gmx-mn)*i/n
		regname=(*pmdata(i)).subname
		rps=strpos(regname,"_")
		if rps ne -1 then regname=strmid(regname, rps+1)
;		print,regname
	    xyouts,xp,yp,regname,font=0,color=colpal(i mod ncl)
	end
    end



    if keyword_set(epssave) then begin
	DEVICE, /CLOSE ; Close the file.
	SET_PLOT, 'x' ; Return plotting to X Windows.
    end

    if keyword_set(pngsave) then begin
	pngsave=string(pngsave)
	filename=pngsave
	if pngsave eq string(1) then filename=dialog_pickfile(/write,/overwrite_prompt,filter='*.png',file=(*pmdata(0)).name+'.png')
	
	if pngsave eq "auto" then filename=(*pmdata(0)).name+".png"
	
	if filename eq "" then return
        
	img=tvrd(0,true=1)
	write_png,filename,img
;	h=img_save(filename,img,typ="png")
    end

end


function read_tbl,f
;the template
t={  VERSION:1.00000,DATASTART:0,DELIMITER:32B,MISSINGVALUE:0,COMMENTSYMBOL:'',$
FIELDCOUNT:3L,FIELDTYPES:[4,7,7],FIELDNAMES:["energy","element","descr"],FIELDLOCATIONS:[0L,4L,7L],FIELDGROUPS:[0,1,2]}
if not(keyword_set(f)) then f="$HOME/sync/idl/XPSlookup.red"

tbl=read_ascii(f,template=t)
return,tbl
end

function find_element,energy,tbl,tolerance
if(not(keyword_set(tolerance))) then tolerance=0.5
dist=tbl.energy-energy
dist=abs(dist)-tolerance
i=where(dist lt 0)
if i(0) ne -1 then return,{energy:tbl.energy(i),element:tbl.element(i),descr:tbl.descr(i)} else return, -1
end

function find_energy,element,tbl
i=0
for j=0,n_elements(element)-1 do i=[i,where(tbl.element eq element(j))]
i=i(1:*)
tbl={energy:tbl.energy(i),element:tbl.element(i),descr:tbl.descr(i)}

s=(sort(tbl.energy))
tbl.energy=tbl.energy(s)
tbl.element=tbl.element(s)
tbl.descr=tbl.descr(s)

if i(0) ne -1 then return,tbl else return, -1
end

pro autoexport,dirr
;goes through the directory and tries to draw the content together
    if not(keyword_set(dirr)) then dirr=dialog_pickfile(/directory,/must_exist)
;dirr - directory where to search, goes down two levels
;filter - helps to process only wanted files ("_BE" etc.)

rules={$
    ;rules is a structure defining processing options for each curve

    ;filter defining which curves are searched and in which order
    filter:["Cu*_BE","C1s*_BE","O*_BE","N*_BE","Surv*_BE"],$

    ;normalization, tells which curves get normalized by the first one and how(normtype), 
    ;1 is by maximum, 2 is by maximum-minimum and 3 is by its total intensity
    normalize:[0,0,0,0,0],$
    normtype:2,$

    ;offsets of the curves
    offset:[0,0.5,0.5,0.5,0.5],$ 

    ;savitzky-golay smooth width
    sg:[2,10,10,15,1],$

    ;size of the picture in px
    xs:[600,400,400,400,1000],$
    ys:[400,400,400,400,400],$
    
    ;type of background: see drawmultip
    bkg:[4,1,1,1,1],$

    ;colors
    colors:[1,1,1,1,1],$

    ;overlay lines for all curves
    identify:["N","C","O","Cu"],$

    ;interval of the data plotted and processed
    ulim:[0,0,0,0,0,0],$
    llim:[0,0,0,0,0,0]$
}


;    if not(keyword_set(dirr)) then dirr=dialog_pickfile(/directory,/must_exist)
    if dirr eq "" then return
print,dirr

				
for c=0,n_elements(rules.filter)-1 do $
    begin
	window,0,xs=rules.xs(c),ys=rules.ys(c)
	print,rules.filter(c)
	dirs=file_search(dirr+'/*/transposed/'+rules.filter(c)+'/')
	;print,dirs
	if dirs(0) ne "" then $
	    begin

		for i=0,n_elements(dirs)-1 do $
		    begin
			filez=file_search(dirs(i)+'/*')
			print,dirs(i)
			if filez(0) ne "" then $
			    begin
				datam=loadmultip(filez)
				
				if c eq 0 then begin
				    actnorms=dblarr(n_elements(datam))
				    allnrm=rules.normtype*sgn(2*sgn(rules.normalize(0))-1)
				    subnames=strarr(n_elements(datam))
				    for j=0,n_elements(datam)-1 do subnames(j)=(*datam(j)).subname
				    print,"subnames1:",subnames
				end
					
				if c eq 1 then begin
				    norms=actnorms
				    ;print, "second cycle"
				    ;print, norms
				end
				
				if c ge 1 then begin
				    allnrm=0
				    actnorms=dblarr(n_elements(datam))
				    for j=0,n_elements(datam)-1 do begin
					print,"subname2:",(*datam(j)).subname
					print,"subnames2:",subnames
					www=where(subnames eq (*datam(j)).subname)
					if www(0) ne -1 then actnorms(j)=norms(www) else actnorms(j)=1
				    end
				    if rules.normalize(c) eq 0 then actnorms=0
				    ;print,"actual norms"
				    ;print,actnorms
				end
				
				if rules.normtype eq 0 then begin 
				    print,"no normalizing at all"
				    allnrm=0 
				    actnorms=0
				end
				
				if rules.normalize(c) ne 0 then xsect=rules.normalize(c) else xsect=0
				print,"xsect"+string(xsect)				
				drawmultip,datam,identify=rules.identify,$
				    colors=rules.colors(c),bkg=rules.bkg(c),$
				    offset=rules.offset(c),sg=rules.sg(c),$
				    pngsave=file_dirname(filez(0))+'.png',lim=[rules.ulim(c),rules.llim(c)],normfactor=actnorms,allnorm=allnrm,crosssect=xsect
			    end
		    end
	    end
    end
end


