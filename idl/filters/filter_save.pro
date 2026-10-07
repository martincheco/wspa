pro filter_save,file,filt
;saves filter
if (keyword_set(filt)) then $
    begin
	if not(keyword_set(file)) then file=dialog_pickfile()
	n=n_elements(filt.type)
	stuff=dblarr(n)
	idealfilt={type:strarr(n),par1:stuff,par2:stuff,par3:stuff}
	nt=n_tags(filt)
	struct_assign,filt,idealfilt 
	openw,1,file,error=err
	if (err eq 0) then begin 
	    for i=0,n-1 do $
		begin
		    line=idealfilt.type(i)
		    for j=1,3 do line=line+string((idealfilt.(j))(i))
		    ;print,line
		    printf,1,line
		end
	    close,1
	end else print,"Error: filter cannot be written!"
    end
end
