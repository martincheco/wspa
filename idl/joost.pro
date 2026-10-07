function joost_order,f
n=n_elements(f)
ii=lonarr(n)
for i=0,n-1 do begin
	p1=strpos(f(i),'--')
	p2=strpos(f(i),'-Df')
	frag=strmid(f(i),p1+5,p2-p1-5)
	ii(i)=round(frag)
end 
return,(sort(ii))

end


function joost_read
f=getfiles('I/')
f1=getfiles('df/')
ii=joost_order(f1)
f=f(ii)
f1=f1(ii)
prim=read_asc(f(0))
s=size(prim)
n=n_elements(f)/2
stack=dblarr(n,4,s(1),s(2))
for i=0,n-1 do begin
	stack(i,0,*,*)=read_asc(f(2*i))
	stack(i,1,*,*)=read_asc(f(2*i+1))
	stack(i,2,*,*)=read_asc(f1(2*i))
	stack(i,3,*,*)=read_asc(f1(2*i+1))
end

tf=stackfold(stack(0:68,*,*,*))
t=stackzoom(tf,4)
tt=rmshift(t,base_i=0,chan=0,/stuff)
;tt=rmdelay(tt,2,3,/stuff)
stack=stackzoom(tt,0.5)
return,stack
end

pro joost
resolve_routine,'ppr'
resolve_routine,'register2'
cd,'/home/martin/sync/data/JOOST_th/Xe/'
thxe=ppr_mread_th(dirnm=dirnm,convert=[20,5e-12,1900,21922])
thxe=ppr_th_rev(thxe,2)
joost_xe1,thxe,dirnm
;joost_xe2,th


;joost_CO1,th
;joost_CO2,th
end

pro joost_xe1,th,dirnm

cd,'/home/martin/sync/data/JOOST/30_7_57_xe1/'
ex=joost_read()
ex=reform(ex(5:15,1,*,*))
file_mkdir,'reg'
cd,'reg'
thc=ppr_th_zcut(th,43-27+5,43-27+15)
rg=register_iter(*thc(14),ex,1,0,0,0,0,0,0,/norot,mask=[1,1,0,1,1,0,0],/vis)
reg=ppr_register_all(ex,thc,/norot,init=rg.vect,/vis)
cors=ppr_dump_all(reg,dirnm)
g=gplt()
end
