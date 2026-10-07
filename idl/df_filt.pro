pro df_filt,filtw,splines
;utility to filter any curve
openr,1,'in.dat'
x=0
y=0
repeat begin
a=''
readf,1,a
;help,a
;print,a
if (strpos(a,"#") eq -1) then begin
    xy=strsplit(a," ",/extract)
;    help,xy
;    help,xy(0)
;    help,xy(1)
    x=[x,float(xy(0))]
    y=[y,float(xy(1))]
end

endrep until EOF(1)
close,1
x=x(1:*)
y=y(1:*)
n=n_elements(x)
x=x(0:n/2)
y=y(0:n/2)

print,y

;a=read_ascii('in.dat')
;print,"afadfa"

;xy=a.(0)
;x=xy(0,*)
;y=xy(1,*)
;plot,x,y

ny=dezofilter(x,y,width=filtw,splines=splines)

;oplot,x,ny
openw,1,'out.dat'
for i=0,n_elements(x)-1 do printf,1,x(i),ny(i),y(i)
close,1
plot,x,y
oplot,x,ny
;print,'out.dat'
end