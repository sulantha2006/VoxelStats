function runRFT( hObject,eventdata, type )
    handles = guidata(hObject);
    set(handles.lblStatus, 'String', 'VoxelStats v1.1 - Busy...');
    image_dims = handles.image_dims;
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
        case 't'
            serach_vol = get(handles.txtRftSearchVol_t, 'String');
            voxel_num = get(handles.txtRftVoxelNum_t, 'String');
            fwhm = get(handles.txtRftFWHM_t, 'String');
            df = get(handles.txtRftDF_t, 'String');
            clus_th = get(handles.txtRftClusterTh_t, 'String');
        case 'pt'
            serach_vol = get(handles.txtRftSearchVol_pt, 'String');
            voxel_num = get(handles.txtRftVoxelNum_pt, 'String');
            fwhm = get(handles.txtRftFWHM_pt, 'String');
            df = get(handles.txtRftDF_pt, 'String');
            clus_th = get(handles.txtRftClusterTh_pt, 'String');
    end
    
    tValues_RFT=[];
    old_cData = handles.c_data;
    oldTValues = old_cData.tValues;
    fieldn = fieldnames(oldTValues);
    for f =1:length(fieldn)
        field = fieldn{f};
        stat_mat = eval(['oldTValues.' field]);
        correctd_mat = VoxelStatsDoRFT(stat_mat, image_dims, str2num(serach_vol), ...
            str2num(voxel_num), str2num(fwhm), str2num(df), 0.05, str2num(clus_th));
        eval(['tValues_RFT.' field ' = correctd_mat;']);
    end
    
    old_cData.tValues_RFT = tValues_RFT;
    handles.c_data = old_cData;
    switch type
        case 'lm'
            set(handles.chooseEst_lm, 'String', fieldnames(old_cData));
        case 'glm'
            set(handles.chooseEst_glm, 'String', fieldnames(old_cData));
        case 't'
            set(handles.chooseEst_t, 'String', fieldnames(old_cData));
        case 'pt'
            set(handles.chooseEst_pt, 'String', fieldnames(old_cData));
    end
    set(handles.lblStatus, 'String', 'VoxelStats v1.1 - Idle.');
    guidata(hObject, handles);

end

