pro varpos,numbers,pos,n,result
;generates recursively permutations in the array (numbers) from n elements
nn=n_elements(numbers)
w=where(numbers eq 0)
if 1 eq 1 then begin
	;position of the currently rotated number, 
	;breaks if its the last one  
	;now, determine which numbers are still unused
	nw=n_elements(w) ;number of elements that are occupied
	pnumbers=intarr(n-pos) ;array of still possible numbers
	cnt=0
	for i=1,n do begin
		ww=where(numbers eq i)
		if ww(0) eq -1 then begin ;only if a number is not used, add it
			pnumbers(cnt)=i
			cnt=cnt+1
		end 
	end
	for i=0,n-pos-1 do begin
		numbers(pos:*)=0
		numbers(pos)=pnumbers(i)
		if pos+1 lt nn then begin
			varpos,numbers,pos+1,n,result 
		end else begin
			result=[[result],[numbers]]
		end
	end
end

end

function genvar,n,nnn
;selection of n elements of nn
nums=intarr(n)
result=nums
varpos,nums,0,nnn,result

return,result(*,1:*)

end

function cols,vs,tst
;returns an array with dimensions of vs
;1 means a number is in tst, too, 0 not
 
s=size(vs)
sv=s(2)
n=s(1)

st=n_elements(tst)

ncols=vs*0
;number of colors that are ok


for i=0,st-1 do begin 
		w=where(vs eq tst(i))
		if w(0) ne -1 then ncols(w)=1
end

;return,ncols
return,total(ncols,1)
end

function hits,vs,tst
;returns an array with dimensions of vs
;1 means a number is in tst at the same pos, 0 not
 
s=size(vs)
sv=s(2)
n=s(1)

st=n_elements(tst)

ncols=vs*0
;number of colors that are ok


for i=0,st-1 do begin 
		w=where(vs(i,*) eq tst(i))
		if w(0) ne -1 then ncols(i,w)=1
end

;return,ncols
return,total(ncols,1)
end

function test,vs,tstres,ncols,nhits

s=size(tstres)
dims=s(0)
if dims eq 1 then tstres=reform(tstres,s(1),1)
s=size(tstres)
n=s(2)
ss=size(vs)

ww=intarr(ss(2))+1 
for i=0,n-1 do begin
	;help,tstres
	;help,i
	colsn=cols(vs,tstres(*,i))
	hitsn=hits(vs,tstres(*,i))
	w=(colsn eq ncols(i))
	wwcol=(ww * w)
	w=(hitsn eq nhits(i))
	wwhit=(ww * w)
	ww=ww*wwcol*wwhit 
end
;print,ww
www=where(ww eq 1)
;help,www

if www(0) ne -1 then begin
	res=vs(*,www)
	s=size(res)
	if s(0) eq 1 then return,reform(res,s(1),1) else return,res 
end else $
	return,-1
end


function shuffle, vs
s=size(vs)
n=s(2)
rvs=vs
;shuffles the variations
a=floor(n*randomu(seed,100000)-1)
b=floor(n*randomu(seed,100000)-1)
rvs(*,a)=vs(*,b)

return,rvs
end


pro logik
vs=genvar(5,8)
;help,vs
;vs=shuffle(vs)
barvy=strarr(10)
;tstres - result of the test
barvy[1]="black"
barvy[2]="red"
barvy[3]="yellow"
barvy[4]="blue"
barvy[5]="green"
barvy[6]="grey"
barvy[7]="pink"
barvy[8]="white"
barvy[9]="empty"
;vs - array containing possibilities
;print,cols(vs,[1,2,4])
;print,hits(vs,[1,2,4])
;help,vs
;help,cols(vs,[1,2,4])
;print,barvy(vs)
print,"**"

tstres=vs(*,0)
print,barvy(tstres(*,0))
ncols=-1
nhits=-1
s=size(vs)

while vs(0) ne -1 do $
begin
	read,"colors:",a
	read,"hits:",b
	a=(a>0)<5
	b=(b>0)<5
	if ncols(0) eq -1 then ncols=a else ncols=[ncols,a]
	if nhits(0) eq -1 then nhits=b else nhits=[nhits,b]
	s=size(vs)
	if s(2) gt 1 then begin
		vs=test(vs(*,1:*),tstres,ncols,nhits)
		help,vs
	;	print,barvy(vs)
		print,"**"
		if vs(0) ne -1 then begin
			tstres=[[tstres],[vs(*,0)]]
	;	help,tstres
			print,barvy(vs(*,0))
		end
	end else begin
		print, 'That was the last option!'		
		vs=-1
	end

end

print,"No more options!"
print,"All guesses:"
print,barvy(tstres)

end
