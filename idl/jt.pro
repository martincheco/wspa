;set of routines that control directly the NANONIS via the labview interface

pro jt,url
defsysv,'!JT',{host:'c192',timeout:'5',port:'3020',url:'http://c192/Measurements/',loc:'D:/Measurements/',path:''}
e=jt_stat()
cd,'/home/martin/jt'
end

function jt_cmd,cmd
;sends a command to the machine, returns the result (if any)
;if wait is set, waits for the end of cmd execution
;print,'echo "'+cmd+'" | nc -w '+!JT.timeout+' -C '+!JT.host+' '+!JT.port
res='no reply'
spawn,'echo "'+cmd+'" | nc -w '+!JT.timeout+' -C '+!JT.host+' '+!JT.port,res,/sh
;strip newlines, they make a mess
;help,strlen(res(11))

for i=0,n_elements(res)-1 do res(i)=strmid(res(i),0,strlen(res(i))-1)
return,res
end

function jt_wait
wait,0.2 ;safety wait
c=0
;print,'wait proc'
stt=jt_stat()

while stt.exec ne 0 or stt.scan ne 0 do begin
;print,c
    if c eq 4 then Print,'Waiting to finish..'
    c=c+1
;    print,'waiting..'
;    help,stt,/st
    wait,0.25
    stt=jt_stat()

;    help,stt.scan
;    help,stt.exec
end

return,1
end

function jt_cmdw,cmd
t=jt_cmd(cmd)
w=jt_wait()
return,t
end

function dissect,rorig
;designed to make a structure out of the par result, whatever it is
r=rorig
n=n_elements(r)
n=n/2 ;it comes in pairs
mj=strarr(n)
mn=mj
unit=mj
val=mj

for j=0,n-1 do begin
    i=2*j
;    if strpos(r(i),'INF') ne -1 then print,r(i)

    p=strsplit(r(i),">",/extract)
;    print,p
;    help,p
    ;p(0) is major group, p(1) minor with an optional unit
    mj(j)=strjoin(strsplit(p(0)," /-.",/extract),"")
    m=strsplit(p(1),"()",/extract)
;    help,m
    if n_elements(m) gt 1 then unit(j)=m(1) else unit(j)=""
    mn(j)=strjoin(strsplit(m(0)," /-.",/extract),"")
    val(j)=r(i+1)
;    print,mj(j),'|',mn(j),'|',unit(j),'|',val(j)
end

;build up a string defining the structure
struc="strukt={"
for i=0,n-1 do begin
;    print,i
;    help,mj(i)
    if mj(i) eq mn(i) then struc+=mj(i)+":" else struc+=mj(i)+'_'+mn(i)+":"
    ;check if val is a valid number
    y=strnumber(val(i),vl)
    if y eq 1 and finite(vl) ne 1 then y=0 ;workaround for infinities and Nans
    if y eq 1 then struc+=strtrim(string(vl),2) else struc+='"'+val(i)+'"'
    if i ne n-1 then struc+=', '
end
struc+='}'

;print,struc

void=execute(struc)

return,strukt
end

function jt_stat
;gets a quick status, good enough to get basic info about the script etc.
r=jt_cmd("")
nstat=''
for i=0,n_elements(r)-1 do begin
    prt=strsplit(r(i),string(59B),/extract)
    nstat=[nstat,strtrim(prt,2)]
end
r=nstat[1:*]


