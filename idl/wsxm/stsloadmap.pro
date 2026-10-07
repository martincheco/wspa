function stsloadmap,f

r=read_file(f,/array)

dir=file_dirname(f)

n=n_elements(r)

ptrs=ptrarr(n)

for i=0,n-1 do begin
	ptrs(i)=ptr_new(loadnanonis_sts(dir+'/'+r(i),/head))

end

return,ptrs
end

