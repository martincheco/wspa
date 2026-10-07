function loadwsxm,f,raw=raw
;reads the wsxm format file and returns a structure containing parameters and image
;raw causes the function to return unscaled values
close,/all ; for sure
cd,current=c
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist,filter=['*.ch*;*.top;*.stp'],title='Select a WSXM file to open',path=c)


dummy={par:"Filename: "+f,img:0,zunit:0,runit:0,xsize:0,ysize:0,conversion:0,zsize:0,datatype:0}


if not(File_Test(f)) then return,dummy
print,"Reading "+f

openr,1,f
par=strarr(999)
counter=-1

repeat begin
counter=counter+1
a=strarr(1)
if not(EOF(1)) then readf,1,a
par(counter)=a
endrep until strpos(a,"[Header end]") ne -1 or counter gt 997 or EOF(1)
par=par(0:counter+1)
par=shift(par,1)
;print,par
par(0)="Filename: "+f
x=getval(par,"Number of columns:","int")
y=getval(par,"Number of rows:","int")
runit="none"
zunit="none"
xsize=getval(par,"X Amplitude:","float",unit=runit)
ysize=getval(par,"Y Amplitude:","float",unit=runit)
zsize=getval(par,"Z Amplitude:","float",unit=zunit)
datatype=getval(par,"Image Data Type:")
;help,zunit
;help,runit

if x gt 0 and y gt 0 then begin
    case datatype of
	"short":img=intarr(x,y) 
	"float32":img=fltarr(x,y)
	"float":img=fltarr(x,y)
	"double":img=dblarr(x,y)
	"float64":img=dblarr(x,y)
	"long":img=lonarr(x,y) 
	else: img=intarr(x,y) 
    endcase
    readu,1,img
    ;IMPORTANT!! REVERSAL ONLY FOR IDL!!
    img=reverse(img,1)
end else img=0

close,1

conversion=1D
if not(keyword_set(raw)) then begin
conversion=double(zsize)/(double(max(img))-double(min(img)))
img=double(img)*conversion ; preserves the offset
end
help,conversion
return,{par:par,img:img,zunit:zunit,runit:runit,xsize:xsize,ysize:ysize,conversion:conversion,zsize:zsize,datatype:datatype}
end
