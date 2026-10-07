function energy_sort,m,cluster=cluster,width=width,volume=volume,gauss=gauss,reduce=reduce
;gets images and energies from string array m
;sorts by enegies and makes a stack
;PARAMETERS
;width - resolution width
;gauss - gaussian broadening in energy
;SWITCHES
;cluster - sums the images+energies that have energies within the width
;reduce - use for faster clustering (to be improved)
;gauss - performs a gaussian spreading in energy

;loading all phmaps into an array
n=n_elements(m)

stk=tostack(m)
s=size(stk)
stk=reform(stk,s(1),s(3),s(4))
print,s

;reducing the XY dimensions of the array if requested (typically X=500 & Y=500 is unneccesarily big)
if keyword_set(reduce) then begin
	stk=rebin(stk,s(1),s(3)/reduce,s(4)/reduce)
	s(3)/=reduce
	s(4)/=reduce
end

help,stk


;retrieving the energies corresponding to the maps
e=dblarr(n)

for i=0,n-1 do begin
	am=*m(i)
	e(i)=getval(am.par,'Energy:','float')
end

print,e
;sorting stack by energy
is=sort(e)

e=e(is)
stk=stk(is,*,*)
help,stk
print,e

;the clustering of the phmaps that are within the preset width
if keyword_set(cluster) then begin
	nn=dblarr(n)+1.
	;20% proximity criterion if width is not explicitly specified
	if not(keyword_set(width)) then width=0.2*abs(max(e)-min(e))/n else width=abs(width)
	help,width	

	;the search for the similar energies - dirty but works well
	repeat begin
		c=0
		n=n_elements(e)
		if n gt 1 then begin

			enm=e/nn
			for i=0,n-2 do begin
				if abs(enm(i)-enm(i+1)) le width then begin
;				print,"***",e(i)/nn(i),e(i+1)/nn(i+1),abs(e(i)/nn(i)-e(i+1)/nn(i+1)) 
					e(i)+=e(i+1)
					nn(i)+=nn(i+1)
					e(i+1)=0./0. ;insert nans
					stk(i,*,*)+=stk(i+1,*,*)
					c++
				end
				if c gt 0 then break
			end
		end
		print,e
		print,n
		print,e/n
		print,where(finite(e) )
		stk=stk(where(finite(e)),*,*)
		nn=nn(where(finite(e)))
		e=e(where(finite(e)))
		help,c
		print,e
		help,stk
	end until c eq 0
	e=e/nn
end


;this would create a 3D volume hyperspectral map from the stack of phmaps
if keyword_set(volume) then begin
	if not(keyword_set(gauss)) then fact=1L else fact=(gauss>1)
	mx=max(e)+fact*width
	mn=min(e)-fact*width
	nnn=round((mx-mn)/width)
	nstk=dblarr(nnn,s(3),s(4))
	nne=(dindgen(nnn)/nnn)*(mx-mn)+mn

	for i=0,n-1 do begin
		l=abs(e(i)-nne)
		ie=where(l eq min(l))
		help,ie
		nstk(ie(0),*,*)=stk(i,*,*)
	end

	e=nne
	;if gauss parameter is set, smear the intensity on the Energy axis
	if keyword_set(gauss) then stk=stackgauss(nstk,gauss) else stk=nstk
	stk=stk(fact/2:-fact/2-1,*,*)
	e=e(fact/2:-fact/2-1)

end


return,{e:e,stack:stk}
end
