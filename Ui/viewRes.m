function viewRes( hObject,eventdata, type )
    handles = guidata(hObject);
    set(handles.lblStatus, 'String', 'VoxelStats v1.1 - Busy.');
    maskFile = get(handles.txtMaskFile, 'String');
    imageType_s = get(handles.chooseImageType, 'String');
    imageType = imageType_s{get(handles.chooseImageType, 'Value')};
    [~, ~, ~, ~, image_steps] = readMaskSlices(imageType, maskFile);
    voxel_dims = [image_steps(3), image_steps(2), image_steps(1)];
    
    image_dimsizes = getimageinfo(openimage(maskFile), 'DimSizes');
    image_dims = [image_dimsizes(2), image_dimsizes(3), image_dimsizes(4)];
    
    switch type
        case 'lm'
            est_s = get(handles.chooseEst_lm, 'String');
            est = est_s{get(handles.chooseEst_lm, 'Value')};
            var_s = get(handles.chooseVarName_lm, 'String');
            var = var_s{get(handles.chooseVarName_lm, 'Value')};
            data = eval(['handles.c_data.' est '.' var]);
        case 'glm'
            est_s = get(handles.chooseEst_glm, 'String');
            est = est_s{get(handles.chooseEst_glm, 'Value')};
            var_s = get(handles.chooseVarName_glm, 'String');
            var = var_s{get(handles.chooseVarName_glm, 'Value')};
            data = eval(['handles.c_data.' est '.' var]);
        case 'roc'
            est_s = get(handles.chooseEst_roc, 'String');
            est = est_s{get(handles.chooseEst_roc, 'Value')};
            data = eval(['handles.c_data.' est]);
    end
    VoxelStatsShow(data, image_dims, voxel_dims);
    set(handles.lblStatus, 'String', 'VoxelStats v1.1 - Idle.');
end

