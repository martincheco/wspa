function stackredshift,dt,redshifts

ndt=dt
s=size(dt)
for i=0,s(2)-1 do for j=0,s(3)-1 do ndt(*,i,j)=shift(dt(*,i,j),redshifts(i,j))


return,ndt
end
