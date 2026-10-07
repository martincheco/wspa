pro xsf_dump,f,range=range
if not(keyword_set(f)) then f=dialog_pickfile()

t=xsf_read(f)


dt=t.data


if keyword_set(range) then dt=dt(range,*,*)


s=size(dt)

for i=0,s(1)-1 do begin
	ff=file_dirname(f)+path_sep()+file_basename(f,'.xsf')+'_'+strtrim(string(i,format='(I04)'),2)
	print,ff
	write_png,ff+'.png',bytscl(reform(dt(i,*,*)))
	slicewsxm,ff+'.stp',bytscl(reform(dt(i,*,*)))
end




end
