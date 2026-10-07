function ppr_mread_th,f,dirnm=dirnm,convert=convert
;loads theory data
;dirnm needed to store names of files to sort
;convert includes parameters for conversion F to df
if not(keyword_set(f)) then f='.' 
drs=getfiles(f,/dirs)
n=n_elements(drs)
;if not(keyword_set(convert)) then convert=[14,5e-12,1e6,1e6]
dirnm=drs
thp=ptrarr(n)
;print,drs
for i=0,n-1 do begin
        print,'Reading:',drs(i)+'OutFz.xsf'
        th=xsf_read(drs(i)+'OutFz.xsf')
        if keyword_set(convert) then tht=giessibl(reverse(1.60217*1e-9*th.data,1),n=convert(0),dz=convert(1),k=convert(2),f0=convert(3),/ext) else tht=reverse(th.data,1)
;	s=size(th)
;        th=repstack(th,2,2)
;        th=repstack(th,2,3)
;        tht=reverse(tht,2)
;	th=congrid(th,s(1)1.6,s(2),s(3))

        thp(i)=ptr_new(tht)
end


return,thp
end

function ppr_th_zcut,th,z1,z2,free=free
n=n_elements(th)
thp=ptrarr(n)
for i=0,n-1 do begin
	tt=*th(i)
	thp(i)=ptr_new(tt(z1:z2,*,*))
end
if keyword_set(free) then ptr_free,th
return,thp
end

function ppr_th_rev,th,dim
n=n_elements(th)
for i=0,n-1 do begin
	tt=reverse(*th(i),dim,/overwrite)
end
return,th
end


function ppr_sort,th,d
;extracts the Q and K from the dirnames
;sorts the pointers in th to be an array
n=n_elements(d)
q=dblarr(n)
k=q
;th=ptrarr(n)

for i=0,n-1 do begin
	kq=strsplit(file_basename(d(i)),'Q|-K',/regex,/extract)
	k(i)=kq(0)
	q(i)=kq(1)
	
	img=0;read_png(d(i)+'/a_overview.png')

end
help,k
help,q
mi=multisort(k,q)

k=k(mi)
q=q(mi)
thn=th(mi)
ii=n_elements(uniq(q(sort(q))))
jj=n/ii

k=reform(k,ii,jj)
q=reform(q,ii,jj)
thn=reform(thn,ii,jj)

return,{k:q,q:k,th:thn}
end



pro ppr_curves,blk
ss=size(blk)


end

pro ppr_browse,r,zofs
s=size(r.th)
ss=size(*r.th(0))
window,1,xs=200,ys=200
plot,r.q,r.k,psym=1
window,2,xs=ss(2),ys=ss(3)*4
if not(keyword_set(zofs)) then zofs=intarr(s(1),s(2))
m=0
repeat begin
	wset,1
	cursor,x,y,/change,/data
	wset,2
	w=where((abs(x-r.q) eq min(abs(x-r.q))) and (abs(y-r.k) eq min(abs(y-r.k))))
	wxy=array_indices(r.q,w)
	wx=wxy(0)
	wy=wxy(1)
	tv,bytscl((*r.th(wx,wy))(zofs(wx,wy),*,*))
	tv,bytscl((*r.th(wx,wy))(zofs(wx,wy)+1,*,*)),0,ss(3)
	tv,bytscl((*r.th(wx,wy))(zofs(wx,wy)+2,*,*)),0,ss(3)*2
	tv,bytscl((*r.th(wx,wy))(zofs(wx,wy)+3,*,*)),0,ss(3)*3
	
end until !mouse.button ne 0

end

function ppr_transpose,r


return,{th:transpose(r.th),k:transpose(r.k),q:transpose(r.q)}
end


function ppr_arrange,r,bk,zoffs
;will make a big array, following q and k
if not(keyword_set(bk)) then bk=0
s=size(r.th)
ss=size(*r.th(0))

if not(keyword_set(zoffs)) then zoffs=intarr(s(1),s(2))
zof=max(zoffs)-(zoffs)
print,min(zof),max(zof)
nx=ss(2)
ny=ss(3)
mnmx=max(zoffs)-min(zoffs)+1
nz=ss(1)

ndx=s(1)
ndy=s(2)

a=dblarr(nz+mnmx,(nx+2*bk)*ndx+bk,(ny+2*bk)*ndy+bk)*(0./0.)
help,a
for i=0,ndx-1 do for j=0,ndy-1 do begin
	xpos=i*(nx+2*bk)+bk
	ypos=j*(ny+2*bk)+bk
	a(zof(i,j):nz-1+zof(i,j),xpos:xpos+nx-1,ypos:ypos+ny-1)=*r.th(i,j)	
end
return,a
end

function ppr_mkarr,r
;makes a 5D array (q,k,z,x,y)
s=size(r.th)
ss=size(*r.th(0))
print,s
print,ss
farr=dblarr(s(1),s(2),ss(1),ss(2),ss(3))
for i=0,s(1)-1 do for j=0,s(2)-1 do farr(i,j,*,*,*)=*r.th(i,j)


return,farr
end


pro ppr_dump,r,zoffs
a=ppr_arrange(r,2,zoffs)
s=size(a)
for i=0,s(1)-1 do png_save,'slice_'+strtrim(string(i,format='(I03)'))+'.png',bytscl(reform(a(i,*,*)),/nan)
end


function ppr_register_all,ex,th,norot=norot,init=init,vis=vis
resolve_routine,'register2'
step=intarr(7)
n=n_elements(th)
if not(keyword_set(init)) then init=[1.,0.,0.,0.,0.,0.,0.]
reg=ptrarr(n)
for i=0,n-1 do begin
	thx=*th(i)
	res=register_iter(thx,ex,init(0),init(1),init(2),init(3),init(4),init(5),init(6),vis=vis,step=step,norot=norot)
	reg(i)=ptr_new(res)
end

return,reg
end


function ppr_dump_all,thr,dirnm
n=n_elements(thr)
cors=dblarr(n)
s=size((*thr(0)).a)
;window,0,xs=500,ys=500

for i=0,n-1 do begin
        res=*thr(i)
        if keyword_set(dirnm) then dr=file_basename(dirnm(i)) else dr=strtrim(string(i,format='(I04)'),2)
        print,dr
        file_mkdir,dr
        cd,dr
        register_dump,res

        cors(i)=res.r

        openw,1,'params.txt'
;        printf,1,'Similarity factor: ',res.r
        printf,1,'Pearson:',res.r
        printf,1,'Zoom, Rot, dz, dx, dy, a, b:',res.vect
        close,1
cd,'..'
end
return,cors
end
