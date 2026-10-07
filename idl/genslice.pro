function take_vect,a,b
;takes parameters for a from b
return,{at:a.at,xy:a.xy,z:a.z,x:b.x,y:b.y,e:b.e,f:b.f,zz:a.zz}
end

function vector,indices,a,b
;base vectors x indices = lattice vector
aa=a*real_part(indices)+b*imaginary(indices)
return,aa
end


function rot_v,v,rot
;rotates only a vector
i=complex(0.,1.)
return,v*exp(i*rot*!PI/180.)
end

function mirror_c,s,x=x,y=y
sn=s
if keyword_set(x) then begin
sn.xy=complex(-s.xy,imaginary(s.xy))
sn.x=complex(-s.x,imaginary(s.x))
sn.y=complex(-s.y,imaginary(s.y))
end 
if keyword_set(y) then begin
sn.xy=complex(s.xy,-imaginary(s.xy))
sn.x=complex(s.x,-imaginary(s.x))
sn.x=complex(s.y,-imaginary(s.y))
end

return,sn
end

function shift_c,s,vect
;shifts a structure by vect(complex)
return,{at:s.at,xy:s.xy+vect,z:s.z,e:s.e,f:s.f,x:s.x,y:s.y,zz:s.zz}
end



function rot_c,s,rot
;rotates all the structure
p={at:s.at,xy:s.xy,z:s.z,e:s.e,f:s.f,x:s.x,y:s.y,zz:s.zz}
p.xy=rot_v(s.xy,rot)
;p.e=rot_v(s.e,rot)
;p.f=rot_v(s.f,rot)

p.x=rot_v(s.x,rot)
p.y=rot_v(s.y,rot)
return,{at:p.at,xy:p.xy,z:p.z,e:p.e,f:p.f,x:p.x,y:p.y,zz:p.zz}
end

function repeat_c,st,n,m
;repeats the structure n times in the direction defined by e and m times by f
if n lt 1 or m lt 1 then return,st

sx=vector(st.e,st.x,st.y)
sy=vector(st.f,st.x,st.y)

copy=st
row=copy
if m gt 1 then for i=1,m-1 do begin
copy.xy=copy.xy+sx
row=merge_c(row,copy)
end


res=row

if n gt 1 then for j=1,n-1 do begin
row.xy=row.xy+sy
res=merge_c(res,row)
end


res.e=res.e*m
res.f=res.f*n

return,res
end

function match_c,s,l,scale=scale
;rotates and scales two supercells to match, second is the ref

ss=vector(s.f,s.x,s.y)+vector(s.e,s.x,s.y)
ll=vector(l.f,l.x,l.y)+vector(l.e,l.x,l.y)

if keyword_set(scale) then conv=ll/ss else conv=(ll/abs(ll))/(ss/abs(ss))
ns=s
ns.xy=ns.xy*conv
ns.x=ns.x*conv
ns.y=ns.y*conv

return,ns
end

function merge_c,a,b
return,{at:[a.at,b.at],xy:[a.xy,b.xy],z:[a.z,b.z],e:a.e,f:a.f,x:a.x,y:a.y,zz:a.zz}
end

function cut_c,a,plane,cutoff,dir
;cuts off atoms below one of three planes x,y,z below cutoff
if not(keyword_set(cutoff)) then cutoff=0

if not(keyword_set(dir)) then dir=1
ind=-1
if plane eq "x" then ind=where((real_part(a.xy)-cutoff)*dir gt 0.)
if plane eq "y" then ind=where((imaginary(a.xy)-cutoff)*dir gt 0.)
if plane eq "z" then ind=where((real_part(a.z)-cutoff)*dir gt 0.)
if ind(0) ne -1 then print,n_elements(ind)," atoms selected" else print,"no atoms selected"
if ind(0) ne -1 then return,{at:a.at(ind),xy:a.xy(ind),z:a.z(ind),e:a.e,f:a.f,x:a.x,y:a.y,zz:a.zz} else return,a

end

function crop_c,a,x1,x2,y1,y2,z1,z2
	help,x1
	an=cut_c(a,'x',x1,1)
	an=cut_c(an,'x',x2,-1)
	an=cut_c(an,'y',y1,1)
	an=cut_c(an,'y',y2,-1)

	an.x=complex(x2-x1,0)
	an.y=complex(0,y2-y1)
	an.e=complex(1,0)
	an.f=complex(0,1)
	an.xy=an.xy-complex(x1,y1)
	if keyword_set(z1) and keyword_set(z2) then begin
		an=cut_c(an,'z',z1,1)
		an=cut_c(an,'z',z2,-1)
		an.zz=z2-z1
		an.zz=an.zz-z1
	end

