function read_profile,f
if file_test(f) then begin
str=read_ascii(f)
data=str.(0)
return,{r:data(0,*),z:data(1,*)}
end else return,-1
end