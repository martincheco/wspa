pro bug_ncdf
fid=ncdf_open('Au010-M-Xp-Topo.nc')
varid=ncdf_varid(fid,'reftime')
ncdf_varget,fid,varid,var
help,var
print,string(var)
ncdf_close,fid
end
