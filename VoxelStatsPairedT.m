function [ result_h, result_p, result_t ] = VoxelStatsPairedT( inputTable, contrastColumnId1, contrastColumnId2, includeString, mask_file )
mainDataTable = readtable(inputTable);
    
    if length(includeString) > 0
        incStr = strrep(includeString, 'mdt.', 'mainDataTable.');
        eval(['mainDataTable_rows = ' incStr ';']);
        mainDataTable = mainDataTable(mainDataTable_rows, :);
    end
    
    %%Get Mask data
    [slices, image_height, image_width, mask_slices] = getMaskSlices(mask_file);
    image_elements = image_height * image_width;

    eval(['group1data = readmultiValuedMincData(mainDataTable.' contrastColumnId1 ',' num2str(slices) ', mask_slices);']);
    
    eval(['group2data = readmultiValuedMincData(mainDataTable.' contrastColumnId2 ',' num2str(slices) ', mask_slices);']);
    
    [h, p, ci, t] = ttest(group1data, group2data);
    
    result_h = zeros(image_elements, slices);
    result_h(mask_slices) = h;
    
    result_p = zeros(image_elements, slices);
    result_p(mask_slices) = p;
    
    result_t = zeros(image_elements, slices);
    result_t(mask_slices) = t;

end