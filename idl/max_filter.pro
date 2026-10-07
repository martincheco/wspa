function max_filter, img, factor=factorl; bytescales after truncates the image at its factor*mean value
if not(keyword_set(factor)) then factor=4
return,bytscl(mean(img)*factor < img)
end

