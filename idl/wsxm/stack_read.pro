function stack_getsizes,fo
	f=file_basename(fo)
	fs=strsplit(f,".",/extract)
	
	fss=strsplit(fs(0),"_|-",/extract,/regex)
print,fss
return,fss(-3:-1)
end


function stack_read,f
s=stack_getsizes(f)
help,s
print,s
nm=bytarr(3)
help,nm
for i=0,2 do nm(i)=isnumeric(s(i))

if total(nm) eq 3 then st=dblarr(s(0),s(1),s(2))*(-0./0.)
if total(nm) eq 2 then st=dblarr(s(1),s(2))*(-0./0.)
if total(nm) eq 1 then st=dblarr(s(2))*(-0./0.)

help,st
openr,1,f
readu,1,st
close,1
return,st
end
