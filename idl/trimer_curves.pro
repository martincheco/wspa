function trimer_curves,flist,bkg

n=n_elements(flist)

t=loadnanonis_sts(flist(0))
b=loadnanonis_sts(bkg)

data=t.data



for i=1,n-1 do begin
	a=loadnanonis_sts(flist(i))
	data+=a.data
end

t.data=data/n

return,t
end




