function tmtrace_read

f=dialog_pickfile(/multi,/must)

r=loadnanonis_sts(f(0))

n=n_elements(f)
rr=r.data
s=size(rr)
t=reform(rr(0,*))
h=lonarr(n,s(2))

for i=0,n_elements(f)-1 do begin
	rx=loadnanonis_sts(f(i))
	h(i,*)=rx.data(1,*)
end


return,{t:t,h:h}
end

function tmtrace_rebin,tr,n
;rebins to bigger bins by factor n

s=size(tr.h)

newn=s(2)/n
l=newn*n



nh=lonarr(s(1),newn)

nt=rebin(reform(tr.t(0:l-1)),newn)

for i=0,s(1)-1 do begin
	nh(i,*)=rebin(reform(tr.h(i,0:l-1)),newn)
end

return,{t:nt,h:nh}
end

pro tmtrace_export,f,tr

s=size(tr.h)

openw,1,f,width=100000
for i=0,s(1)-1 do printf,1,reform(tr.h(i,*))
close,1

end

