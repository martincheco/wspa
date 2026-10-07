pro slicewsxm,path,slice,xdim=xdim,ydim=ydim,zunit=zunit,chan=chan,bias=bias
;a wrapper for the savewsxm for export of plain data slices
;exports a slice of data to the wsxm format
;xdim ydim are optional dimensions in nm
;zunit is the Z unit
;chan is acq. channel
;bias in mV

slice=reform(double(slice))
s=size(slice)
;help,slice
if not(keyword_set(xdim)) then xdim=s(1)
if not(keyword_set(chan)) then chan='unknown!'
if not(keyword_set(ydim)) then ydim=s(2)
if not(keyword_set(zunit)) then zunit='unknown!'
if not(keyword_set(bias)) then bias=0

bias=string(bias)

runit='nm'

nrows="Number of rows:"+string(s(1))
ncols="Number of columns:"+string(s(2))

zdim=max(slice,/nan)-min(slice,/nan)
;print,'**INFO**',path
;help,zdim
;help,max(slice)
;help,min(slice)
xsze="X Amplitude:"+string(xdim)+' '+runit
ysze="Y Amplitude:"+string(ydim)+' '+runit
zsze="Z Amplitude:"+string(zdim)+' '+zunit


acqchan="Acquisition channel: "+chan


parstring=['Filename: '+ path ,$
"WSxM file copyright Nanotec Electronica","SxM Image file",$
;"Image header size: ",$
"[Control]","Signal Gain: 1","Topography Bias: "+bias+" mV",xsze,ysze,$
"[General Info]",acqchan,"Acquisition time: "+string(systime()),nrows,ncols,"Image Data Type: float",zsze,$
"[Miscellaneous]","[Header end]"]


data={img:slice,runit:'nm',zunit:zunit,conversion:1D,xsize:xdim,ysize:ydim,$
par:parstring,datatype:'short'}

savewsxm,data,path

end
