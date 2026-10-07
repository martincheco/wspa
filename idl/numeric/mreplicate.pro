function mreplicate,v,dim
m=reform(replicate(v(0),n_elements(v)*dim),n_elements(v),dim)
for i=0,dim-1 do m(*,i)=v
return,m
end

