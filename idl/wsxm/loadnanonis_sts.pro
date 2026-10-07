function loadnanonis_sts,f,head=head,units=units,silent=silent
;reads the NANONIS DAT format file and returns a structure containing parameters and image
;head reads only the header
;units tries to get the right unit suffixes

;open file
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist,filter=['*.dat','*.DAT'],title='Select a NANONIS DAT file to open')

;in case file does not exist or corrupted
dummypar={f:f,x:0,y:0,z:0,type:'absolute',exptype:'none',date:'1970.01.01 00:00:00',runit:'m'}
dummy={p:dummypar,data:0,units:0}

f=repstr(f,' ','\ ')

if not(File_Test(f)) then return,dummy
print,File_Test(f)
print,'Fine'

;reading parameters until binary data
if not(keyword_set(silent)) then print,"Reading "+f
openr,1,f,width=1024

if EOF(1) then begin
	close,1
	return,dummy
end

par=strarr(999)
counter=-1



repeat begin
    counter=counter+1
    a=strarr(1)
    readf,1,a
    par(counter)=a
;print,counter
endrep until strpos(a,"[DATA]") ne -1 or counter ge 998 or EOF(1)

if EOF(1) or counter ge 998 then begin
    close,1
    return,dummy
end

a=0B

;adjust read position to the data beginning
par=par(0:counter+1)
par=shift(par,1)

;getting crucial parameters
par(0)="Filename: "+f(0)
x=getval(par,"X \(m\)","dbl")
;help,x
y=getval(par,"Y \(m\)","dbl")
;help,y
z=getval(par,"Z \(m\)","dbl")
bias=getval(par,"Bias>Bias \(V\)","float")

;help,x
;help,y
;help,z

exptype=getval(par,"Experiment	") ;get type of experiment
date=getval(par,"Date") ;most important
if date(0) eq "" then date=getval(par,"Start time") ;most important



date0=strsplit(date,' ',/extract)
date1=strsplit(date0(0),'.',/extract)
date=date1(2)+'-'+date1(1)+'-'+date1(0)+' '+date0(1)

channels=''
readf,1,channels
data=0
;units=0
;print,"HERE"
;print,channels
chans=strsplit(channels,"	",/regex,/extract)



;print,chans
;help,chans

n=n_elements(chans)

if not finite(x) or x eq 0.0 then begin
    wx = where(strpos(chans, "X (m)") ne -1, countx)
    if countx gt 0 then begin
        on_ioerror, skip_datalne
        datline = ""
        readf, 1, datline
        lne = strsplit(datline, "	", /extract)
        if n_elements(lne) gt wx(0) then x = double(lne(wx(0)))
        wy = where(strpos(chans, "Y (m)") ne -1, county)
        if county gt 0 and n_elements(lne) gt wy(0) then y = double(lne(wy(0)))
        wz = where(strpos(chans, "Z (m)") ne -1, countz)
        if countz gt 0 and n_elements(lne) gt wz(0) then z = double(lne(wz(0)))
        skip_datalne:
    endif
endif

data=0

inttime=0
settime=0
bwd=0

if not(keyword_set(head)) then begin
    lne=dblarr(n)
    counter=0
    data=lne
    repeat begin
	counter=counter+1
	readf,1,lne
	data=[[data],[lne]]
    endrep until EOF(1)
    close,1

    data=data(*,1:*)

    settime=getval(par,'Settling time \(s\)','float')
    inttime=getval(par,'Integration time \(s\)','float')

    ;s=size(data)

    ;seems like unnecessary
    ;if exptype eq "Z spectroscopy" then begin 
    ;chans=["Z (m)",chans]
    ;zoffs=getval('Z offset \(m\)','float')
    ;zsweep=getval('Z sweep distance \(m\)','float')
    ;z=zsweep*dindgen(s(2))/s(2)+zoffs
    ;z=reform(z,1,s(2))
    ;help,data
    ;help,z
    ;data=[z,data]
    ;end
    w = strpos(channels,"[bwd]") 
    if w(0) ne -1 then bwd=1 else bwd=0

end

close,1

;experimental
if keyword_set(units) then begin
    units=strarr(n)
    for i=0,n-1 do begin
	ss=strsplit(chans(i),'\(|\)',/regex,/extract)
	chans(i)=strtrim(ss(0),2)
	units(i)=strtrim(ss(1),2)
	

    end
;    print,units
end else units=0

p={f:f,x:x,y:y,z:z,bias:bias,type:'absolute',exptype:exptype,date:date,runit:'m',par:par,settime:settime,inttime:inttime,bwd:bwd}

stack={p:p,data:data,units:units,chans:chans}


return,stack
end
