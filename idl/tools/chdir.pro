pro chdir,last=last
i=strsplit(!PATH,":")
log=strmid(!PATH,i(n_elements(i)-1))
p=strpos(log,"/idl")
log=strmid(log,0,p)+"/idl/chdir.log"
print,log
lst=-1
dir=""

if file_test(log) then lst=loadlist(log) ;has a natural limit of 999

if(keyword_set(last)) then begin
    slist=lst(uniq(lst))
    ;print,slist
    nn=9<(n_elements(slist))
    for i=0,nn-1 do print,"("+strtrim(string(i+1),2)+") "+slist(i)
    number=""
    read,number
    number=fix(strtrim(number,2))
    if number(0) le (n_elements(lst)-1)<9 and number(0) ge 1 then begin
	dir=slist(number(0)-1)
	print,"Using: ",dir
    end
end


if dir eq "" then dir=dialog_pickfile(/dir,/must_exist)

if file_test(dir,/directory) then begin
    savelist,log,[dir,lst]
    cd,dir
end else print,"Invalid directory "+dir
end