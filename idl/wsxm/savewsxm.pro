pro savewsxm,data,f
;makes an autopsy of existing parameters and dumps it into a wsxm file
;corrects the Z amplitude, X, Y amplitude, number of rows and number of columns, adds a comment(?)
;pmdata is the structure

close,/all ; for sure

fpath=getval(data.par,"Filename:")
fb=file_basename(fpath)

if not(keyword_set(f)) then f = dialog_pickfile(/write, /overwrite_prompt,filter='*.top,*.ch0,*.ch1,*.ch2,*.ch3',title='Tell which WSXM file to write',file="mod_"+fb)
if f eq "" then return


par=data.par(1:*) ;cut out the filename
;help,par

;print,par

s=size(data.img)
runit="none"
zunit="none"

;zsize=getval(par,"Z Amplitude:","float",unit=zunit)
;x=getval(par,"Number of columns:","int")
;y=getval(par,"Number of rows:","int")

;xratio=float(x)/s(1)
;yratio=float(y)/s(2)

dataimg=double(data.img)
;dataimg(where(finite(dataimg,/nan)))=mmean(dataimg)
zamp=abs(double(max(dataimg,/nan)-min(dataimg,/nan)))

putval,par,"X Amplitude:",strtrim((data.xsize),2)+" "+data.runit
putval,par,"Y Amplitude:",strtrim((data.ysize),2)+" "+data.runit
putval,par,"Z Amplitude:",strtrim(string(zamp),2)+" "+data.zunit
putval,par,"Number of columns:",strtrim(string(s(1)))
putval,par,"Number of rows:",strtrim(string(s(2)))
putval,par,"Image Data Type:","double"

openw,1,f
for i=0,n_elements(par)-1 do printf,1,par(i)


if data.conversion(0) ne 1D then begin
    print,"CONVERSION IN PLACE!!!"
    rimg=double(dataimg)/data.conversion
end else rimg=dataimg

print,min(rimg,/nan),max(rimg,/nan)


;IMPORTANT!! REVERSAL ONLY FOR IDL!!
rimg=(reverse(rimg,1))
help,rimg
writeu,1,rimg
close,1
;tvscl,rimg
end
