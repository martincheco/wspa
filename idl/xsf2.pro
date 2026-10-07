function moveto,str,lun,lim
counter=-1
repeat begin
counter=counter+1
a=strarr(1)
readf,lun,a
endrep until strpos(a,str) ne -1 or counter+1 gt lim or eof(lun)
if eof(lun) or counter+1 gt lim then return,-1 else return,1
end

function xsf_read,f

close,/all ; for sure
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist,filter='*.xsf',title='Select a XSF file to open')

dummy=0
lun=1
lim=9999 ; max header length

if not(File_Test(f)) then return,dummy
print,"Reading "+f

openr,lun,f
if not(moveto("BEGIN_DATAGRID_3D",lun,lim)) then return,-1
n=intarr(3)
readf,lun,n
help,n
x=dblarr(3)
o=x
y=x
z=y
readf,lun,o
readf,lun,y
readf,lun,z
readf,lun,x
data=fltarr(n(0),n(1),n(2))
print,n,y,z,x

readf,lun,data


xi=dindgen(n(2))*x(2)/n(2)+o(2)
yi=dindgen(n(0))*y(0)/n(0)+o(0)
zi=dindgen(n(1))*z(1)/n(1)+o(1)
close,1
return,{n:n,x:xi,y:yi,z:zi,data:transpose(data,[2,0,1])}
end

pro xsfview,t,x=x,y=y,z=z,rx=rx,ry=ry,rz=rz,iso=iso,invert=invert,save=save,histx=histx

if not(keyword_set(x) or keyword_set(y) or keyword_set(z)) then zz=1 else zz=0

if not(keyword_set(rx)) then rx=[min(t.x),max(t.x)]
if not(keyword_set(ry)) then ry=[min(t.y),max(t.y)]
if not(keyword_set(rz)) then rz=[min(t.z),max(t.z)]

wrx0=where(abs(t.x-rx(0)) eq min(abs(t.x-rx(0))))
wrx1=where(abs(t.x-rx(1)) eq min(abs(t.x-rx(1))))
wrx0=wrx0(0)
wrx1=wrx1(0)
wry0=where(abs(t.y-ry(0)) eq min(abs(t.y-ry(0))))
wry1=where(abs(t.y-ry(1)) eq min(abs(t.y-ry(1))))
wry0=wry0(0)
wry1=wry1(0)
wrz0=where(abs(t.z-rz(0)) eq min(abs(t.z-rz(0))))
wrz1=where(abs(t.z-rz(1)) eq min(abs(t.z-rz(1))))
wrz0=wrz0(0)
wrz1=wrz1(0)

if keyword_set(x) then begin
    w=where(abs(t.x-x) eq min(abs(t.x-x)))
    print,w
    if w(0) ne -1 then data=t.data(w(0),wry0:wry1,wrz0:wrz1) else return
    a=t.y(wry0:wry1)
    b=t.z(wrz0:wrz1)
;    xrange=ry
;    yrange=rz
print,"x: ",t.x(w(0))
end
if keyword_set(y) then begin
    w=where(abs(t.y-y) eq min(abs(t.y-y)))
    if w(0) ne -1 then data=t.data(wrx0:wrx1,w(0),wrz0:wrz1) else return
    a=t.x(wrx0:wrx1)
    b=t.z(wrz0:wrz1)
;    xrange=rx
;    yrange=rz
print,"y: ",t.y(w(0))
end
if keyword_set(z) or zz eq 1 then begin
    if not(keyword_set(z)) then z=0
    w=where(abs(t.z-z) eq min(abs(t.z-z)))
    if w(0) ne -1 then data=t.data(wrx0:wrx1,wry0:wry1,w(0)) else return
    a=t.x(wrx0:wrx1)
    b=t.y(wry0:wry1)
;    xrange=rx
;    yrange=ry
print,"z: ",t.z(w(0))
end

data=reform(data)
if keyword_set(histx) then data=histxpand(data)
if keyword_set(invert) then data=-data
;if keyword_set(sym) then contour,data+reverse(data,2),a,b,nlevels=255,/cell_fill,iso=iso,xst=1,yst=1 else $


contour,data,a,b,nlevels=255,/fill,iso=iso,xst=1,yst=1,background=255,color=0,position=[0.1,0.1,0.95,0.95]
if keyword_set(save) then begin
	print,"saving"

	if keyword_set(x) then f=strtrim(save,2)+"x"+strtrim(string(t.x(w(0)),format='(F5.1)'),2)+".png"
	if keyword_set(y) then f=strtrim(save,2)+"y"+strtrim(string(t.y(w(0)),format='(F5.1)'),2)+".png"
	if keyword_set(z) then f=strtrim(save,2)+"z"+strtrim(string(t.z(w(0)),format='(F5.1)'),2)+".png"

	a=tvrd(0,true=1)
	write_png,f,a
end

end

function symetrize,t,x=x,y=y,z=z
;symetrizes two-domain structures etc.
tt=t
if keyword_set(x) then tt.data=tt.data+reverse(tt.data,1)
if keyword_set(y) then tt.data=tt.data+reverse(tt.data,2)
if keyword_set(z) then tt.data=tt.data+reverse(tt.data,3)
return,tt
end

function mirror,t,x=x,y=y,z=z
;experimental only
if keyword_set(x) then data=[reverse(t.data,1),t.data]
if keyword_set(y) then data=[[reverse(t.data,2)],[t.data]]
if keyword_set(z) then data=[[[reverse(t.data,3)]],[[t.data]]]

tx=t.x
ty=t.y
tz=t.z

if keyword_set(x) then tx=[-reverse(tx),tx]
if keyword_set(y) then ty=[-reverse(ty),ty]
if keyword_set(z) then tz=[-reverse(tz),tz]

return,{data:data,n:t.n,x:tx,y:ty,z:tz}
end

function transp,t,x=x,y=y,z=z

xi=t.x
yi=t.y
zi=t.z

if(keyword_set(z)) then begin
	xi=t.y
	yi=t.x
data=transpose(t.data,[1,0,2])
end

if(keyword_set(y)) then begin
	zi=t.x
	xi=t.z
data=transpose(t.data,[2,1,0])
end

if(keyword_set(x)) then begin
	zi=t.y
	yi=t.z
data=transpose(t.data,[0,2,1])
end

return,{data:data,n:t.n,x:xi,y:yi,z:zi}
end

;pro xsfview,t
;a=xsf_read()
;help,a,/struct
;xvolume,bytscl(a.data),scale=0.8,/interpolate
;end
