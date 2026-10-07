
function loadnanonis_bulk,f,raw=raw,verbose=verbose,spskip=spskip
;reads the NANONIS SXM format file and returns a structure containing parameters and image
;verbose - prints more info while loading channles
;spskip - skips reading of channels that represent photon spectra

close,/all ; for sure

;open file
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist,filter=['*.sxm','*.SXM'],title='Select a NANONIS file to open')

;in case file does not exist or corrupted
dummy={par:"Filename: "+f,img:0,zunit:0,runit:0,xsize:0,ysize:0,conversion:0,zsize:0,datatype:0}
if not(File_Test(f)) then return,dummy

;reading parameters until binary data
print,"Reading "+f
openr,1,f
par=strarr(1999)
counter=-1L

repeat begin
    counter=counter+1
    a=strarr(1)
    readf,1,a
    par(counter)=a
endrep until strpos(a,":SCANIT_END:") ne -1 or counter gt 1997

print,"Header counter: ",counter+1

a=0B

;adjust read position to the data beginning
print,'bytes after header end'
repeat begin
    ad=a
    a=0B
    readu,1,a
    ;print,a
endrep until ad eq 26B and a eq 4B
;print,'found image start'
par=par(0:counter+1)
par=shift(par,1)
paru=STRUPCASE(par)

;getting crucial parameters

par(0)="Filename: "+f
xy=getvaln(par,":SCAN_PIXELS:")
x=round(xy(0))
y=round(xy(1))

;help,x
;help,y


xysize=getvaln(par,":SCAN_RANGE:")
xsize=double(xysize(0))*1E9
ysize=double(xysize(1))*1E9

;help,xsize
;help,ysize

runit="nm"
zunit="nm"
datatype='float'

;read parameters to determine total no of images and to assign correct parameters

chans=rdnline(par,':DATA_INFO:',/n)
chans=par(chans(2:*))

	chans=chans(where(strtrim(chans,2) ne ""))
	print,'skipping the spectroscopic channels'


help,chans
chn=n_elements(chans)
;split
chnum=intarr(chn)
chname=strarr(chn)
chunit=strarr(chn)
chdirr=strarr(chn)
chcal=dblarr(chn)
choffs=dblarr(chn)



for i=0,chn-1 do begin
   	line=strsplit(chans(i),/extract)
    chnum(i)=round(line(0))
    chname(i)=line(1)
    chunit(i)=line(2)
    sdir=strtrim(line(3),2)
    if sdir eq 'both' then chdirr(i)=2 else chdirr(i)=1
    chcal(i)=line(4)
    choffs(i)=line(5)
end


if keyword_set(spskip) then begin
	print,'skipping the spectroscopic channels'
	w=where(valid_num(strtrim(chname,2)) ne 1)
	if w(0) ne -1 then begin
		chn=n_elements(w)
		chnum=chnum(w)
		chname=chname(w)
		chdirr=chdirr(w)
		chcal=chcal(w)
		choffs=choffs(w)
	end

end

;voltage in dual mode will be different!
	voltage="Topography Bias: "+getvaln(paru,":BIAS")+" V"
	;print,voltage
	currl=rdnline(par,":Z-CONTROLLER:",/n)
	if currl(0) ne -1 then begin
		currr=strsplit(par(currl(2)),"	",/extract)
		current="Set Point: "+strtrim(string(currr(2)),2)
		feed="Feedback: "+strtrim(string(currr(1)),2)
