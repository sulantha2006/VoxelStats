function viewRes( hObject,eventdata, type )
    handles = guidata(hObject);
    set(handles.lblStatus, 'String', 'VoxelStats v1.1 - Busy.');
    maskFile = get(handles.txtMaskFile, 'String');
    imageType_s = get(handles.chooseImageType, 'String');
    imageType = imageType_s{get(handles.chooseImageType, 'Value')};
    [image_slices, image_height, image_width, ~, image_steps, slices_data] = readMaskSlices(imageType, maskFile);
    voxel_dims = [image_steps(3), image_steps(2), image_steps(1)];

    image_dims = [image_slices, image_height, image_width];
    
    switch type
        case 'lm'
            est_s = get(handles.chooseEst_lm, 'String');
            est = est_s{get(handles.chooseEst_lm, 'Value')};
            var_s = get(handles.chooseVarName_lm, 'String');
            var = var_s{get(handles.chooseVarName_lm, 'Value')};
            data = eval(['handles.c_data.' est '.' var]);
            template = get(handles.txtTemplate_lm, 'String');
        case 'glm'
            est_s = get(handles.chooseEst_glm, 'String');
            est = est_s{get(handles.chooseEst_glm, 'Value')};
            var_s = get(handles.chooseVarName_glm, 'String');
            var = var_s{get(handles.chooseVarName_glm, 'Value')};
            data = eval(['handles.c_data.' est '.' var]);
            template = get(handles.txtTemplate_glm, 'String');
        case 'roc'
            est_s = get(handles.chooseEst_roc, 'String');
            est = est_s{get(handles.chooseEst_roc, 'Value')};
            data = eval(['handles.c_data.' est]);
            template = get(handles.txtTemplate_roc, 'String');
    end
    if strcmp(template, '')
        VoxelStatsShow(data, image_dims, voxel_dims);
    else
        VoxelStatsShowOnTemplate(data, template, imageType);
    end
    set(handles.lblStatus, 'String', 'VoxelStats v1.1 - Idle.');
end

