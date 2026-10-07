function inqvar,fid,varname,str=str
varid=ncdf_varid(fid,varname)
help,varid
if varid ne -1 then ncdf_varget,fid,varid,var else var=0
if keyword_set(str) then var=strtrim(string(var),2)
return,var
end


function loadgsxm,f
;reads the gsxm format file and returns a structure containing parameters and image
close,/all ; for sure

;open file
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist,filter='*.nc',title='Select a GSXM NetCDF file to open')

;in case file does not exist or corrupted
dummy={par:"Filename: "+f,img:0,zunit:0,runit:0,xsize:0,ysize:0,conversion:0,zsize:0,datatype:0}
if not(File_Test(f)) then return,dummy

;reading the ncdf
print,"Reading "+f
fid=ncdf_open(f)

;getting crucial parameters and image

x=inqvar(fid,"dimx")
y=inqvar(fid,"dimy")
runit="nm" ;we divide ranges
zunit="V"

xsize=inqvar(fid,"rangex")/10.
ysize=inqvar(fid,"rangey")/10.

datatype="float"

img=inqvar(fid,"FloatField")
conversion=1D

dz=inqvar(fid,"dz")
img=img*dz

acqchan="unknown"

if strpos(strlowcase(file_basename(f)),"topo",/reverse_search) gt -1 then begin
    zunit="nm" ;check the Z if it is in Volts or Angstroms
    img=img/10.
    acqchan="Topography"
end

if strpos(strlowcase(file_basename(f)),"tunnel",/reverse_search) gt -1 then begin ;check the Z if it is in Volts or Angstroms
    print,"yes"
    zunit="nA" 
    acqchan="Current"
end

help,acqchan

zsize=abs(max(img)-min(img))

;parameters frenzy
if strpos(f,"-Xm-",/reverse_search) then dir="b" else dir="f";scanning direction, needs more work
if dir eq "f" then xdir="forward"
if dir eq "b" then xdir="backward"
xscandir="X scanning direction: "+xdir

;voltages and currents
voltage="Topography Bias: "+inqvar(fid,"sranger_mk2_hwi_bias",/str)+" V"
current="Set Point: "+inqvar(fid,"sranger_mk2_hwi_mix0_current_set_point",/str)+" nA"

;this date might be bad for sorting
date="Acquisition time: "+inqvar(fid,"t_start",/str)

pxsize="X Amplitude: "+string(xsize)+" nm"
pysize="Y Amplitude: "+string(ysize)+" nm"
zsize="Z Amplitude: "+ string(zsize)+" nm"

acqsig="Acquisition channel: "+acqchan
nrows="Number of rows: "+string(y)
ncols="Number of columns: "+string(x)
imgdttype="Image Data Type: float"
scanfq="X-Frequency: "+strtrim(string(inqvar(fid,"sranger_mk2_hwi_scan_speed_x")/x),2)+" s"
;scanangle=""

;com=inqvar(fid,"comment") ;bug in gdl, unused
com="- not available -"

parstring=[$
"WSxM file copyright Nanotec Electronica","SxM Image file",$
;"Image header size: ",$
"[Control]",current,"Signal Gain: 1",voltage,pxsize,pysize,scanfq,$
"[General Info]",acqsig,date,nrows,ncols,imgdttype,zsize,xscandir,$
"[Miscellaneous]",com,"[Header end]"]
newpar=["Filename: "+f,parstring]


slice={par:newpar,img:img,zunit:zunit,runit:runit,xsize:xsize,ysize:ysize,conversion:conversion,zsize:zsize,datatype:datatype}

ncdf_close,fid

return,slice
end
