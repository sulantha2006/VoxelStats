function runRFT( hObject,eventdata, type )

    handles = guidata(hObject);
    set(handles.lblStatus, 'String', 'VoxelStats v1.1 - Busy...');
    image_dims = get(handles.image_dims);
    switch type
        case 'lm'
            serach_vol = get(handles.txtRftSearchVol_lm, 'String');
            voxel_num = get(handles.txtRftVoxelNum_lm, 'String');
            fwhm = get(handles.txtRftFWHM_lm, 'String');
            df = get(handles.txtRftDF_lm, 'String');
            clus_th = get(handles.txtRftClusterTh_lm, 'String');
        case 'glm'
            serach_vol = get(handles.txtRftSearchVol_glm, 'String');
            voxel_num = get(handles.txtRftVoxelNum_glm, 'String');
            fwhm = get(handles.txtRftFWHM_glm, 'String');
            df = get(handles.txtRftDF_glm, 'String');
            clus_th = get(handles.txtRftClusterTh_glm, 'String');
    end
    
    tValues_RFT=[];
    old_cData = handles.c_data;
    oldTValues = old_cData.tValues;
    fieldn = fieldnames(oldTValues);
    for f =1:length(fieldn)
        field = fieldn(f);
        stat_mat = eval(['oldTValues.' field]);
        correctd_mat = VoxelStatsDoRFT(stat_mat, image_dims, serach_vol, ...
            voxel_num, fwhm, df, 0.05, clus_th);
        eval(['tValues_RFT.' field ' = correctd_mat']);
    end
    
    old_cData.tValues_RFT = tValues_RFT;
    handles.c_data = old_cData;
    set(handles.chooseEst_lm, 'String', fieldnames(old_cData));
    guidata(hObject, handles);
    set(handles.lblStatus, 'String', 'VoxelStats v1.1 - Idle.');

end

