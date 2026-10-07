function read_fort25,f ; reads an output from the crystal code, namely what comes out as fort.25
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist, filter = 'fort.*')

s=read_ascii(f)
help,s,/structure
a=s.field1

x=round(float(a(1)))
y=round(float(a(2)))
print,x,y
s=read_ascii(f,data_start=3)
help,s,/structure
a=s.field1
help,a
a=float(reform(a,n_elements(a)))
help,a
b=reform(a(0:x*y-1),x,y)
return,b
end