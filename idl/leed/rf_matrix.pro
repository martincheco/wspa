function rf_matrix,iv,energy,rf,filter,filterpar
;returns a square matrix with a chosen rfactors of IVs at energies defined by array energy
;ignores zero values
;uses filter to smooth the data first

if not(keyword_set(filterpar)) then filterpar=[10,20]
if not(keyword_set(filter)) then filter="none"

s=size(iv)
pmatrix=dblarr(s(1),s(1))
for i=0,s(1)-1 do for j=0,s(1)-1 do $
    begin
	iv1=reform(iv(i,*))
	iv2=reform(iv(j,*))
	
	case filter of
	    "savgol":$
	    begin
		iv1=dezofilter(energy, iv1, width=filterpar(0), /savg)
		iv2=dezofilter(energy, iv2, width=filterpar(0), /savg)
	    end
	else:$
	    print,"No filter";,/noprint
	endcase
	
	w=where(iv1 gt 0 and iv2 gt 0)
    
	if w(0) gt -1 then $ ;throws away all that is =< 0
    	    begin
		iv1=iv1(w)
    		iv2=iv2(w)
		e=energy(w)
	    end
    
	case rf of $
	    "pendry": pmatrix(i,j)=pendry2(e,iv1>2,iv2>2)
	    ;"ja": pmatrix(i,j)=ja_rfactor(e,iv1>2,iv2>2)
	    ;"whatever": pmatrix(i,j)=whatever_rfactor(e,iv1>2,iv2>2)
	else: print,"Unknown R-factor";,/noprint
	endcase
        
    end
print,pmatrix;,/noprint

return,pmatrix
end
