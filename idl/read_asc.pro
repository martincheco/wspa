function read_asc,f
;read asc exported from Matrix(?)

r=read_file(f,/igcom,/arr)
n=n_elements(r)
;print,r(0)
a=strsplit(r(0),',',/extract)
img=strarr(n,n_elements(a))
;help,img
for i=0,n-1 do begin
	img(i,*)=reform(strsplit(r(i),',',/extract))
end
;help,img
return,double(img)
end