scan=strpos(r(0),"SCAN") ne -1
exec=strpos(r(0),"EXEC") ne -1
w=where(strpos(r,"last=") ne -1)
if w(0) ne -1 then last=strsplit(r(w(0)),"last=",/regex,/extract)
last=strjoin(strsplit(last,'"',/extract),'')
last=strjoin(strsplit(last,'\',/extract),'/')
last=strjoin(strsplit(last,!JT.loc,/regex,/extract),'')

w=where(strpos(r,"path=") ne -1)
if w(0) ne -1 then path=strsplit(r(w(0)),"path=",/regex,/extract)
path=strjoin(strsplit(path,'"',/extract),'')
path=strjoin(strsplit(path,'\',/extract),'/')
path=strjoin(strsplit(path,!JT.loc,/regex,/extract),'')

w=where(strpos(r,"mode=") ne -1)
if w(0) ne -1 then mode=strsplit(r(w(0)),"mode=",/regex,/extract)
mode=strjoin(strsplit(mode,'"',/extract),'')

w=where(strpos(r,"cen=") ne -1)
;print,r(w(0))
if w(0) ne -1 then cen=strsplit(r(w(0)),"cen=",/regex,/extract)
cen=strjoin(strsplit(cen,'()nm',/extract),'')
cen=strsplit(cen,',',/extract)
cen=double(cen)

w=where(strpos(r,"pos=") ne -1)
;print,r(w(0))
if w(0) ne -1 then pos=strsplit(r(w(0)),"pos=",/regex,/extract)
pos=strjoin(strsplit(pos,'()nm',/extract),'')
pos=strsplit(pos,',',/extract)
pos=double(pos)

w=where(strpos(r,"I=") ne -1)
;print,r(w(0))
if w(0) ne -1 then i=strsplit(r(w(0)),"I=",/regex,/extract)
i=strjoin(strsplit(i,'I=nA',/extract),'')
i=double(i)
w=where(strpos(r,"df=") ne -1)
;print,r(w(0))
if w(0) ne -1 then df=strsplit(r(w(0)),"df=",/regex,/extract)
df=strjoin(strsplit(df,'df=Hz',/extract),'')
df=double(df)
w=where(strpos(r,"U=") ne -1)
;print,r(w(0))
if w(0) ne -1 then v=strsplit(r(w(0)),"U=",/regex,/extract)
v=strjoin(strsplit(v,'U=mV',/extract),'')
v=double(v)
w=where(strpos(r,"Z=") ne -1)
;print,r(w(0))
if w(0) ne -1 then z=strsplit(r(w(0)),"Z=",/regex,/extract)
z=strjoin(strsplit(z,'Z=mV',/extract),'')
z=double(z)
w=where(strpos(r,"phi=") ne -1)
;print,r(w(0))
if w(0) ne -1 then phi=strsplit(r(w(0)),"phi=",/regex,/extract)
phi=strjoin(strsplit(phi,'phi=deg',/extract),'')
phi=double(phi)
w=where(strpos(r,"a=") ne -1)
;print,r(w(0))
if w(0) ne -1 then a=strsplit(r(w(0)),"a=",/regex,/extract)
a=strjoin(strsplit(a,'a=nm',/extract),'')
a=double(a)
w=where(strpos(r,"px") ne -1)
;print,r(w(0))
if w(0) ne -1 then px=strsplit(r(w(0)),"px",/extract)
px=uint(px)


stat={scan:scan,exec:exec,last:last(0),stat:r,path:path,cen:cen,pos:pos,mode:mode,v:v,i:i,z:z,df:df,a:a,phi:phi,px:px}
!JT.path=path
return,stat
end

function jt_file,f
spawn,'rm "'+file_basename(f)+'"'
quer='wget -O "'+file_basename(f)+'" "'+!JT.url+f+'"'
;print,quer
spawn,quer,res
return,res
end

function jt_list,last=last,sts=sts
;reads list of files in the directory of the last file
;last gets the last file of specified type (image default)
;sts specifies if last sts should be returned
quer='wget -O list "'+!JT.url+'/'+!JT.path+'/?tpl=list"'
print,quer
spawn,'rm list'
spawn,quer,res
l=read_file('list',/arr)
if keyword_set(sts) then srch='.dat' else srch='.sxm'
l=file_basename(l)
w=where(strpos(l,srch) ne -1)
if w(0) ne -1 then l=l(w)
n=n_elements(l)

;sorting, numbers in nanonis botched

nn=n_elements(l)
nums=intarr(nn)

for i=0,nn-1 do begin
    b=strsplit(l(i),'[0-9]+',/regex,/extract)
    lte=strjoin(strsplit(l(i),b(0),/extract),'')
    lte=strjoin(strsplit(lte,b(1),/extract),'')
    nums(i)=uint(lte)
end
srt=sort(nums)
l=l(srt)
if keyword_set(last) then l=l(n-1)
;print,l
return,l
end

function jt_last_img
r=jt_stat()
l=jt_list(/last)
print,l
res=jt_file(!JT.path+'/'+l)
img=loadnanonis(file_basename(l))
return,img
end

function jt_last_sts
r=jt_stat()
l=jt_list(/sts,/last)
res=jt_file(!JT.path+'/'+l)
sts=loadnanonis_sts(l)
return,sts
end

function jt_par
;gets all parameters, slower, but has some additional info
res=jt_cmd("par")
;strip newlines, they mess up things
;for i=0,n_elements(res)-1 do res(i)=strmid(res(i),0,strlen(res(i))-1)
par=dissect(res)
return,par
end


function jt_experiment_1,n
jt
z1=dblarr(n,n)
z2=z1
r=z1
d=3. ;elementary distance
dd=strtrim(string(2*d/3.),2)

for i=0,n-1 do for j=0,n-1 do begin
    t=jt_cmdw('sts_z_dist 0 -0.800')
    x=(i-n/2)*d
    y=(j-n/2)*d
    x=strtrim(string(x),2)
    y=strtrim(string(y),2)
    cmd1='mv ' + x + ' ' + y
    cmd2='feed 0'
    cmd2a='v 0'
    cmd3='sts_z'
    cmd3a='v -350'
    cmd4='feed 1'
    cmd5='dmv '+dd+' '+dd
    cmd6='wait 50'
    cmd7='dmv -'+dd+' -'+dd


;    print,cmd1
    t=jt_cmdw(cmd1)

    stsstart:
    
;    print,cmd2
    t=jt_cmdw(cmd2)
;    print,cmd2a
    t=jt_cmdw(cmd2a)
;    print,cmd3
    t=jt_cmdw(cmd3)
;    print,cmd3a
    t=jt_cmdw(cmd3a)
;    print,cmd4
    t=jt_cmdw(cmd4)
;    print,cmd5
    t=jt_cmdw(cmd5)
;    print,cmd6
    t=jt_cmdw(cmd6)
    s1=jt_stat()
    t=jt_cmdw('z='+strtrim(string(s1.z),2))
    z1(i,j)=s1.z
;    print,cmd7
    t=jt_cmdw(cmd7)
;    print,cmd6
    t=jt_cmdw(cmd6)
    s2=jt_stat()
    t=jt_cmdw('z='+strtrim(string(s2.z),2))
;    print,'z=',s2.z
    z2(i,j)=s2.z
    diff= (s2.z-s1.z)
    print,'DZ  =',diff
    if diff lt 0.02 and diff gt -0.01 and r(i,j) lt 5 then begin
	print,'REPEATING',i,j,r(i,j)
	r(i,j)+=1
	dst=strtrim(string(-0.8-r(i,j)*0.05),2)
	print,dst
	t=jt_cmdw('sts_z_dist 0 '+dst)
	goto, stsstart
    end
end

t=jt_cmd('scan')

return,{r:r,z1:z1,z2:z2}
end


