pro putval,stack,id,value
;gets the value after the identifier in the stack and replaces by string
;uses regex, may crash if the regex is bad
    found=STREGEX(stack,id,/extract)
    w=where(found)
    if not(keyword_set(typ)) then typ="str"
	if w(0) ne -1 then stack(w(0))=id+" "+value 
	;if w(0) eq -1 then 
	end
print,stack(w(0))
end
