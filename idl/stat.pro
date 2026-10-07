function stat
sm=dblarr(500,10000)
seed=0
for i=0,499 do begin
	for j=0,9999 do begin
		rsm=randomu(seed,i+1)
		smp=double(total(round(rsm)))/n_elements(rsm)
		sm(i,j)=smp
	end
end

res=dblarr(500)
for i=0,499 do res(i)=stddev(sm(i,*)) 

return,res

end
