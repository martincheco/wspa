pro sts2txt_old,f,subchans
n=n_elements(f)
for i=0,n-1 do begin
	t=loadnanonis_sts(f(i))
	openw,1,f(i)+'.txt',width=1024
	s=size(t.data)
	if not(keyword_set(subchans)) then subchans=indgen(s(1))
	for j=0,s(2)-1 do printf,1,t.data(subchans,j)
	close,1
end

end


pro sts2txt,f,subchans=subchans,trans=trans

t=sts_toarea(f,sub=subchans,bias=bias)

if keyword_set(trans) then begin
	t=transpose(t,[0,2,1])
	s=size(t)
	help,t
	help,reform(bias,1,1,n_elements(bias))
	if n_elements(bias) eq n_elements(f) then begin
		bb=transpose(mreplicate(bias,s(2)))
		help,bb
		t=[reform(bb,1,s(2),s(3)),t]
	end
end

s=size(t)
help,s
for i=0,s(2)-1 do begin
	openw,1,strtrim(string(i,format='(I04)'),2)+'.txt',width=1024
	for j=0,s(3)-1 do printf,1,reform(t(*,i,j))
	close,1
end

end
