function getvalns,par,pattern,unit=unit
;used by loadnanonis
;getval function for the nanonis style parameter file structure
i=rdnline(par,pattern)
if i(0) ne -1 then a=strsplit(par(i(0)),/extract) else a=''
if keyword_set(unit) then unit=getunit(par(i(-2)))
return,a(-1)
end
