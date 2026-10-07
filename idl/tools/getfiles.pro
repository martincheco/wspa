
function getfiles,dr,dirs=dirs,mask=mask,range=range
;reads files or subdirectories from a directory
;can use mask like *a*.efg etc.
;range keyword is an array of two, which will generate a range of numbers, third elements gives the length

if not(keyword_set(dr)) then dr='.'

if not(keyword_set(mask)) then res=file_search(dr+'/*',/mark) $
	else res=file_search(dr+'/'+mask,/mark)



help,res
wd=file_test(res,/directory)
help,wd
;print,res
;print,wd
wf=1-wd
wwd=where(wd)
wwf=where(wf)

help,wwd
help,wwf
    if wwd(0) ne -1 then drs=res(where(wd)) else drs=''
    if wwf(0) ne -1 then fls=res(where(wf)) else fls=''
    if not(keyword_set(dirs)) then res=fls else res=drs



if keyword_set(range) then begin
	rng1=range(0)
	rng2=range(1)
	nn=range(2)
;	nn=ceil(alog10(rng1+1,/double)) ;number of digits
	fullrange=string(indgen(rng2-rng1+1)+rng1,format='(I0'+strtrim(string(nn),2)+')')
	print,fullrange
	nres=''
	for i=0,n_elements(fullrange)-1 do begin
		print,fullrange(i)
		w=where(strmatch(res,'*'+fullrange(i)+'.*') eq 1)
		if w(0) ne -1 and fullrange(i) ne '*' then nres=[nres,res(w(0))]
		print,w(0),res(w(0))
	end
	if n_elements(nres) gt 1 then res=nres(1:*) else res=''
end

return,res
end
