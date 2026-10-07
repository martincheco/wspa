function profily
cd,"/home/martin/newvers"
x6=rd_int_raw('6x6.raw')
si4=rd_int_raw('Si4.raw')
si5=rd_int_raw('Si5.raw')
si2a=rd_int_raw('Si2a.raw')
si2b=rd_int_raw('Si2b.raw')
si2c=rd_int_raw('Si2c.raw')

h=[[[x6]],[[si4]],[[si5]],[[si2a]],[[si2b]],[[si2c]]]

a=fltarr(235,6)
b=a

for i=0,5 do begin
aa=mprofile(reform(h(*,*,i)),160,150,32,343)
bb=mprofile(reform(h(*,*,i)),192,182,53,363)
a(*,i)=aa(19:253)
b(*,i)=bb(56:290)
end

return,[[[a]],[[b]]]
end



pro save_profily, a


s=size(a)

openw,1,'/home/martin/newvers/profily_a.dat'

for i=0,s(1)-1 do begin
printf,1,reform(a(i,*,0))
endfor

close,1

openw,1,'/home/martin/newvers/profily_b.dat'

for i=0,s(1)-1 do begin
printf,1,reform(a(i,*,1))
endfor

close,1

end
