function read_pw,f ; reads an output from the pw code
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist)




s=read_ascii(f,data_start=202)
;help,s,/struct
a=s.field1
;print,a(0:200)

x=round(float(a(0)))
y=round(float(a(1)))
;print,x,y
s=read_ascii(f,data_start=206)
;help,s,/structure
a=s.field1
;print,a(0:200)


a=a(0:n_elements(a)-13)
;help,a
a=float(reform(a,n_elements(a)))
;help,a
b=reform(a(0:x*y-1),x,y)
;help,b
return,b
end

function read_seq,sav=sav
f = dialog_pickfile(/read, /must_exist,/multiple_files)
a=read_pw(f(0))
s=size(a)
ar=fltarr(s(1),s(2),n_elements(f))
for i=0, n_elements(f)-1 do begin
g=read_pw(f(i))
ar(*,*,i)=g
if keyword_set(sav) then write_tiff,f(i)+'.tif',bytscl(g)
print,f(i),total(g)
end

return,ar
end