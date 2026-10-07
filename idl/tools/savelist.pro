pro savelist,file,lst
openw,1,file,error=err
    if (err eq 0) then begin 
	for i=0,n_elements(lst)-1 do printf,1,lst(i)
	close,1
    end else print,"Error: list cannot be written! (Maybe insufficient rights?)"
end

