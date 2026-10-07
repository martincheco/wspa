function xsf_moveto,str,lun,lim
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
lim=999 ; max header length

if not(File_Test(f)) then return,dummy
print,"Reading "+f

openr,lun,f
if not(xsf_moveto("BEGIN_DATAGRID_3D",lun,lim)) then return,-1
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
help,data
readf,lun,data
;data=reform(data,n(0),n(1),1)

xi=dindgen(n(2))*x(2)/n(2)+o(2)
yi=dindgen(n(0))*y(0)/n(0)+o(0)
zi=dindgen(n(1))*z(1)/n(1)+o(1)
close,1
return,{n:n,x:xi,y:yi,z:zi,data:transpose(data,[2,0,1])}
end

