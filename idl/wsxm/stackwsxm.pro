pro stackwsxm,t,chans=chans,xdim=xdim,ydim=ydim,units=units

;exports stack to current subdir as wsxm files
;chans allows specifying the channel names

s=size(t)

for i=0,s(1)-1 do $
;slices
    for j=0,s(2)-1 do begin
    ;channels
	is=string(i,format='(I04)')
	js=string(j,format='(I02)')
	path='slice_'+is+'.f.ch'+js
	print,path
	slicewsxm,path,reform(t(i,j,*,*)),zunit=units(j),chan=chans(j),xdim=xdim,ydim=ydim
    end


end