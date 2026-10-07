pro cube_slices,f,chan=chan
d=read_cube(f)

s=size(d.data)


for i=0,s(2)-1 do begin
	ii=string(i,format='(I03)')
	path=ii+".ch"+chan
	print,path
	slc=reform(d.data(*,i,*))
	slice=transpose(slc);congrid(slc,121,cubic=-0.5))
	slicewsxm,path,slice,xdim=d.xdim/10.,ydim=d.zdim/10.,zunit="nm",chan=file_basename(f)
end

end

