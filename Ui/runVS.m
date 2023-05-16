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
                [ c_struct, slices_p, image_height_p, image_width_p, coeff_vars, voxel_num, df, voxel_dims]  = ... 
                    VoxelStatsLME(imageType, model_str, csvFile, maskFile, multi_vars, cat_vars, filterStr);
            else
                [ c_struct, slices_p, image_height_p, image_width_p, coeff_vars, voxel_num, df, voxel_dims]  = ... 
                    VoxelStatsLM(imageType, model_str, csvFile, maskFile, multi_vars, cat_vars, filterStr);
            end
            set(handles.chooseEst_lm,'Value',1); 
            set(handles.chooseEst_lm, 'String', fieldnames(c_struct));
            handles.image_dims = [slices_p, image_height_p image_width_p];
            handles.voxel_num = voxel_num;
            handles.df = df;
            handles.voxel_dims = voxel_dims;
        case 'glm'
            model_str = get(handles.txtModel_glm, 'String');
            multi_vars = strsplit(strrep(get(handles.txtMultVar_glm, 'String'), ' ', ''), {','});
            cat_vars = strsplit(strrep(get(handles.txtCatVar_glm, 'String'), ' ', ''), {','});
            mixed = get(handles.chooseMixed_glm, 'Value');
            distrib_s = get(handles.chooseDist_glm, 'String');
            distrib = distrib_s(get(handles.chooseDist_glm, 'Value'));
            if mixed
                [ c_struct, slices_p, image_height_p, image_width_p, coeff_vars, voxel_num, df, voxel_dims]  = ... 
                    VoxelStatsGLME(imageType, model_str, distrib, csvFile, maskFile, multi_vars, cat_vars, filterStr);
            else
                [ c_struct, slices_p, image_height_p, image_width_p, coeff_vars, voxel_num, df, voxel_dims]  = ... 
                    VoxelStatsGLM(imageType, model_str, distrib, csvFile, maskFile, multi_vars, cat_vars, filterStr);
            end
            set(handles.chooseEst_glm,'Value',1); 
            set(handles.chooseEst_glm, 'String', fieldnames(c_struct));
            handles.image_dims = [slices_p, image_height_p image_width_p];
            handles.voxel_num = voxel_num;
            handles.df = df;
            handles.voxel_dims = voxel_dims;
        case 'roc'
            dataCol = get(handles.txtDataCol_roc, 'String');
            groupingCol = get(handles.txtGroupCol_roc, 'String');
            c_struct = VoxelStatsROC(imageType, csvFile, dataCol, groupingCol, maskFile, filterStr);
            set(handles.chooseEst_roc,'Value',1); 
            set(handles.chooseEst_roc, 'String', fieldnames(c_struct));
        case 't'
            dataCol = get(handles.txtDataCol_t, 'String');
            groupingCol = get(handles.txtGroupCol_t, 'String');
            Group1 = get(handles.txtGroup1_t, 'String');
            Group2 = get(handles.txtGroup2_t, 'String');
            welch = get(handles.chooseWelch_t, 'Value');

            c_struct = VoxelStatsT(imageType, csvFile, dataCol, groupingCol, Group1, Group2, filterStr, maskFile, welch);
            
            set(handles.chooseEst_t,'Value',1); 
            set(handles.chooseEst_t, 'String', fieldnames(c_struct));
        case 'pt'
            ContrastCol1 = get(handles.txtContrastCol1_pt, 'String');
            ContrastCol2 = get(handles.txtContrastCol2_pt, 'String');
            c_struct = VoxelStatsPairedT(imageType, csvFile, ContrastCol1, ContrastCol2, filterStr, maskFile);
            set(handles.chooseEst_pt,'Value',1); 
            set(handles.chooseEst_pt, 'String', fieldnames(c_struct));
        case 'propt'
            dataCol = get(handles.txtDataCol_propt, 'String');
            groupingCol = get(handles.txtGroupCol_propt, 'String');
            c_struct = VoxelStatsProportionTest(imageType, csvFile, dataCol, groupingCol, maskFile, filterStr);
            set(handles.chooseEst_propt,'Value',1); 
            set(handles.chooseEst_propt, 'String', fieldnames(c_struct));
    end
    handles.c_data = c_struct;
    switch type
        case 'lm'
            str_selection_s = get(handles.chooseEst_lm, 'String');
            str_selection = str_selection_s{1};
            intVars = eval(['handles.c_data.' str_selection]);
            newfields = fieldnames(intVars);
            set(handles.chooseVarName_lm, 'String', newfields);
            
            voxel_volume = prod(voxel_dims);
            set(handles.txtRftVoxelNum_lm, 'String', handles.voxel_num);
            set(handles.txtRftSearchVol_lm, 'String', handles.voxel_num*voxel_volume);
            set(handles.txtRftDF_lm, 'String', handles.df);
            
        case 'glm'
            str_selection_s = get(handles.chooseEst_glm, 'String');
            str_selection = str_selection_s{1};
            intVars = eval(['handles.c_data.' str_selection]);
            newfields = fieldnames(intVars);
            set(handles.chooseVarName_glm, 'String', newfields);
            
            voxel_volume = prod(voxel_dims);
            set(handles.txtRftVoxelNum_glm, 'String', handles.voxel_num);
            set(handles.txtRftSearchVol_lm, 'String', handles.voxel_num*voxel_volume);
            set(handles.txtRftDF_glm, 'String', handles.df);
    end
            
    guidata(hObject, handles);
    set(handles.lblStatus, 'String', 'VoxelStats v1.1 - Idle.');
end

