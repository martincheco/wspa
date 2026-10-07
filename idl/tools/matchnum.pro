function matchnum,flst,nos
;searches flst(strarr) for occurence of numbers
;nos - numbers to find

n=n_elements(nos)

matchs=-1

for i=0,n-1 do begin
    mtch='*'+strtrim(string(nos(i)),2)+'*'
    w=where(strmatch(flst,mtch))
    if w(0) ne -1 then matchs=[matchs,w]
end


if n_elements(matchs) gt 1 then $
    return, matchs(1:*) $
else $
    return, matchs

end