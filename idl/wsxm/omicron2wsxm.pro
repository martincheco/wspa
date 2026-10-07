pro omicron2wsxm,dirr

if not(keyword_set(dirr)) then dirr=dialog_pickfile(/directory,/must_exist)
if dirr eq "" then return

;file_mkdir,dirr+"_wsxm"

dirs=file_search(dirr+'/*')
print,dirs

for i=0,n_elements(dirs)-1 do begin
    print,dirs(i)
    ndir=file_dirname(dirr)+"/"+file_basename(dirr)+"_wsxm/"+strmid(file_basename(dirs(i)),8,16)

    print, ndir
    file_mkdir,ndir

    filez=file_search(dirs(i),'*.par',count=count)
;    help,filez
    if count ne 0 then $
    for j=0,n_elements(filez)-1 do begin
	a=mloadwsxm(filez(j))
	pv=ptr_valid(a)
	if pv(0) ne 0 then $
	for k=0,n_elements(a)-1 do begin
	    orifilename=file_basename((*a(k)).par(0))
	    nfilename=ndir+"/"+orifilename
	    print,nfilename
	    savewsxm,*a(k),nfilename
	end ;else print,"No data in the .par file!"
	if pv(0) ne 0 then ptr_free,a
    end ;else print, "No data found!"

end

end