;	date="Acquisition time: "+getvaln(par,":REC_DATE:")+" "+getvaln(par,":REC_TIME:")
	end else begin
		current="Set Point: 1 nA"
		feed="Feedback: whatever"
	end

	date0=getvaln(par,":REC_DATE:")
	if date0(0) eq "" then begin
		datea=getvaln(par,":Date:")
		if datea(0) eq "" then datea=getvaln(par,":Start time:")
		date0=datea(0)
		time0=datea(1)
		end else time0=getvaln(par,":REC_TIME:")


	;print,date0
	if date0(0) ne "" then begin
		date1=strsplit(date0,'.',/extract)
		date="Acquisition time: "+date1(2)+'-'+date1(1)+'-'+date1(0)+' '+time0
	end 
		dur="Duration: "+getvaln(par,":ACQ_TIME:")

	pxsize="X Amplitude: "+string(xsize)+" nm"
	pysize="Y Amplitude: "+string(ysize)+" nm"
	nrows="Number of rows: "+string(y)
	ncols="Number of columns: "+string(x)
	imgdttype="Image Data Type: float"
	scanfq="X-Frequency: "+string(float(getvaln(par,":ACQ_TIME:"))/y)+" s"
	ydir=getvaln(par,":SCAN_DIR:")
	;help,ydir(0)
	yscandir="Y scanning direction: "+ydir(0)
	scanangle="Scan angle: "+string(getvaln(par,":SCAN_ANGLE:")) ;employ this later

	xyo=getvaln(par,":SCAN_OFFSET:")
	xo=" X Offset: "+string(xyo(0))+" m"
	yo=" Y Offset: "+string(xyo(1))+" m"

	cm=rdnline(par,":COMMENT:",/n)
	;help,cm
	if cm(0) ne -1 then $
	com=strjoin(par(cm(1:*)), "\n") else com=""


;reading binary data

    if keyword_set(verbose) then print,'Reading binary data...'

if x gt 0 and y gt 0 then begin

	
	;allocate megaarray
	print,'Allocate mem.'
	megarray=fltarr(chn,2,x,y)	;chdirr can be one also in principle!!
	print,'Start read'
	readu,1,megarray
	print,'Finish read'
	megarray=swap_endian(megarray) ;nanonis is big endian
	if ydir eq "down" then megarray=reverse(megarray,4) ;OMG specs!
	ffnite=finite(megarray)
	winf=where(ffnite eq 0) ;tweak for incomplete images
	if not(keyword_set(raw)) then if winf(0) ne -1 then begin
	    avg=min(megarray(where(ffnite)))
	    megarray(winf)=avg
	    print,"pruning out the NANs.."
	end
	
	conversion=1D
	print,'Finish endian swap and other processing'
;img=fltarr(x,y)

for i=0,chn-1 do begin
    if keyword_set(verbose) then print,'Channel:',i
    for j=0,chdirr(i)-1 do begin
	;print,i,j
	img=reform(megarray(i,j,*,*))
	;help,img
	if j eq 1 then img=reverse(img,1)
	;help,where(finite(img) eq 0)
	;img=img;*chcal(i)+choffs(i) ;not sure what is calibration and offset, have to ask
	zsize=abs(max(img)-min(img))
	pzsize="Z Amplitude: "+string(zsize)

	;parameters frenzy, stil inside the for cycle
	if j eq 0 then dir="f" else dir="b"
	if j eq 0 then xdir="forward" else xdir="backward"


	acqsig="Acquisition channel: "+chname(i)
	xscandir="X scanning direction: "+xdir
	
	parstring=[$
	"WSxM file copyright Nanotec Electronica","SxM Image file",$
	;"Image header size: ",$
	"[Control]",current,"Signal Gain: 1",voltage,pxsize,pysize,scanfq,xo,yo,scanangle,$
	"[General Info]",acqsig,date,dur,nrows,ncols,imgdttype,pzsize,xscandir,yscandir,$
	"[Miscellaneous]",com,feed,"[Header end]"]
	newpar=["Filename: "+f+"."+dir+strtrim(string(chnum(i)),2),parstring]
newpar=1
	slice={par:newpar,img:img,zunit:chunit(i),runit:runit,xsize:xsize,ysize:ysize,conversion:conversion,zsize:zsize,datatype:datatype}
;	slice={par:newpar,zunit:chunit(i),runit:runit,xsize:xsize,ysize:ysize,conversion:conversion,zsize:zsize,datatype:datatype}

	if i eq 0 and j eq 0 then stack=slice else stack=[stack,slice]

    end ;direction enfor
end 
end else stack=0 ;main endfor!!!

close,1

return,stack
end
