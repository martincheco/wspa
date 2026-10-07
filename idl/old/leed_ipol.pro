function leed_ipol,x1,x2,e1,e2,enew
x1=double(x1)
x2=double(x2)
e1=double(e1)>0
e2=double(e2)>0
enew=double(enew)>0
renew=enew^0.5

re1=e1^0.5
re2=e2^0.5

const=(x2-x1)*re1*re2/(re1-re2)
x8=x2-const/re2
x82=x1-const/re1
print,x8,x82

xnew=const/renew+x8
plot,enew,xnew

return,xnew
end
