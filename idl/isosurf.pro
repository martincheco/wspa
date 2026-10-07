function isosurf
g=getfiles(mask='*.sxm',range=[65,88,3])
n=n_elements(g)


a=loadnanonis(g(0))

aa=a.img
s=size(aa)

dt=dblarr(s(1),s(2),n)

for i=0,n-1 do begin
	a=loadnanonis(g(i))
	aa=a.img
	dt(*,*,i)=shift(aa(*,*,9),5)+aa(*,*,8)
end


return,dt
end
