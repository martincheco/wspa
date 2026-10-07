function omi_par,a,i

tparams=a.parameters.topography(i)
p=a.parameters

;voltages and currents
if tparams.direction eq 'forward' then begin
    voltage="Topography Bias: "+string(p.voltageforward*1000)+" mV"
    current="Set Point: "+string(p.currentforward)+" nA"
end else begin
    voltage="Topography Bias: "+string(p.voltagebackward*1000)+" mV"
    current="Set Point: "+string(p.currentbackward)+" nA"
end

date="Acquisition time: "+p.time
xsize="X Amplitude: "+string(p.xpixels*p.incrementx)+" nm"
ysize="Y Amplitude: "+string(p.ypixels*p.incrementy)+" nm"
zsize="Z Amplitude: 1234"

acqsig="Acquisition channel: "+tparams.type
nrows="Number of rows: "+string(p.xpixels)
ncols="Number of columns: "+string(p.ypixels)
imgdttype="Image Data Type: short"
scanfq="X-Frequency: "+string(p.scanspeed/p.xpixels*p.incrementx)+" Hz"
xscandir="X scanning direction: "+tparams.direction
;yscandir="Y scanning direction: unknown"
;scanangle=""

com="Comments: "+p.comment


parstring=[$
"WSxM file copyright Nanotec Electronica","SxM Image file",$
;"Image header size: ",$
"[Control]",current,"Signal Gain: 1",voltage,xsize,ysize,scanfq,$
"[General Info]",acqsig,date,nrows,ncols,imgdttype,zsize,xscandir,$
"[Miscellaneous]",com,"[Header end]"]

;ln=string(total(strlen(parstring))+n_elements(parstring))
;ln=ln+strlen(ln)

;parstring=["Imported from Omicron STM file format","SxM Image file",$
;"Image header size: "+ln,$
;parstring(2:*)]

return,parstring

end

function loadomicron,f,raw=raw,preselect=preselect

a=loadstm(f(0))

if n_tags(a) eq 0 or ptr_valid(a.images(0)) eq 0 then return,0

p=a.parameters
chan=p.topography.type
;help,chan
;help,p.tchannels
w=-1
cc=0
if (keyword_set(preselect)) then $
for i=0,p.tchannels-1 do begin
    chan(i)=strtrim(chan(i),2)
    if where(preselect eq chan(i)) ne -1 then begin
	;print,chan(i),i,cc+1
	w=[w,i]
	cc=cc+1
    end    
end
;print,w,cc
;help,w
if cc ne 0 then w=w(1:cc) else w=indgen(p.tchannels)

for ii=0,n_elements(w)-1 do $
begin
    i=w(ii)
    ;print,strtrim(chan(i),2)
    img=*(a.images)(i) ;for raw, later recalculated
    datatype='short'
    conversion=1D
    
    tparams=a.parameters.topography(i)
    fname=a.dir+tparams.filename
    par=["Filename: "+fname,omi_par(a,i)]
    zunit=tparams.unit
    runit='nm'
    xsize=p.xpixels*p.incrementx
    ysize=p.ypixels*p.incrementy
    
    if not(keyword_set(raw)) then begin
	conversion=tparams.resolution
	img=double(img)*conversion ; preserves the offset
	datatype='short'
    end

    zsize=max(img)-min(img)

    slice={par:par,img:img,zunit:zunit,runit:runit,xsize:xsize,ysize:ysize,conversion:conversion,zsize:zsize,datatype:datatype}
    if i ne w(0) then stack=[stack,slice] else stack=slice
end

return,stack
end