return,an
end

function trans_c,st,v
;translate by v
return,{at:st.at,xy:st.xy+v,z:st.z,e:st.e,f:st.f,x:st.x,y:st.y,zz:st.zz}
end


function ztrans_c,st,dz
;translate by v
return,{at:st.at,xy:st.xy,z:st.z+dz,e:st.e,f:st.f,x:st.x,y:st.y,zz:st.zz}
end


function scale_c,st,f
;scales by factor f
return,{at:st.at,xy:st.xy*f,z:st.z*f,e:st.e,f:st.f,x:st.x*f,y:st.y*f,zz:f*st.zz}
end



function genslice,x1a,y1a,x2a,y2a,ei,ej,fi,fj,dim=dim,cart=cart,at=at,offs=offs,zz=zz
;constructs a grid specified by vectors (x1,y1),(x2,y2)
;dim is the number of cells to be used
;cart specifies that x1,y1,x2,y2 are in cartesian instead of radial coords r1,a1,r2,a2
;ei ej fi fj are vectors of the supercell
;at type of atom (Z)
;offs ([xo,yo) gives the lattice an offset specified by fractions of lattice vectors 
;zz is an optional zz direction periodicity
;Silicon as default
if not(keyword_set(at)) then at=12

;cplx unit
i=dcomplex(0.,1.)
 
col1=255


ei=round(ei)
ej=round(ej)
fi=round(fi)
fj=round(fj)


x1=double(x1a)
x2=double(x2a)
y1=double(y1a)
y2=double(y2a)

if not(keyword_set(cart)) then begin
    
    mm=x1*exp(i*y1*!PI/180.)
    x1=real_part(mm)
    y1=imaginary(mm)
    nn=x2*exp(i*y2*!PI/180.)
    x2=real_part(nn)
    y2=imaginary(nn)
end

;supercell vectors
help,ei
help,ej
a=vector(dcomplex(ei,ej),dcomplex(x1,y1),dcomplex(x2,y2))


;decomposing them into cartesian components
ai=real_part(a)
aj=imaginary(a)

b=vector(dcomplex(fi,fj),dcomplex(x1,y1),dcomplex(x2,y2))

bi=real_part(b)
bj=imaginary(b)


;dimension of the lattice used for carving the supercell
if not(keyword_set(dim)) then dim=max(abs([ei,ej,fi,fj]))*2
help,dim
;dim=round(dim)
;indices generation
ix=lindgen((dim*2)^2)
ii=ix / (2*dim)
jj=ix mod (2*dim)
ii=ii-dim
jj=jj-dim

;just for sure
ai=ai(0)
aj=aj(0)
bi=bi(0)
bj=bj(0)

;lattice construction
v=vector(dcomplex(ii,jj),dcomplex(x1,y1),dcomplex(x2,y2))
if keyword_set(offs) then v=v+offs(0)*dcomplex(x1,y1)+offs(1)*dcomplex(x2,y2)

;decompose it for a plot
vi=real_part(v)
vj=imaginary(v)

plot,vi,vj,psym=3,/iso
oplot,[0,ai,ai+bi,bi,0.],[0,aj,aj+bj,bj,0.],psym=-3

il=1E-4 ;eliminates numerical errors
;selection of the points within the supercell
pa=(vi*aj-vj*ai)
ca=double(bi*aj-bj*ai)
wa=where(pa le 0. and pa gt ca+il)
if wa(0) eq -1 then wa=where(pa ge 0. and pa lt ca-il)

vi=vi(wa)
vj=vj(wa)
;oplot,vi,vj,psym=6


pb=(vi*bj-vj*bi)
cb=double(ai*bj-aj*bi)
wb=where(pb ge 0. and pb lt cb-il)
if wb(0) eq -1 then wb=where(pb le 0. and pb gt cb+il)

vi=vi(wb)
vj=vj(wb)

oplot,vi,vj,psym=6

if not(keyword_set(zz)) then zz=0./0.

return,{at:replicate(at,n_elements(vi)),xy:complex(vi,vj),z:fltarr(n_elements(vi)),$
e:complex(ei,ej),f:complex(fi,fj),x:complex(x1,y1),y:complex(x2,y2),zz:zz}
;at - vector of proton numbers
;xy - complex vectors, lattice pts positions in xy plane
;z -  vector of z coordinates
;x, y - starting lattice vectors
;e, f - indices of the supercell
;THE SUPERCELL VECTORS ARE GOING TO BE CALCULATED EVERY TIME AGAIN USING x,y,e,f

end

pro write_bas,file,st,trans=trans,povray=povray
;trans keyword switches off translation to element names


sx=vector(st.e,st.x,st.y)
sy=vector(st.f,st.x,st.y)

if not(keyword_Set(file)) then file=dialog_pickfile(/overwrite)
openw,1,file
n=n_elements(st.xy)
printf,1,n_elements(st.xy)

printf,1,"# Supercell vectors:",sx,sy
atomname=strarr(200)
for i=0,199 do atomname(i)=string(i)

if (keyword_set(trans)) then begin
    atomname(1)="H"
    atomname(2)="He"
    atomname(3)="Li"
    atomname(4)="Be"
    atomname(5)="B"
    atomname(6)="C"
    atomname(7)="N"
    atomname(8)="O"
    atomname(9)="F"
    atomname(10)="Ne"
    atomname(11)="Na"
    atomname(12)="Mg"
    atomname(13)="Al"
    atomname(14)="Si"
    atomname(15)="P"
    atomname(16)="S"
    atomname(17)="Cl"
    atomname(18)="Ar"
    atomname(19)="K"
    atomname(20)="Ca"
atomname(21)="Sc"
atomname(22)="Ti"
atomname(23)="V"
atomname(24)="Cr"
atomname(25)="Mn"
atomname(26)="Fe"
atomname(27)="Co"
atomname(28)="Ni"
atomname(29)="Cu"
atomname(30)="Zn"
atomname(31)="Ga"
atomname(32)="Ge"
atomname(33)="As"
atomname(34)="Se"
atomname(35)="Br"
atomname(36)="Kr"
atomname(37)="Rb"
atomname(38)="Sr"
atomname(39)="Y"
atomname(40)="Zr"
atomname(41)="Nb"
atomname(42)="Mo"
atomname(43)="Tc"
atomname(44)="Ru"
atomname(45)="Rh"
atomname(46)="Pd"
atomname(47)="Ag"
atomname(48)="Cd"
atomname(49)="In"
atomname(50)="Sn"
atomname(51)="Sb"
atomname(52)="Te"
atomname(53)="I"
atomname(54)="Xe"
atomname(55)="Cs"
atomname(56)="Ba"
atomname(57)="La"

atomname(58)="Ce"
atomname(59)="Pr"
atomname(60)="Nd"
atomname(61)="Pm"
atomname(62)="Sm"
atomname(63)="Eu"
atomname(64)="Gd"
atomname(65)="Tb"
atomname(66)="Dy"
atomname(67)="Ho"
atomname(68)="Er"
atomname(69)="Tm"
atomname(70)="Yb"
atomname(71)="Lu"

atomname(72)="Hf"
atomname(73)="Ta"
atomname(74)="W"
atomname(75)="Re"
atomname(76)="Os"
atomname(77)="Ir"
atomname(78)="Pt"
atomname(79)="Au"
atomname(80)="Hg"
atomname(81)="Tl"
atomname(82)="Pb"
atomname(83)="Bi"
atomname(84)="Po"
atomname(85)="At"
atomname(86)="Rn"
atomname(87)="Fr"
atomname(88)="Ra"
atomname(89)="Ac"

atomname(90)="Th"
atomname(91)="Pa"
atomname(92)="U"
atomname(93)="Np"
atomname(94)="Pu"
atomname(95)="Am"
atomname(96)="Cm"
atomname(97)="Bk"
atomname(98)="Cf"
atomname(99)="Es"
atomname(100)="Fm"
atomname(101)="Md"
atomname(102)="No"
atomname(103)="Lr"

end


sz=size(st.at(0))

print,sz
if sz(1) ne 7 then begin

	for i=0L,n-1 do begin
		if keyword_set(povray) then $
			printf,1,atomname(st.at(i)),"(",real_part(st.xy(i)),",",imaginary(st.xy(i)),",",real_part(st.z(i)),",",imaginary(st.z(i)),")" $
		else $
			printf,1,atomname(st.at(i)),real_part(st.xy(i)),imaginary(st.xy(i)),real_part(st.z(i))

	end

end else begin

	for i=0L,n-1 do begin
		if keyword_set(povray) then $
			printf,1,(st.at(i)),"(",real_part(st.xy(i)),",",imaginary(st.xy(i)),",",real_part(st.z(i)),$
			",",imaginary(st.z(i)),")" $
		else $
			printf,1,(st.at(i)),real_part(st.xy(i)),imaginary(st.xy(i)),real_part(st.z(i))
	end

end


close,1
end


function import_lvs,a,fl
;reads a lvs file to get the cell vectors
lvs=read_ascii(fl)
b=a
print,lvs
b.x=complex(lvs.(0)[0,0],lvs.(0)[1,0])
b.y=complex(lvs.(0)[0,1],lvs.(0)[1,1])
b.e=complex(1,0)
b.f=complex(0,1)
return,b
end


function read_xyz,fl

if not(keyword_set(fl)) then fl = DIALOG_PICKFILE()
OPENR, 1, fl
; Read one line at a time, saving the result into array
array = ''
line = ''
WHILE NOT EOF(1) DO BEGIN 
  READF, 1, line 
  array = [array, line] 
ENDWHILE
; Close the file and free the file unit
FREE_LUN, 1


header=array[0:2]
;header check and extraction of supercell vector if available
p=strpos(header,"# Supercell vectors:")
wp=where(p ne -1)

if wp(0) ne -1 then begin
    header=header(wp(0))

    p1=strpos(header,":(")
    p2=strpos(header,")(")
    temp=strmid(header,p1+2,p2-p1-2)
    p3=strpos(temp,",")
    xtemp=strmid(temp,0,p3)
    ytemp=strmid(temp,p3+1)
    print,xtemp,ytemp
    x=complex(xtemp,ytemp)

    temp=strmid(header,p2+2)
    ;temp=strmid(temp,;
    p4=strpos(temp,")")-1
    print,temp
    temp=strmid(temp,0,p4+1)
    p3=strpos(temp,",")
    xtemp=strmid(temp,0,p3)
    ytemp=strmid(temp,p3+1)
    print,xtemp,ytemp
    y=complex(xtemp,ytemp)
end

if keyword_set(x) then x=x else x=complex(0.,0.)
if keyword_set(y) then y=y else y=complex(0.,0)
if keyword_set(e) then e=e else e=complex(1.,0)
if keyword_set(f) then f=f else f=complex(0.,1)
if keyword_set(zz) then zz=zz else zz=complex(1.,0)


coords=array(3:*)

n=n_elements(coords)

xy=complexarr(n)
z=complexarr(n)

for i=0,n-1 do begin
	lne=coords(i)
	lnea=strsplit(lne,/extract)
	xy(i)=complex(lnea(1),lnea(2))
	z(i)=complex(lnea(3),0)
	sz=size(lnea(0))
	if sz(1) eq 2 then begin
		if i eq 0 then at=intarr(n)
		at(i)=fix(lnea(0))
	end else begin
		if i eq 0 then at=strarr(n)
		at(i)=lnea(0)
	end

end


struct={at:at,xy:xy,z:z,e:e,f:f,x:x,y:y,zz:zz}
return,struct
end




function read_bas,fl,x=x,y=y,e=e,f=f,zz=zz
if not(keyword_set(zz)) then zz=0./0.
if not(keyword_set(fl)) then fl=dialog_pickfile()
a=read_ascii(fl,data_start=2,header=header)
nnn=n_elements(a.field1(1,*))
xy=reform(complex(a.field1(1,*),a.field1(2,*)),nnn)
z=reform(complex(a.field1(3,*)),nnn)
at=reform(a.field1(0,*),nnn)
print,header

;header check and extraction of supercell vector if available
p=strpos(header,"# Supercell vectors:")
wp=where(p ne -1)

if wp(0) ne -1 then begin
    header=header(wp(0))

    p1=strpos(header,":(")
    p2=strpos(header,")(")
    temp=strmid(header,p1+2,p2-p1-2)
    p3=strpos(temp,",")
    xtemp=strmid(temp,0,p3)
    ytemp=strmid(temp,p3+1)
    print,xtemp,ytemp
    x=complex(xtemp,ytemp)

    temp=strmid(header,p2+2)
    ;temp=strmid(temp,;
    p4=strpos(temp,")")-1
    print,temp
    temp=strmid(temp,0,p4+1)
    p3=strpos(temp,",")
    xtemp=strmid(temp,0,p3)
    ytemp=strmid(temp,p3+1)
    print,xtemp,ytemp
    y=complex(xtemp,ytemp)
end

if keyword_set(x) then x=x else x=complex(0.,0.)
if keyword_set(y) then y=y else y=complex(0.,0)
if keyword_set(e) then e=e else e=complex(1.,0)
if keyword_set(f) then f=f else f=complex(0.,1)

struct={at:at,xy:xy,z:z,e:e,f:f,x:x,y:y,zz:zz}
return,struct
end

function atoms_c,a,z
;renames chemistry of all atoms to z
st=a
st.at=intarr(n_elements(st.at))+z
return,st
end


function reduce_c,s,i
;copies only selected elements from s.xy s.at s.z by i
i=reform(i)

p={at:s.at(i),xy:s.xy(i),z:s.z(i),e:s.e,f:s.f,x:s.x,y:s.y,zz:s.zz}

return,p
end

function select_c,s
;interactively selects atoms to remove according to their xy coords
;returns an array
vis_c,s
mny=min(imaginary(s.xy))
t=s
ii=-1

repeat begin
n=n_elements(t.xy)

print,"atom", ii
print,"n",n

if ii(0) ne -1 then begin
    i=indgen(n-1)
    if ii(0) ne n-1 then i(ii(0):n-2)=i(ii(0):n-2)+1
    help,i
    t=reduce_c(t,i)
    help,t,/struct
    vis_c,t
end

cursor,x,y,/up,/data
print,x,y

dx=real_part(t.xy)-x
dy=imaginary(t.xy)-y
r=dx^2+dy^2
ii=where(r eq min(r))

endrep until y lt mny


return,t
end

pro vis_c,s,w=w,num=num,zcol=zcol,zinfo=zinfo

;num labels atoms
;w selects atoms to highlight
;zcol distinguishes atoms by colors according to their z coord
;zinfo uses imaginary part of Z for the colors (spins etc.)
;device,decomposed=1
;goldpalette,/pure

la=vector(s.e,s.x,s.y)
lb=vector(s.f,s.x,s.y)
lax=real_part(la)
lay=imaginary(la)
lbx=real_part(lb)
lby=imaginary(lb)
xx=real_part(s.x)
xy=imaginary(s.x)
yx=real_part(s.y)
yy=imaginary(s.y)
if keyword_set(zinfo) then z=(bytscl(-imaginary(s.z))) else z=bytscl(real_part(s.z))


print,s.y,yx,yy
help,yx

    mxx=max(real_part(s.xy))
    mxy=max(imaginary(s.xy))
    mnx=min(real_part(s.xy))
    mny=min(imaginary(s.xy))

if (xx eq 0 and xy eq 0) or (yx eq 0 and yy eq 0) then begin
    plot,[mnx-0.2*abs(mnx),mxx+0.2*abs(mxx)],[mny-0.2*abs(mny),mxy+0.2*abs(mxy)],psym=-3,/iso,xst=3,yst=3,/nodata
end $
else $
begin
    plot,[mnx-0.2*abs(mnx),mxx+0.2*abs(mxx)],[mny-0.2*abs(mny),mxy+0.2*abs(mxy)],psym=-3,/iso,xst=3,yst=3,/nodata
    oplot,[0.,lax,lax+lbx,lbx,0.],[0.,lay,lay+lby,lby,0.],psym=-3
    
end

oplot,[0.,lax,lax+lbx,lbx,0.],[0.,lay,lay+lby,lby,0.],psym=-3,color=128
;plot,real_part(s.xy),imaginary(s.xy),psym=3,/iso,xst=2,yst=2
oplot,[0.,lax],[0.,lay],psym=-3,color=128
oplot,[0.,lbx],[0.,lby],psym=-3,color=128



oplot,[0.,xx],[0.,xy],psym=-3,color=250
oplot,[0.,yx],[0.,yy],psym=-3,color=250


if keyword_set(w) then oplot,real_part(s.xy(w)),imaginary(s.xy(w)),psym=5

oplot,real_part(s.xy),imaginary(s.xy),psym=3
n=n_elements(s.xy)

if keyword_set(num) then $
    for i=0,n-1 do xyouts,real_part(s.xy(i)),imaginary(s.xy(i)),strtrim(string(i),2)

help,n
help,xy
help,s.z
help,z

if keyword_set(zcol) then $
    for i=0L,n-1 do begin
	plots,real_part(s.xy(i)),imaginary(s.xy(i)),psym=2,color=2.*z(i)/3.+85
    end


if keyword_set(zcol) then print,"Zmin, Zmax, dZ",min(real_part(s.z)),max(real_part(s.z)),max(real_part(s.z))-min(real_part(s.z))

end

function multiply_c,sa,sb
;places sb at every sa coordinate
;new unit cell vectors (x,y,e,f,z,zz) will be taken from the sa
;atom types in sa will be gnored and sb used instead

tmpxy=sb.xy+sa.xy(0)
tmpat=sb.at
tmpz=sb.z

for i=1,n_elements(sa.xy)-1 do begin
	xy=sb.xy+sa.xy(i)
	tmpxy=[tmpxy,xy]
	tmpat=[tmpat,sb.at]
	tmpz=[tmpz,sb.z]
end

return,{at:tmpat,xy:tmpxy,x:sa.x,y:sa.y,e:sa.e,f:sa.f,z:tmpz,zz:sb.zz}
end



