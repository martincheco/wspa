function FePc_mkstak_rdmap, fm
;reads a map from xyz file, reforms, returns
	map=loadxyz(fm)
	
	return,map
end

function FePc_mkstak_rden, fe
;reads the energies for the maps from molden file
	openr,1,fe
	a=''
	readf,1,a
	en=fltarr(100000L)
	i=0
	help,a
	while not(EOF(1)) and strtrim(a,2) ne "" do begin
		a=''
		readf,1,a
		help,a
		en(i)=float(a)
		i=i+1	
	end
	close,1
	return,en(where(en))
end


function FePc_mkstak_rdall,f
	n=n_elements(f)
	map=FePc_mkstak_rdmap(f(0))
	s=size(map.img)
	stack=dblarr(n,s(1),s(2))
	stack(0,*,*)=map.img
	for i=1,n-1 do begin

		map=FePc_mkstak_rdmap(f(i))
		stack(i,*,*)=map.img
	end


	return,stack	
	
end

function FePc_mkstak_irr,stack,ren,w,resample
	print,'Entering the abyss..creating stack from slices'
	nn=(max(ren)+10L)*resample;create an array for the 3d map
	help,nn
	s=size(stack)
	nstack=dblarr(nn,s(2),s(3))
	help,nstack
	n=s(1)	
	for i=0,n-1 do begin ;add each slice with a defined gaussian spread in z
		print,'SLICE: ',i
		slice=reform(stack(i,*,*),1,s(2),s(3))
		help,slice
		slice3= rebin(slice,nn,s(2),s(3),/SAMPLE)
		help,slice3
		gaus=gauss1d(nn,(ren(i)*resample),w*resample)
		help,gaus
		gaus3= REBIN(REFORM(gaus, nn ,1, 1), nn, s(2), s(3), /SAMPLE)
		help,gaus3
		nstack=nstack+slice3*gaus3
	end

	st=congrid(nstack,nn/resample,s(2),s(3))
	return,{st:st,e:ren}
end

function FePc_mkstak
	g=getfiles(mask="campovec*")
	gg=getfiles(mask="*.in")
	if n_elements(g) ne n_elements(gg(0)) then begin
		print,'Different number of energies and maps, aborting!'
		return,-1
		
	end
	resample=1 ;resampling parameter to have everything finer
	w=5
	r=FePc_mkstak_rdall(g)
	ren=FePc_mkstak_rden(gg(0))
	r=FePc_mkstak_irr(r,ren,w,resample)
	return,r
end

