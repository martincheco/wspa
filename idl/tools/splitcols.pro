function splitcols,dt
;converts data in columns (has to be a string arrray) into array of doubles
n=n_elements(dt)
dts=strsplit(dt(0),/extract)
nc=n_elements(dts)
dtar=strarr(nc,n)
for i=0,n-1 do begin
    dtar(*,i)=strsplit(dt(i),/extract)
end
print,dtar(*,0:10)
return,double(dtar)
end