function [ result_h, result_p, result_t ] = VoxelStatsT( inputTable, dataColumn, groupColumnName, group1, group2, includeString, mask_file )
mainDataTable = readtable(inputTable);
    
    if length(includeString) > 0
        incStr = strrep(includeString, 'mdt.', 'mainDataTable.');
        eval(['mainDataTable_rows = ' incStr ';']);
        mainDataTable = mainDataTable(mainDataTable_rows, :);
    end
    
    %%Get Mask data
[slices, image_height, image_width, mask_slices] = getMaskSlices(mask_file);
image_elements = image_height * image_width;
    
    if isstr(group1)
        eval(['group1_rows = strcmp(mainDataTable. ' groupColumnName ', ''' group1 ''');']);
    else
        eval(['group1_rows = mainDataTable. ' groupColumnName ' == ' num2str(group1) ';']);
    end
    eval(['group1data = readmultiValuedMincData(mainDataTable(group1_rows, :).' dataColumn ',' num2str(slices) ', mask_slices);']);
    
    if isstr(group2)
        eval(['group2_rows = strcmp(mainDataTable. ' groupColumnName ', ''' group2 ''');']);
    else
        eval(['group2_rows = mainDataTable. ' groupColumnName '== ' num2str(group2) ';']);
    end
    eval(['group2data = readmultiValuedMincData(mainDataTable(group2_rows, :).' dataColumn ',' num2str(slices) ', mask_slices);']);
    
    [h, p, ci, t] = ttest2(group1data, group2data);
    
    result_h = zeros(image_elements, slices);
    result_h(mask_slices) = h;
    
    result_p = zeros(image_elements, slices);
    result_p(mask_slices) = p;
    
    result_t = zeros(image_elements, slices);
    result_t(mask_slices) = t.tstat;

end

function [mask_slices_n, mask_height, mask_width, mask_slices] = getMaskSlices(mask_file)
    mask = [];
    try
        mask = openimage(mask_file);
        mask_slices_n = getimageinfo(mask, 'NumSlices');
        mask_height = getimageinfo(mask, 'ImageHeight');
        mask_width = getimageinfo(mask, 'ImageWidth');
        mask_slices_t = getimages(mask, 1:mask_slices_n);
    catch
        fprintf('File reading failed for : %s \nSleeping 5s before retrying...', mask_file);
        try
            closeimage(mask);
        end
        pause(5);
        mask = openimage(mask_file);
        mask_slices_n = getimageinfo(mask, 'NumSlices');
        mask_height = getimageinfo(mask, 'ImageHeight');
        mask_width = getimageinfo(mask, 'ImageWidth');
        mask_slices_t = getimages(mask, 1:mask_slices_n);
        fprintf('Done...\n');
    end
    mask_slices = mask_slices_t > 0.9;
    closeimage(mask);
end

function [resultMat] = readmultiValuedMincData( subjectList, totalSlices, mask_slices)
    [n m] = size(subjectList);
    resultMat = zeros(n, sum(sum(mask_slices)));
    for i = 1:n
        h = [];
        for retry=1:5
            try
                h = openimage(subjectList{i,1});
                t = getimages(h, 1: totalSlices);
                resultMat(i,:) = t(mask_slices)';
                break;
            catch
                fprintf('File reading failed for : %s \nSleeping 5s before retrying...\n', subjectList{i,1});
                try
                    closeimage(h);
                end
                pause(5);
                if retry < 5
                    continue;
                else
                    fprintf('File reading failed and connot recover. ')
                    exit
                end
            end
        end
    end

end