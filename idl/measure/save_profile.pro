pro save_profile,fnm,pfl,xlabel=xlabel,ylabel=ylabel,err=err
;labels saves axis names

    if pfl.z(0) ne -1 then begin
	if not(keyword_set(fnm)) then fnm=dialog_pickfile(/write,/overwrite_prompt)
	if fnm ne "" then begin
	    openw,1,fnm
	    if keyword_set(xlabel) and keyword_set(ylabel) then printf,1,xlabel,' ',ylabel
	    for ii=0,n_elements(pfl.z)-1 do $
		if keyword_set(err) then printf,1,pfl.r(ii),pfl.z(ii),err(ii) else printf,1,pfl.r(ii),pfl.z(ii)
	    close,1
	end else print,"Invalid filename!"
	end
end
