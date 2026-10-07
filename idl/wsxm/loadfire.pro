function fire2img,x,y,z
;translates three vectors of xyz to an image
;xy must be regularly spaced and ordered by lines

;try to sort
;srt1=sort(y)
;x=x(srt1)
;y=y(srt1)
;z=z(srt1)
;srt2=sort(x)
;x=x(srt2)
;y=y(srt2)
;z=z(srt2)
                      
n=n_elements(z)      

x=x-x[0] ;centering
y=y-y[0]

;guessing dimensions and base vectors..
xl=1L
xdif=1.01*abs(x(1)-x(0)) ;smallest difference of x
help,x(xl+1)
help,x(xl)
help,abs(x(xl+1)-x(xl))

while abs(x(xl+1)-x(xl)) le xdif do begin 
    xl=xl+1
    print,xl,x(xl)
end

print,'asdf'
xl=xl+1

yl=n/xl

print,'Dimensions of array'
print,xl,yl


img=reform(z,xl,yl)                                                             
s=size(img)                 

xll=xl-1; cesar fixed this already! (summer 2013)                                                                        
yll=yl-1;                                                                        

img=img(0:xll-1,0:yll-1) ;some lines are doubled                                

vx2=x[xl-1]      
vx1=x[yl*xl-xll-1] 
vy2=y[xl-1]                                                              
vy1=y[yl*xl-xll-1]

print,'vectors:'
print,vx1,vy1,vx2,vy2

return,{img:img,x:complex(vx1,vy1),y:complex(vx2,vy2)}
end      


function loadfire,f
;reads the FIREBALL stm module output format and returns a structure containing parameters and image
close,/all ; for sure

dummy={par:"Filename: "+f,img:0,zunit:0,runit:0,xsize:0,ysize:0,conversion:0,zsize:0,datatype:0}


if not(File_Test(f)) then return,dummy
print,"Reading "+f

openr,1,f

repeat begin
a=strarr(1)
readf,1,a
endrep until strpos(a,"X[") ne -1 or EOF(1)

if strpos(a,"X[") ne -1 then xunit=strmid(a,strpos(a,"X[")+2,1) else xunit=""
xunit=xunit(0)

if strpos(a,"Z[") ne -1 then zunit=strmid(a,strpos(a,"Z[")+2,1) else zunit=""
zunit=zunit(0)
help,zunit

x=dblarr(1024L^2)
y=x
z=x

repeat begin
a=strarr(1)
readf,1,a
endrep until strtrim(a,2) ne ""

ab=strsplit(a,"\s",/regex,/extract)
x(0)=ab(0)
y(0)=ab(1)
z(0)=ab(2)
counter=1L

xx=0D
yy=0D
zz=0D
WHILE ~ EOF(1) DO BEGIN
	readf,1,xx,yy,zz
	x(counter)=xx
	y(counter)=yy
	z(counter)=zz
	counter=counter+1
end
;rep until counter ge 1024L^2 or EOF(1)

close,1

x=x(0:counter-1)
y=y(0:counter-1)
z=z(0:counter-1)

;srt=sort(y)
;x=x(srt)
;y=y(srt)
;z=z(srt)
;srt=sort(x)
;x=x(srt)
;y=y(srt)
;z=z(srt)

;print,x
;print,y

stimg=fire2img(x,y,z)

img=stimg.img

if zunit eq "A" then begin
    zunit="nA"
    img=img*1E9
end

s=size(img)
xsize=abs(stimg.x)
ysize=abs(stimg.y)
zsize=(max(img)-min(img))

nrows="Number of rows:"+string(s(1))
ncols="Number of columns:"+string(s(2))

xsze="X Amplitude:"+string(xsize)+' '+xunit
ysze="Y Amplitude:"+string(ysize)+' '+xunit
zsze="Z Amplitude:"+string(zsize)+' '+zunit

ax=real_part(stimg.x)
ay=imaginary(stimg.x)
bx=real_part(stimg.y)
by=imaginary(stimg.y)

driftx=(bx*ax+by*ay)/abs(stimg.x)
drifty=(-bx*ay+by*ax)/abs(stimg.y)

driftx=driftx/abs(stimg.x)*s(1)
drifty=drifty/abs(stimg.x)*s(1)-s(2)

par=strarr(6)
par(0)="Filename: "+f
par(1)="Comments: dx,dy: "+string(driftx)+string(drifty)+"("+string(ax)+","+string(ay)+","+string(bx)+","+string(by)+")"
par(2)="Driftx: "+string(driftx)
par(3)="Drifty: "+string(drifty)
par(4)="Acquisition channel: Fireball-STM"
par(5)="Base vectors: ("+string(ax)+","+string(ay)+","+string(bx)+","+string(by)+")"



parstring=[par(0),$
"WSxM file copyright Nanotec Electronica","SxM Image file",$
;"Image header size: ",$
"[Control]","Signal Gain: 1","Topography Bias: 0 mV",xsze,ysze,$
"[General Info]",par(4),"Acquisition time: "+string(systime()),nrows,ncols,"Image Data Type: float",zsze,$
"[Miscellaneous]",par(2),par(3),par(5),par(1),"[Header end]"]

print,parstring

if not(file_test(f+'.flt')) then begin
openw,1,f+'.flt'
printf,1,"fireball 3 "+string(driftx)+" "+string(drifty)
close,1
end

help,img

return,{par:parstring,img:img,zunit:zunit,runit:xunit,xsize:xsize,ysize:ysize,conversion:1D,zsize:zsize,datatype:'double'}
end
