
function loadcreatek,f,raw=raw
;reads the wsxm format file and returns a structure containing parameters and image
;raw causes the function to return unscaled values
close,/all ; for sure

;open file
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist,filter='*.dat,*.DAT',title='Select a CREATEK DAT file to open')

;in case file does not exist or corrupted
dummy={par:"Filename: "+f,img:0,zunit:0,runit:0,xsize:0,ysize:0,conversion:0,zsize:0,datatype:0}
if not(File_Test(f)) then return,dummy

;reading parameters until binary data
print,"Reading "+f
openr,1,f
par=strarr(999)
counter=-1

repeat begin
    counter=counter+1
    a=strarr(1)
    readf,1,a
    par(counter)=a
endrep until strpos(a,"PSTMAFM") ne -1 or counter gt 997
    
par=par(0:counter+1)
par=shift(par,1)

;getting crucial parameters

par(0)="Filename: "+f
x=getval(par,"Num.X / Num.X=","int")
y=getval(par,"Num.Y / Num.Y=","int")
runit="none"
zunit="none"

xsize=getval(par,"Length x\[A\]=","flt")/10.
ysize=getval(par,"Length y\[A\]=","flt")/10.
runit="nm"
zunit="nm"
datatype="float"

;read parameters to determine total no of images and to assign correct parameters

channels=getval(par,"Channels / Channels=","int")
directions=getval(par,"Scanmode / ScanXMode=","int") ; number of scanning directions
multivoltage=getval(par,"Scantype / Scantype=","int") ; 1 single volt 2 multivolt
feedback=getval(par,"CHmode / CHmode=","int") ;0 const. height 1 const. current
ydir=getval(par,"ScanYDirec / ScanYdirec=","int") ;0 const. height 1 const. current
if ydir eq 0 then ydir="down" else ydir="up"

multiv=intarr(6)
multiv(0)=getval(par,"MVolt_1 / MVolt_1=","int")
multiv(1)=getval(par,"MVolt_2 / MVolt_2=","int")
multiv(2)=getval(par,"MVolt_3 / MVolt_3=","int")
multiv(3)=getval(par,"MVolt_4 / MVolt_4=","int")
multiv(4)=getval(par,"MVolt_5 / MVolt_5=","int")
multiv(5)=getval(par,"MVolt_6 / MVolt_6=","int")

;count of nonzero multi voltages
mw=where(multiv ne 0)
n_multiv=n_elements(mw)

;setting up to read binary data
point_lun,1,0
point_lun,1,16388
yset=0
yn=y

if x gt 0 and y gt 0 then $
for i=0,channels-1 do begin

    img=fltarr(x,y)
    readu,1,img
    
    if not(yset) then for j=y-1,0,-1 do begin
	if total(img(*,j)) ne 0 then begin
	yn=j
	yset=1
	break
	end
    end


    ;kills the zero area
    img=img(*,0:yn)
    ;reverse upside-down
    img=reverse(img,2)

    conversion=1D
    if not(keyword_set(raw)) then begin
	conversion=1D
	; Z conversion = ZPiezoConstant [A/V] * 10[V] * GainZ / (2D^19+1)
	; or           = GainZ * DACtoz[A]
	; I conversion = 10D^GainPreamp [A/V] * 10[V] / (2D^19+1)
	img=img*conversion ; preserves the offset
	zsize=abs(max(img)-min(img))
    end
    

;parameters frenzy, stil inside the for cycle
if directions eq 1 then dir="f" else if i mod 2 eq 0 then dir="f" else dir="b"; here will go specification of a scanning direction
if dir eq "f" then xdir="forward"
if dir eq "b" then xdir="backward"

;voltages and currents, multivoltages not implemented yet!
    voltage="Topography Bias: "+getval(par,"Biasvolt\[mV\]=")+" mV"
    current="Set Point: "+strtrim(string(getval(par,"Current\[A\]=","float")*1e9),2)+" nA"

;date has to be trimmed yet
date="Acquisition time: "+getval(par,"PSTMAFM.EXE_Date=")

pxsize="X Amplitude: "+string(xsize)+" nm";+getval(par,"Length x\[A\]=")/10.+" nm"
pysize="Y Amplitude: "+string(ysize)+" nm";+getval(par,"Length x\[A\]=")/10.+" nm"
zsize="Z Amplitude: 1234"

acqsig="Acquisition channel: unknown"
nrows="Number of rows: "+string(yn)
ncols="Number of columns: "+string(x)
imgdttype="Image Data Type: float"
scanfq="X-Frequency: "+getval(par,"Sec/line:=")+" s"
xscandir="X scanning direction: "+xdir ;has to be corrected in the future
yscandir="Y scanning direction: "+ydir
;scanangle=""

com="Comments: - no comments available -"


parstring=[$
"WSxM file copyright Nanotec Electronica","SxM Image file",$
;"Image header size: ",$
"[Control]",current,"Signal Gain: 1",voltage,pxsize,pysize,scanfq,$
"[General Info]",acqsig,date,nrows,ncols,imgdttype,zsize,xscandir,yscandir,$
"[Miscellaneous]",com,"[Header end]"]
newpar=["Filename: "+f+"."+dir+strtrim(string(i/directions),2),parstring]


slice={par:newpar,img:img,zunit:zunit,runit:runit,xsize:xsize,ysize:ysize,conversion:conversion,zsize:zsize,datatype:datatype}

if i ne 0 then stack=[stack,slice] else stack=slice

end else stack=0;endfor!!!

close,1

return,stack
end
