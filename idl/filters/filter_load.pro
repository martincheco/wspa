function filter_load,file,inter=inter
;inter sets interactive opening of a filter
;loads filter
if keyword_set(inter) then file=dialog_pickfile(/must_exist,filter='*.flt')
openr,1,file,error=err
if err ne 0 then begin
print,"Error opening file"
return,{type:["none"],par1:[0],par2:[0],par3:[0]}
end
filttype=strarr(42)
filtpar1=dblarr(42)
filtpar2=dblarr(42)
filtpar3=dblarr(42)
if not(keyword_set(file)) then return,{type:["none"],par1:[0],par2:[0],par3:[0]}
i=0
WHILE NOT(EOF(1)) and i lt 42 DO begin
    ;print,i,EOF(1)
    line=""
    readf,1,line
    if strtrim(line,2) ne "" then $
    begin
	fields=strsplit(line,/extract)  
	nel=n_elements(fields)
	filttype(i)=fields(0)
        if nel gt 1 then filtpar1(i)=double(fields(1))
        if nel gt 2 then filtpar2(i)=double(fields(2))
        if nel gt 3 then filtpar3(i)=double(fields(3))
	i=i+1
    endif
end
close,1

if i ne 0 then filt={type:filttype(0:i-1),par1:filtpar1(0:i-1),par2:filtpar2(0:i-1),par3:filtpar3(0:i-1)} $
else filt={type:["none"],par1:[0],par2:[0],par3:[0]}

return,filt
end
