function sts_toarea,f,sub=sub,bias=bias
;reads multiple z or v spectroscopies and puts to an aray(file_index,data(0)_index,channel)
;values - an array with the independent quantity, must have the same dim. as f
;sub - subchannels to select
;bias - try to extract bias fro sts files

if not(keyword_set(f)) then f=dialog_pickfile(/must_exist,/multiple)

n=n_elements(f)
bias=dblarr(n)
t=loadnanonis_sts(f(0))
bias(0)=t.p.bias*1000

s=size(t.data)
chans=s(1)
help,t.data
print,s(1)
if not(keyword_set(sub)) then sub=indgen(chans) else chans=n_elements(sub)
stack=dblarr(chans,n,s(2))

help,chans
help,sub
help,n

for j=0,chans-1 do stack(j,0,*)=t.data(sub(j),*)

for i=1,n-1 do begin
    t=loadnanonis_sts(f(i))
    bias(i)=t.p.bias*1000
    for j=0,chans-1 do stack(j,i,*)=t.data(sub(j),*)
end

return,stack
end