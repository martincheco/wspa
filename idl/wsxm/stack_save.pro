pro stack_save,f,st
s=size(st)
if s(0) eq 3 then begin
s1=strtrim(string(s(1)),2)
s2=strtrim(string(s(2)),2)
s3=strtrim(string(s(3)),2)
f=f+"_"+s1+"_"+s2+"_"+s3+".dbl"
end
if s(0) eq 2 then begin

s1=strtrim(string(s(1)),2)
s2=strtrim(string(s(2)),2)
f=f+"_"+s1+"_"+s2+".dbl"

end


openw,1,f
writeu,1,double(st)
close,1
end
