function stsgridtostack,t,m,n
;pass here the structure that contains all the curves in each point
;m,n are the dimensions of the grid

tr=reform(t,m,n)
smpl=(*t(0)).data
s=size(smpl)

arr=dblarr(s(2),s(1),m,n)

for i=0,m-1 do for j=0,n-1 do begin
	
arr(*,*,i,j)=transpose((*tr(i,j)).data)
end

return,transpose(arr,[2,1,3,0]) ;order as stack
end
