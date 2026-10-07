function genx,x,y
return,x-y/2
end

function geny,x,y
return,y*3^0.5/2
end

function genscript,img,d,sa,sb
s=size(img)
entr=string(10B)
if n_elements(sa) gt 1 then sa=strjoin(sa,entr)
if n_elements(sb) gt 1 then sb=strjoin(sb,entr)

scrpt=''
c=0
for i=0,s(1)-1 do $
    for j=0,s(2)-1 do begin
	
	x=(i-s(1)/2)*d
	y=(j-s(2)/2)*d
	hx=x;genx(x,y)
	hy=y;geny(x,y)
	x=strtrim(string(hx),2)
	y=strtrim(string(hy),2)
	if img(i,j) gt 0 then begin
	    scrpt=scrpt+sa+entr
	    scrpt=scrpt+'mv '+x+' '+y+entr
	    scrpt=scrpt+sb+entr
	    c=c+1
	end
    end
print,c
return,scrpt
end
