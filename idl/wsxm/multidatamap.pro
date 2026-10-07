function multidatamap,t
;finds number of adjacent channels in the set
n=n_elements(t)
fnames=strarr(n)
map=intarr(n)
for i=0,n-1 do begin
    fnames(i)=((*t(i)).par)(0)
    p=strpos(fnames(i),'.',/reverse_search)
    fnames(i)=strmid(fnames(i),0,p-1)
end
print,fnames
map=uniq(fnames)

return,map
end