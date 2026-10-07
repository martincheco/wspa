function mloadwsxm,f,preselect=preselect,sts=sts,mask=mask
;load entire list of files into a structure, THEY DO NOT HAVE TO BE THE SAME SIZE
;supports also lists
;sts - to search for sts files
cd,current=c
if not(keyword_set(mask)) then mask=['*.sxm;*.top;*.ch*;*.stp','*.par','*.dat','*.nc','*.txt']

if not(keyword_set(f)) then f=dialog_pickfile(/multiple_files,/must_exist,filter=mask,path=c)
if n_elements(f) eq 0 then return,-1

n=n_elements(f)
;print,f


if n eq 1 then begin
    print,"probably a list"
    ff=strtrim(f,2)
    fb=file_dirname(ff)
    pos=strpos(ff,'.lst',/reverse_search)
    ;print,pos,strlen(fb)
    ext=strlowcase(strmid(ff,2,/reverse))
    if pos gt strlen(fb) and file_test(ff) then begin
	f=loadlist(ff)
	;help,f
	;help,fb
	n=n_elements(f)
	for i=0,n-1 do begin ;tweak for the lists of omicron files
	    fm=f(i)
	    p=strpos(fm,'.tf')
	    if p eq -1 then p=strpos(fm,'.tb')
	    if p ne -1 then strput,fm,".par",p
	    f(i)=fm
	end
	
	f=f(uniq(f,sort(f)))
	n=n_elements(f)
	
	for i=0,n-1 do begin
	    if fb ne "." then f(i)=fb+'/'+f(i)
	end
    end else print,"No, "+ext+ " is not a list, continuing"
end

;print,f

c=0 ;counter for the pointers
pmdata=ptrarr(n*64) ;max 64 channels per file
help,n
print,'max. ptr',n*64

;m#ain reading loop
for i=0,n-1 do begin

print,'loading file '+strtrim(string(i+1),2)+' of '+strtrim(string(n),2)+' : '+f(i)
;test if it is omicron
    fb=file_dirname(f(i))
    
    ;print,strlowcase(strmid(f(i),2,/reverse))
    case strlowcase(strmid(f(i),2,/reverse)) of 

    'par' : $ ;omicron SCALA format
	begin
	    ;print,file_basename(f(i))+': Omicron .par file!'
	    mchunk=loadomicron(f(i),preselect=preselect)
	
	    if n_tags(mchunk) ne 0 then begin
		nchunk=n_elements(mchunk)
	    
		for j=0,nchunk-1 do begin
		    ;help,mchunk(j)
		    pmdata(c)=ptr_new(mchunk(j))
		    c=c+1
		end
	    end
	end
    
    ;for Createk
    'dat' : $ 
	begin
	    mchunk=loadcreatek(f(i))
	    ;help,mchunk
	    if n_tags(mchunk) ne 0 then begin
		nchunk=n_elements(mchunk)
	
		for j=0,nchunk-1 do begin
		    ;help,mchunk(j)
		    pmdata(c)=ptr_new(mchunk(j))
		    c=c+1
		end
	    end
	end

    ;gsxm
    'nc' : $
	begin
	    pmdata(c)=ptr_new(loadgsxm(f(i)))
	    c=c+1
	end

    ;nanonis
    'sxm' : $
	begin
	    spectrum=1
	    mchunk=loadnanonis(f(i),spectrum=spectrum) ;basically skips the spectroscopic data
	    ;aa=mchunk.par
	    ;print,aa(0,*)
	    ;print,"--"
	    if n_tags(mchunk) ne 0 then begin
		nchunk=n_elements(mchunk)
		for j=0,nchunk-1 do begin
;		    help,pmdata
;		    help,mchunk
;		    help,mchunk(j)
;		    help,f(i)
		    pmdata(c)=ptr_new(mchunk(j))
		    c=c+1
		    if j gt 64 then break
		end
	    end
	end


    ;output from FIREBALL STM sim.
    'out' : $
	begin
	    pmdata(c)=ptr_new(loadfire(f(i)))
	    c=c+1
	end

     ;TXT simple file
    'txt' : $
	begin
	    pmdata(c)=ptr_new(loadtxt(f(i)))
	    c=c+1
	end

   
    else: $
    ;wsxm
	begin
	    pmdata(c)=ptr_new(loadwsxm(f(i)))
	    c=c+1
	end

    endcase

endfor

    if c ne 0 then return,pmdata(0:c-1) else return,0
end

;function wsxm,a
;return,a
;end
