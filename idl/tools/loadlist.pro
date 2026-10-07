function loadlist,file
openr,1,file
lst=strarr(999)
i=0
while NOT(EOF(1)) do begin 
line=""
readf,1,line
lst(i)=line
i=i+1
end
close,1
lst=lst(0:i-1>0)
return,lst
end
