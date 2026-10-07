pro bug_space
f='/home/martin/dwnld-chrom/bla\\\/m1_ori.par'
;f='/tmp/bla bla/m1_ori.tf0'
;f='/home/martin/dwnld-chrome/bla bla/sfasdf/m1_ori.tf0'
print,f
a=bug_space(f)
end

function bug_space,f
openr,1,f
close,1
return,1
end