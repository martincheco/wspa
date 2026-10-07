function test_user_file_func
    common wspa_serverpath, serverpath
    common wspa_localdir_cache, ldir_paths, ldir_vals, sdir_paths
    serverpath = '/var/www/wspa'
    cmdargs = ['/var/www/wspa/users/admin', '/var/www/wspa']

    file_path = 'data/mydata/helicenes/Ag111_helicene_acetylsulfanyl/2015-12-28/Ag(111)_094.sxm'
    pmdata = mloadwsxm(file_path)
    n = n_elements(pmdata)
    print, 'Loaded ', n, ' channel(s)'

    for i=0, n-1 do begin
        par_arr = (*pmdata(i)).par
        fn = getval(par_arr, "Filename:")
        acqchan = getval(par_arr, "Acquisition channel:")
        fn_meta = get_meta_path_gdl(fn, cmdargs(0))
        has_flt = file_test(fn_meta)
        print, 'Channel ', i, ': acqchan=', acqchan
        print, '  -> fn=', fn
        print, '  -> meta_flt=', fn_meta
        print, '  -> has_flt=', has_flt
        
        if has_flt then begin
            ffff = filter_load(fn_meta)
            ftype = ffff.type
            print, '  -> loaded filter structure type: ', ftype
        endif
    endfor
    return, 1
end
