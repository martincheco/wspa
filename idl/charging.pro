pro charging

f=getfiles(/dirs)


for j=0,n_elements(f)-1 do begin
print,f(j)
cd,f(j)
t1=sts_toarea(getfiles(mask='Z*.dat'),sub=[5,11,6,12])
for i=0,3 do slicewsxm,'../'+file_basename(f(j))+'_'+strtrim(i,2)+'.stp',reform(t1(i,*,*)),xdim=3,ydim=0.95,zunit='nm',chan=strtrim(i,2)
cd,'..'
end

end
