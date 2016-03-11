function [ result_h, result_p, result_t ] = VoxelStatsT( imageType, inputTable, dataColumn, groupColumnName, group1, group2, includeString, mask_file )
    mainDataTable = readtable(data_file, 'delimiter', ',', 'readVariableNames', true);
    
    if length(includeString) > 0
        incStr = strrep(includeString, 'mdt.', 'mainDataTable.');
        eval(['mainDataTable_rows = ' incStr ';']);
        mainDataTable = mainDataTable(mainDataTable_rows, :);
    end
    
    %%Get Mask data
    [slices, image_height, image_width, mask_slices, voxel_dims] = readMaskSlices(imageType, mask_file);
    image_elements = image_height * image_width;
    
    if isstr(group1)
        eval(['group1_rows = strcmp(mainDataTable. ' groupColumnName ', ''' group1 ''');']);
    else
        eval(['group1_rows = mainDataTable. ' groupColumnName ' == ' num2str(group1) ';']);
    end
    
    if isstr(group2)
        eval(['group2_rows = strcmp(mainDataTable. ' groupColumnName ', ''' group2 ''');']);
    else
        eval(['group2_rows = mainDataTable. ' groupColumnName '== ' num2str(group2) ';']);
    end
    switch imageType
        case {'mnc','MNC', 'minc', 'MINC'}
            eval(['group1data = readmultiValuedMincData(mainDataTable(group1_rows, :).' dataColumn ',' num2str(slices) ', mask_slices);']);
            eval(['group2data = readmultiValuedMincData(mainDataTable(group2_rows, :).' dataColumn ',' num2str(slices) ', mask_slices);']);
        case {'nii','NII', 'nifti', 'NIFTI'}
            eval(['group1data = readmultiValuedNiftiData(mainDataTable(group1_rows, :).' dataColumn ',' num2str(slices) ', mask_slices);']);
            eval(['group2data = readmultiValuedNiftiData(mainDataTable(group2_rows, :).' dataColumn ',' num2str(slices) ', mask_slices);']);
        otherwise
            fprintf('Unknown Image type')
            exit
    end
    
    [h, p, ci, t] = ttest2(group1data, group2data);
    
    result_h = zeros(image_elements, slices);
    result_h(mask_slices) = h;
    
    result_p = zeros(image_elements, slices);
    result_p(mask_slices) = p;
    
    result_t = zeros(image_elements, slices);
    result_t(mask_slices) = t.tstat;

end
