function updown_dir,directory, dir,dirlist=dirlist ;gets a next or previous directory from given directory

a= File_dirname(directory, /mark_directory)
if keyword_set(dirlist) and n_elements(dirlist) gt 0 then $
begin
print, 'Using the directory list..'
b=dirlist
end $
else $
begin
;spawn,'ls '+a,b
b=File_basename(file_search(a+'*/'))
xcc=n_elements(b)
print,'Directory '+a+' contains '  +strtrim(string(xcc),1)+ ' dirs.'
end

c=File_Basename(directory)
;bb=File_Basename(b)

i=where(b eq c)
help,b
print,c
print,b(3)
sz=n_elements(b)
print,sz
print,i+dir
print, (i ge 0)
print,((i+dir) le (sz-1))
print, ((i+dir) ge 0)
if i ge 0 and ((i+dir) le (sz-1)) and ((i+dir) ge 0) then i=i+dir else return, "false"
;print,"h"
return, a+b(i)
end