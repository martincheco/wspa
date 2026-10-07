function getval,stack,id,typ,unit=unit
;gets the value after the identifier, stack is the string array, id is the identifier
;type is the type of variable and unit optionally extracts physical unit after the value
    id_search = id
    p = strpos(stack, id_search)
    w = where(p eq 0, count)
    if count eq 0 then w = where(p ne -1, count)
    if count eq 0 and strpos(id, '\') ne -1 then begin
        id_search = repstr(repstr(id, '\(', '('), '\)', ')')
        p = strpos(stack, id_search)
        w = where(p eq 0, count)
        if count eq 0 then w = where(p ne -1, count)
    endif
    val=""
    valstr="nil"
    if not(keyword_set(typ)) then typ="str"
	if count gt 0 then begin
	    found=stack(w(0))
	    pos=p(w(0))
	    valstr=strmid(found, pos + strlen(id_search))
	    b=byte(valstr)
	    bw=where(b eq 9B, bcnt)
	    if bcnt gt 0 then b(bw)=32B
	    valstr=strtrim(string(b), 2)
	    if valstr ne "" then begin 
		case typ of 
		    "int":val=fix(valstr(0))
		    "float":val=float(valstr(0))
		    "dbl":val=double(valstr(0))
		    else: val=valstr
		endcase
		if keyword_set(unit) or arg_present(unit) then begin
		    unt=strsplit(strtrim(valstr,2)," ",/extract)
		    if n_elements(unt) ge 2 then begin
			unit=unt(1)
			unit=unit(0)
		    endif
		end
	    end
        end
if typ eq "str" then if keyword_set(unit) then begin
p=strpos(val(0),unit,/reverse_search)
if p ne -1 then val=strtrim(strmid(val(0),0,p),2)
end
return,(val(0))

end
