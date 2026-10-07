
function loadtxt,f,x=x,y=y,m=m,n=n
;reads a txt file with a header (or w/o header)
;x,y are physical dimensions (otherwise from a header or wild-guessed)
;m,n are physical dimensions (otherwise from a header or wild-guessed)



dummy={par:"Filename: "+f,img:0,zunit:0,runit:0,xsize:0,ysize:0,conversion:0,zsize:0,datatype:0}


if not(File_Test(f)) then begin
	print,'File not real, returning dummy'
	return,dummy
end
print,"Reading "+f

openr,1,f

hdr=strarr(1000)
c=0
repeat begin
	a=strarr(1)
	readf,1,a
	aa=strtrim(a,2)
	if (strmid(aa,0,1) eq "#") then begin
		hdr(c)=strtrim(strmid(a,1),2)
		if c lt 999 then c++
	end else break
endrep until EOF(1) 

if c gt 0 then hdr=hdr(0:c-1) else hdr=""

print,hdr

if hdr(0) eq "" then begin
	data=[strtrim(a,2)]
	repeat begin
		a=strarr(1)
		readf,1,a
		aa=strtrim(a,2)
		data=[data,aa]
	endrep until EOF(1)
	close,1

	ssplit=strsplit(data(0),/extract)
	if ssplit(0) ne -1 then begin
		m=n_elements(ssplit)
		n=n_elements(data)
		img=dblarr(m,n)
		for i=0,n-1 do begin
			ssplit=strsplit(data(i),/extract)
			img(*,i)=ssplit
		end
		dims=[m,n]
		pdims=[m,n]
		print,dims
		xunit="nm"
		zunit=""
		xsize=pdims(0)
		ysize=pdims(1)
		zsize=(max(img)-min(img))
		nrows="Number of rows:"+string(dims(0))
		ncols="Number of columns:"+string(dims(1))
	
		xsze="X Amplitude:"+string(xsize)+' '+xunit
		ysze="Y Amplitude:"+string(ysize)+' '+xunit
		zsze="Z Amplitude:"+string(zsize)+' '+zunit

		par=strarr(6)
		par(0)="Filename: "+f
		par(1)="Comments: from TXT file"
		par(2)="Acquisition channel: Nil"


		parstring=[par(0),$
		"WSxM file copyright Nanotec Electronica","SxM Image file",$
		;"Image header size: ",$
		"[Control]","Signal Gain: 1","Topography Bias: 0 mV",xsze,ysze,$
		"[General Info]","Acquisition time: "+string(systime()),nrows,ncols,"Image Data Type: float",zsze,$
		"[Miscellaneous]",par(2),par(1),"[Header end]"]


		return,{par:parstring,img:img,zunit:zunit,runit:xunit,xsize:xsize,ysize:ysize,conversion:1D,zsize:zsize,datatype:'double'}
	


	end else begin
		print,'empty first line? returning dummy'
		return,dummy
	end

end


close,1






dims=strsplit(hdr[0],/extract)
print,dims

ee=0.
bb=0.
nm=0.

if n_elements(hdr) gt 1 then pdims=strsplit(hdr[1],/extract) else pdims=dims
if n_elements(hdr) gt 2 then begin
	ee=getval(hdr,'Energy:')
	bb=getval(hdr,'Bias:')
	nm=getval(hdr,'Wavelength:')
end

help,ee
print,ee
help,bb
help,nm

if bb eq "" then bb='0'
if ee eq "" then ee='0'
if nm eq "" then nm='0'


print,pdims(0),pdims(1)



img=fltarr(dims(0),dims(1))
openr,1,f
for i=0,c-1 do readf,1,a

readf,1,img

close,1

xunit="nm"
zunit=""

xsize=pdims(0)
ysize=pdims(1)
zsize=(max(img)-min(img))

nrows="Number of rows:"+string(dims(0))
ncols="Number of columns:"+string(dims(1))

xsze="X Amplitude:"+string(xsize)+' '+xunit
ysze="Y Amplitude:"+string(ysize)+' '+xunit
zsze="Z Amplitude:"+string(zsize)+' '+zunit

par=strarr(6)
par(0)="Filename: "+f
par(1)="Comments: from TXT file"
par(2)="Acquisition channel: Nil"
par(3)="Energy: "+ee+" eV"
par(4)="Wavelength: "+nm+" nm"



parstring=[par(0),$
"WSxM file copyright Nanotec Electronica","SxM Image file",$
;"Image header size: ",$
"[Control]","Signal Gain: 1","Topography Bias: "+bb+" mV",xsze,ysze,$
"[General Info]","Acquisition time: "+string(systime()),nrows,ncols,"Image Data Type: float",zsze,$
"[Miscellaneous]",par(2),par(1),par(3),par(4),"[Header end]"]


return,{par:parstring,img:img,zunit:zunit,runit:xunit,xsize:xsize,ysize:ysize,conversion:1D,zsize:zsize,datatype:'double'}
end
