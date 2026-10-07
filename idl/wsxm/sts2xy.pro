pro sts2xy_export,r,f=f,suffix=suffix,chans=chans,avg=avg
;exports nanonis sts data to xy format
s=size(r.data)


if keyword_set(f) then fname=f else fname=r.p.f
print,n_elements(r.chans(1:*))


nchns=((n_elements(r.chans(1:*)))/2)
help,nchns
chns=indgen((n_elements(r.chans(1:*)))/2)
print,chns
if keyword_set(avg) then data=(r.data(chns+1,*)+r.data(chns+nchns+1,*))/2. else data=r.data

print,chns+1
print,chns+nchns+1

help,r,/st
if not(keyword_set(suffix)) then suffix='xp'
if not(keyword_set(chans)) then chans=indgen(n_elements(data(*,0)))

openw,1,fname+'.'+suffix,width=1024
for i=0,s(2)-1 do begin
printf,1,r.data(0,i),data(chans,i)
end

close,1

end


pro sts2xy,f,suffix=suffix,chans=chans,avg=avg

if not(keyword_set(f)) then f=dialog_pickfile(/multi)

for i=0,n_elements(f)-1 do begin
print,'reading '+f(i)
r=loadnanonis_sts(f(i))
print,'exporting '+f(i)
sts2xy_export,r,f=f(i),suffix=suffix,chans=chans,avg=avg
end

end

