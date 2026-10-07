pro hometemp,f
print,'reading'
a=read_file(f,/array)

n=n_elements(a)
openw,1,f+'.csv'
print,'writing'
for i=0,n-1 do begin

	lne=a(i)
	s=strsplit(lne,/extract)
	dt=s(0)
	tm=s(1)
	sens=s(2)
	ss=strsplit(sens,"|",/extract)
	res=''
	for j=0,n_elements(ss)-1 do begin
		nm=strmid(ss(j),0,2)
		vl=strmid(ss(j),2)
		res=res+vl+','
	end
	printf,1,dt," ",tm,",",res
end

close,1


end



