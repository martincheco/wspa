pro find_f_test,n,mir=mir
a=loadnanonis(getfiles(mask="*068.sxm"))
am=a.img
ac=am(50:-50,50:-50,0)
s=size(ac)
if keyword_set(mir) then ac=reverse(ac)

ac=reform(ac,1,s(1),s(2))
ac=ac-min(ac)
no=string(n,format='(I03)')

print,no

b=loadnanonis(getfiles(mask="*"+no+".sxm"))
bm=b.img
bc=bm(*,*,0)
s=size(bc)
bc=reform(bc,1,s(1),s(2))
bc=bc-min(bc)

t=register_iter(ac,bc,1.,0.,0.,0.,0.,0.,0.,step=[0.,32.,0.,6.,6.,0.,0.],mask=[0.,1.,0.,1.,1.,0.,0.],/vis)


end




function find_f,a,b
;finds a feature in an image
;a is the sample
;b is the image
;uses the iterative correlation method
a=register2(a,b)



return,[xpos,ypos,ang]
end

