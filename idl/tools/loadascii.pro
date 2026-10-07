function loadascii,f
if not(keyword_set(f)) then f=dialog_pickfile(/must_exist)

t=read_ascii(f)

return,t.(0)
end

