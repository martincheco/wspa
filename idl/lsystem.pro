function str2arr,a
;converts string to an array of single letters
n=strlen(a)
b=strarr(n)
for i=0,n-1 do begin
	b(i)=strtrim(strmid(a,i,1),2)
end

return,b
end


pro lsystem,a,n
;procedure that calls function lsystem n times
;a is the input string
for i=0,n-1 do begin 
	a=lsystem(a)
	print,a
end

end


function lsystem,a
;rewrites the string a using the rules
b=str2arr(a)
n=n_elements(b)
pd=0
res='' ;the translated string

for i=1,n-1 do begin   ;goes through the array of letters
	if b(i) ne b(i-1) then begin ;checks if current character is different from the previous one
		res+= strtrim(string(i-pd),2) + b(i-1) ;number of same characters + character
		pd=i ;store the position
	end 	
end
res=res+strtrim(string(n-pd),2) + b(n-1) ;add the last character

return,res
end


