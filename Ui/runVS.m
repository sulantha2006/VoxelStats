function runVS(hObject,eventdata, type)
    handles = guidata(hObject);
    set(handles.lblStatus, 'String', 'VoxelStats v1.1 - Busy...');
    
    csvFile = get(handles.txtDataFile, 'String');
    filterStr  = get(handles.txtFilter, 'String');
    maskFile = get(handles.txtMaskFile, 'String');
    imageType_s = get(handles.chooseImageType, 'String');
    imageType = imageType_s{get(handles.chooseImageType, 'Value')};
    
    switch type
        case 'lm'
            model_str = get(handles.txtModel_lm, 'String');
            multi_vars = strsplit(strrep(get(handles.txtMultVar_lm, 'String'), ' ', ''), {','});
            cat_vars = strsplit(strrep(get(handles.txtCatVar_lm, 'String'), ' ', ''), {','});
            mixed = get(handles.chooseMixed_lm, 'Value');
            if mixed
                [ c_struct, slices_p, image_height_p, image_width_p, coeff_vars]  = ... 
                    VoxelStatsLME(imageType, model_str, csvFile, maskFile, multi_vars, cat_vars, filterStr);
            else
                [ c_struct, slices_p, image_height_p, image_width_p, coeff_vars]  = ... 
                    VoxelStatsLM(imageType, model_str, csvFile, maskFile, multi_vars, cat_vars, filterStr);
            end
            set(handles.chooseEst_lm, 'String', fieldnames(c_struct));
            str_selection_s = get(handles.chooseEst_lm, 'String');
            str_selection = str_selection_s{get(handles.chooseEst_lm, 'Value')};
            intVars = eval(['handles.c_data.' str_selection]);
            newfields = fieldnames(intVars);
            set(handles.chooseVarName_lm, 'String', newfields);
        case 'glm'
            model_str = get(handles.txtModel_glm, 'String');
            multi_vars = strsplit(strrep(get(handles.txtMultVar_glm, 'String'), ' ', ''), {','});
            cat_vars = strsplit(strrep(get(handles.txtCatVar_glm, 'String'), ' ', ''), {','});
            mixed = get(handles.chooseMixed_glm, 'Value');
            distrib_s = get(handles.chooseDist_glm, 'String');
            distrib = distrib_s(get(handles.chooseDist_glm, 'Value'));
            if mixed
                [ c_struct, slices_p, image_height_p, image_width_p, coeff_vars]  = ... 
                    VoxelStatsGLME(imageType, model_str, distrib, csvFile, maskFile, multi_vars, cat_vars, filterStr);
            else
                [ c_struct, slices_p, image_height_p, image_width_p, coeff_vars]  = ... 
                    VoxelStatsGLM(imageType, model_str, distrib, csvFile, maskFile, multi_vars, cat_vars, filterStr);
            end
            set(handles.chooseEst_glm, 'String', fieldnames(c_struct));
            str_selection_s = get(handles.chooseEst_glm, 'String');
            str_selection = str_selection_s{get(handles.chooseEst_glm, 'Value')};
            intVars = eval(['handles.c_data.' str_selection]);
            newfields = fieldnames(intVars);
            set(handles.chooseVarName_glm, 'String', newfields);
        case 'roc'
            dataCol = get(handles.txtDataCol_roc, 'String');
            groupingCol = get(handles.txtGroupCol_roc, 'String');
            c_struct = VoxelStatsROC(imageType, csvFile, dataCol, groupingCol, maskFile, filterStr);
            set(handles.chooseEst_roc, 'String', fieldnames(c_struct));
    end
    handles.c_data = c_struct;
    handles.image_dims = [slices_p, image_height_p image_width_p];
    guidata(hObject, handles);
    set(handles.lblStatus, 'String', 'VoxelStats v1.1 - Idle.');
end

