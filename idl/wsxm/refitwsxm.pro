
function refitwsxm,data,img
;replaces the image and returns a new structure, 
;useful in cases when the new image has different dimensions or type

newdata={par:data.par,img:img,$
xsize:data.xsize,ysize:data.ysize,zsize:data.zsize,$
conversion:data.conversion,datatype:data.datatype,$
zunit:data.zunit,runit:data.runit}
return,newdata
end
