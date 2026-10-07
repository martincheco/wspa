pro bug_write_png
d=bytscl(dist(100,100))
a=d/150B*255B

img=[[[d]],[[d]],[[d]],[[a]]]
help,img
write_png,'tst.png',transpose(img,[2,0,1])

end