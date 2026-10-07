
function load3ds,f
;reads the NANONIS SXM format file and returns a structure containing parameters and image
;verbose - prints more info while loading channles
;spectrum - named var for reading of channels that represent photon spectra

close,/all ; for sure

;open file
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist,filter=['*.3ds','*.3DS'],title='Select a NANONIS file to open')

f=repstr(f,' ','\ ')

;in case file does not exist or corrupted
dummy={par:f,stack:0,chans:0}
if not(File_Test(f)) then return,dummy

;reading parameters until binary data
print,"Reading "+f
openr,1,f
par=strarr(3999)
counter=-1L

repeat begin
    counter=counter+1
    a=strarr(1)
    readf,1,a
    par(counter)=a
endrep until strpos(a,":HEADER_END:") ne -1 or counter gt 3997

print,"Header counter: ",counter+1

a=0B

;adjust read position to the data beginning
;print,'bytes after header end'
;repeat begin
;    ad=a
;    a=0B
;    readu,1,a
;    ;print,a
;endrep until ad eq 26B and a eq 4B
;print,'found image start'
par=par(0:counter+1)
par=shift(par,1)
;paru=STRUPCASE(par)
par(0)="Filename: "+f
;getting crucial parameters


xy=getval(par,"Grid dim=")
xy=repstr(xy,'"','')
xy=strsplit(xy,'x',/extract)
x=round(fix(strtrim(xy(0),2)))
y=round(fix(strtrim(xy(1),2)))

z=getval(par,'Points=')
z=repstr(z,'"','')
z=round(long(z))

print,'Dimensions:',x,y,z


chans=getval(par,'Channels=')
chans=repstr(chans,'"','')
chans=strsplit(chans,';',/extract)

help,chans

swsig=getval(par,'Sweep Signal=')
swsig=repstr(swsig,'"','')

fpars=getval(par,'Fixed parameters=')
fpars=repstr(fpars,'"','')
fpars=strsplit(fpars,';',/extract)

help,fpars

epars=getval(par,'Experiment parameters=')
epars=repstr(epars,'"','')
epars=strsplit(epars,';',/extract)

help,epars


esize=getval(par,'Experiment size \(bytes\)=')
help,esize
esize=round(long(esize))

help,esize

if epars(0) ne "" then n_epars=n_elements(epars) else n_epars=0
if fpars(0) ne "" then n_fpars=n_elements(fpars) else n_fpars=0

epsize=(n_epars + n_fpars + z*n_elements(chans))

;allocate array
;grid=fltarr(y,x,z,n_elements(chans))
;grid=fltarr(z,n_elements(chans),x,y)

xysize=getval(par,"Grid settings=")
xysize=float(strsplit(xysize,';',/extract))


date=getval(par,"Start time=")
date=repstr(date,'"')
;print,date
date=strsplit(date,' ',/extract)

date0=date(0)
time0=date(1)

help,date0
help,time0

date1=strsplit(date0,'.',/extract)
date="Acquisition time: "+date1(2)+'-'+date1(1)+'-'+date1(0)+' '+time0

print,'Reading the binary data..'
grid=fltarr(epsize,x,y)
help,grid


np=n_epars+n_fpars
nch=n_elements(chans)

readu,1,grid
close,1
grid=swap_endian(grid)

params = reform(grid(0:np-1,*,*))
gridrest=grid(np:*,*,*)

;for j=0,nch-1 do begin
;	print,j
;        ;extract data for each channel
;        start_ind = np + j * z
;        stop_ind = np + (j+1) * z
;        stack(*,*,*,j) = grid(*,*, start_ind:stop_ind-1)

;end
help,gridrest

stack=reform(gridrest,z,nch,x,y)


help,stack


return,{stack:stack,xysize:xysize,chans:chans,date:date,swsig:swsig,par:par,epars:epars,fpars:fpars,params:params,raw:grid}
end
