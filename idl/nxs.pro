function nxs_read,f
a=read_ascii(f)
res=double(a.(0))
return,{x:reform(res(0,*)),y:reform(res(1,*))}
end


function nxs_read_all,fl=fl
f=getfiles('./scan')
fl=f
n=n_elements(f)
p=ptrarr(n)
for i=0,n-1 do begin
	p(i)=ptr_new(nxs_read(f(i)))
end	
return,p
end

function nxs_norm,p,b
n=n_elements(p)
np=ptrarr(n)
for i=0,n-1 do begin
	a=(*p(i))
	np(i)=ptr_new({x:a.x,y:(a.y/b.y)})
end 

return,np
end

function nxs_read_bkg

f=getfiles('')
return,nxs_read(f)
end

function nxs_polyeval,x,r
n=n_elements(r)
xx=1D
tot=0D
for i=0,n-1 do begin
tot=tot+xx*r(i)
xx=xx*x
end
return,tot
end

function nxs_fit,t
x=[t.x(50:300),t.x(-350:-10)]
y=[t.y(50:300),t.y(-350:-10)]

;x=t.x
;y=t.y
polyfit,x,y,3,coeffs,sig,yf
nx=t.x
yfit=nxs_polyeval(nx,coeffs)
ny=t.y-yfit
;plot,t.x,t.y,xst=1,yst=1

plot,t.y,yrange=[min(t.y(100:-100)),max(t.y(100:-100))]
oplot,yfit,color=255
;oplot,t.x,ny
wait,0.5
print,sig
;wait,1.0
return,{x:nx,y:ny}
end


function nxs_fit_all
t=nxs_read_all(fl=fl)
b=nxs_read_bkg()
np=nxs_norm(t,b)
n=n_elements(np)
nnp=ptrarr(n)
for i=0,n-1 do begin
	curr=(*np(i))
	nnp(i)=ptr_new(nxs_fit(curr))
end

nxs_dump,nnp,fl+'.g'
return,nnp
end


pro nxs_write,t,f
n=n_elements(t.x)
openw,1,f
for i=0,n-1 do printf,1,t.x(i),t.y(i)
close,1
end

pro nxs_dump,np,f
n=n_elements(np)
for i=0,n-1 do begin
	t=*np(i)
	nxs_write,t,f(i)
end

end

