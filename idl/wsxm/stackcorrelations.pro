function stackcorrelations, dt,i,j,thr=thr,iter=iter,weight=weight,rng=rng
;finds crosscorrelations between the curve at given i,j
;assumes form data(Zi,Xi,Yi)
;threshold defines similarity limit
;returns array of correlations, indices of similar curves and their average
;iter would run again but with the averaged curve and the same threshold
;built for optical spectra
;weight weighs the curves by their correlation above threshold


s=size(dt)
corrs=dblarr(s(2),s(3))
ref=reform(dt(*,i,j))
ref=double(ref);-median(ref,/double)
if not(keyword_set(thr)) then thr=0.95
avg=ref*0D

c=0
for k=0,s(2)-1 do for l=0,s(3)-1 do begin
	crv=double(reform(dt(*,k,l)));-median(dt(*,k,l))))
	if keyword_set(rng) then corrs(k,l)=correlate(crv(rng(0):rng(1)),ref(rng(0):rng(1)),/double) else corrs(k,l)=correlate(crv,ref,/double)
	if corrs(k,l) ge thr then begin
		if keyword_set(weight) then avg+=crv*corrs(k,l) else avg+=crv
		c++
	end
end
print,c

nref=ref
if keyword_set(iter) then for ii=1,iter do begin
	nref=avg/c
	avg=avg*0D
	c=0
	for k=0,s(2)-1 do for l=0,s(3)-1 do begin
		crv=double(reform(dt(*,k,l)));-median(dt(*,k,l))))
		if keyword_set(rng) then corrs(k,l)=correlate(crv(rng(0):rng(1)),nref(rng(0):rng(1)),/double) else corrs(k,l)=correlate(crv,ref,/double)
		if corrs(k,l) ge thr then begin
			if keyword_set(weight) then avg+=crv*corrs(k,l) else avg+=crv
			c++
		end

	end
	print,'Iteration, n:',ii,c
end

avg=avg/c


w=where(corrs ge thr)



if w(0) ne -1 then begin
	inds = ARRAY_INDICES(corrs, w)
end else return,{is:-1,js:-1,avg:ref,corrs:corrs}

return,{is:reform(inds(0,*)),js:reform(inds(1,*)),avg:avg,corrs:corrs,ref:ref,nref:nref}

end
