function [ c_struct ] = VoxelStatsROC( imageType, inputTable, dataColumn, groupColumnName, mask_file, includeString )
    functionTimer = tic;
    mainDataTable = readtable(inputTable);

    if length(includeString) > 0
        incStr = strrep(includeString, 'mdt.', 'mainDataTable.');
        eval(['mainDataTable_rows = ' incStr ';']);
        mainDataTable = mainDataTable(mainDataTable_rows, :);
    end

    %%Get Mask data
    [slices, image_height, image_width, mask_slices] = readMaskSlices(imageType, mask_file);
    image_elements = image_height * image_width;
    switch imageType
        case {'mnc','MNC', 'minc', 'MINC'}
            eval(['multiVarData = readmultiValuedMincData(mainDataTable.' dataColumn ',' num2str(slices) ', mask_slices);']);
        case {'nii','NII', 'nifti', 'NIFTI'}
            eval(['multiVarData = readmultiValuedNiftiData(mainDataTable.' dataColumn ',' num2str(slices) ', mask_slices);']);
        otherwise
            fprintf('Unknown Image type')
            exit
    end
    groupingData = eval(['mainDataTable.' groupColumnName ';']);

    numOfModels = sum(sum(mask_slices));
    totalDataSlices = 200;
    thStruct = zeros(numOfModels,1);
    tprStruct = zeros(numOfModels,1);
    fprStruct = zeros(numOfModels,1);
    fprintf('Analysis Starting: \n');
    analysisTimer = tic;

    %Slicing data
    for sliceCount = 1:totalDataSlices
    fprintf('Artificial Slice - %d - ', sliceCount);
    artificialSliceTimer = tic;
    blockSize = ceil(numOfModels/totalDataSlices);
    [sliceData, numberOfModels_t, isEnd] = getMultiVarForSlice(multiVarData, sliceCount, numOfModels, blockSize);
    if isEnd
        toc(artificialSliceTimer)
        break;
    end
    slices_th = zeros(numberOfModels_t, 1);
    slices_tpr = zeros(numberOfModels_t, 1);
    slices_fpr = zeros(numberOfModels_t, 1);
    parfor k = 1:numberOfModels_t
        roc = parForROC(groupingData, sliceData(:,k));
        slices_th(k) = roc.th;
        slices_tpr(k) = roc.tpr;
        slices_fpr(k) = roc.fpr;
    end
    thStruct((((sliceCount-1)*blockSize)+1):(((sliceCount-1)*blockSize)+numberOfModels_t),:) = slices_th;
    tprStruct((((sliceCount-1)*blockSize)+1):(((sliceCount-1)*blockSize)+numberOfModels_t),:) = slices_tpr;
    fprStruct((((sliceCount-1)*blockSize)+1):(((sliceCount-1)*blockSize)+numberOfModels_t),:) = slices_fpr;
    toc(artificialSliceTimer)
    end
    fprintf('Analysis Done - ');
    toc(analysisTimer)

    finalTHStruct=getVoxelStructFromMask(thStruct, mask_slices, image_elements, slices);
    finalTPRStruct=getVoxelStructFromMask(tprStruct, mask_slices, image_elements, slices);
    finalFPRStruct=getVoxelStructFromMask(fprStruct, mask_slices, image_elements, slices);

    c_struct = struct('thValues', finalTHStruct, 'tprValues', finalTPRStruct, 'fprValues', finalFPRStruct);
    fprintf('Total - ');
    toc(functionTimer)
    

end

function [ roc ] = parForROC(groupingData, sliceData)
    [fpr,tpr,th,auc] = perfcurve(groupingData, sliceData, 1);
    
    dist = sqrt(fpr.^2 + (1 - tpr).^2);
    [best, best_one_index] = min(dist);
    roc = struct('th',th(best_one_index), 'tpr',tpr(best_one_index), 'fpr', fpr(best_one_index));
        
end
