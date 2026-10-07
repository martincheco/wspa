function tstr,x
return,strtrim(string(x),2)

end

function xsf_atoms,at
e=string(10B)
t=string(9B)
n=n_elements(at.z)
str=string(n)+t+'1'+e
for i=0,n-1 do str+=tstr(fix(at.at(i)))+t+tstr(real_part(at.xy(i)))+t+tstr(imaginary(at.xy(i)))+e

return,str
end

pro xsf_write,f,stn,at=at
;writes an xsf
;at are atomic coordinates and primitive unit cell vectors
;cell are datagrid vectors
st=transpose(stn,[1,2,0])
s=size(st)
if not(keyword_set(at)) then begin
	a=[s(1),0.,0.]
	b=[0.,s(2),0.]
	c=[0.,0.,s(3)]
end else begin
	sx=vector(at.e,at.x,at.y)
	sy=vector(at.f,at.x,at.y)
	a=[real_part(sx),imaginary(sx),0.]
	b=[real_part(sy),imaginary(sy),0.]
	c=[0.,0.,abs(at.zz)]
end


e=string(10B)
t=string(9B)
str='CRYSTAL'+e
str+='PRIMVEC'+e
as=strjoin(tstr(a),t)+e
bs=strjoin(tstr(b),t)+e
cs=strjoin(tstr(c),t)

str+=as+bs+cs+e
str+='CONVVEC'+e
str+=as+bs+cs+e
str+='PRIMCOORD'+e
if not(keyword_set(at)) then begin 
	str+='1'+t+'1'+e
	str+='1'+t+'0'+t+'0'+t+'0'+e
end else str+=xsf_atoms(at)
str+=e
str+='BEGIN_BLOCK_DATAGRID_3D'+e
str+='density_3D'+e
str+='BEGIN_DATAGRID_3D_DENSITY'+e
str+=tstr(s(1))+t+tstr(s(2))+t+tstr(s(3))+e
str+='0'+t+'0'+t+'0'+e

str+=as+bs+cs

strend='END_DATAGRID_3D'+e+'END_BLOCK_DATAGRID_3D'+e
openw,1,f
printf,1,str
n=n_elements(stn)
for i=0,n-1 do printf,1,st(i)
printf,1,strend
close,1
end
