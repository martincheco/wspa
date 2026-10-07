function stackconv,t,wz,wx,wy
;averages 4D stack over wz,wx,wy and shrinks it accordingly

if not(keyword_set(wz)) then return,t
if not(keyword_set(wx)) then wx=1
if not(keyword_set(wy)) then wy=1

s=size(t)

nz=s(1)
nch=s(2)
nx=s(3)
ny=s(4)

nt=dblarr(nz,nch,nx,ny)
for z=0,wz-1 do for x=0,wx-1 do for y=0,wy-1 do nt+=shift(t,-z,0,-x,-y)
help,t
help,nt



nt=nt(0:nz-wz-1,*,0:nx-wx-1,0:ny-wy-1)/wz/wx/wy
return,nt
end
