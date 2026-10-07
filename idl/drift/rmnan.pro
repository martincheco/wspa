function rmnan,a
b=a
m=median(a)
i=where(finite(a) eq 0)

if i(0) ne -1 then begin
    b(i)=m
end
return,b
end