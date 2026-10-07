function cosmicrays,array
;takes array of measurements, madian-filters out the cosmic rays
;curve_index,point_index
s=size(array)
res=reform(array(0,*))*0
for i=0,s(2)-1 do res(i)=median(array(*,i))


return,res
end
