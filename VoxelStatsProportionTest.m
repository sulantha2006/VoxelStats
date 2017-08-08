function [ c_struct ] = VoxelStatsProportionTest( imageType, inputTable, dataColumn, groupColumnName, mask_file, includeString, multiVarOperation )
    functionTimer = tic;
    mainDataTable = readtable(inputTable, 'delimiter', ',', 'readVariableNames', true);
    
    if length(includeString) > 0
        incStr = strrep(includeString, 'mdt.', 'mainDataTable.');
        eval(['mainDataTable_rows = ' incStr ';']);
        mainDataTable = mainDataTable(mainDataTable_rows, :);
    end

    %%Get Mask data
    [slices, image_height, image_width, mask_slices, voxel_dims, slices_data] = readMaskSlices(imageType, mask_file);
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
    chi2Struct = zeros(numOfModels,1);
    chi2pStruct = zeros(numOfModels,1);
    fisherpStruct = zeros(numOfModels,1);
    
    %%Do multi value operations if specified
    if nargin > 6 
        operation = multiVarOperation;
        str = strcat('multiVarData = multiVarData', operation, ';');
        eval([str]);
    end
    
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
    slices_chi2 = zeros(numberOfModels_t, 1);
    slices_chi2p = zeros(numberOfModels_t, 1);
    slices_fisherp = zeros(numberOfModels_t, 1);
    
    parfor k = 1:numberOfModels_t
        propTest = parForPropTest(groupingData, sliceData(:,k));
        slices_chi2(k) = propTest.chi2;
        slices_chi2p(k) = propTest.chi2p;
        slices_fisherp(k) = propTest.fisherp;
    end
    chi2Struct((((sliceCount-1)*blockSize)+1):(((sliceCount-1)*blockSize)+numberOfModels_t),:) = slices_chi2;
    chi2pStruct((((sliceCount-1)*blockSize)+1):(((sliceCount-1)*blockSize)+numberOfModels_t),:) = slices_chi2p;
    fisherpStruct((((sliceCount-1)*blockSize)+1):(((sliceCount-1)*blockSize)+numberOfModels_t),:) = slices_fisherp;
    toc(artificialSliceTimer)
    end
    fprintf('Analysis Done - ');
    toc(analysisTimer)

    finalCHI2Struct=getVoxelStructFromMask(chi2Struct, mask_slices, image_elements, slices);
    finalCHI2PStruct=getVoxelStructFromMask(chi2pStruct, mask_slices, image_elements, slices);
    finalFIHSERPStruct=getVoxelStructFromMask(fisherpStruct, mask_slices, image_elements, slices);

    c_struct = struct('chi2Values', finalCHI2Struct, 'chi2pValues', finalCHI2PStruct, 'fisherpValues', finalFIHSERPStruct);
    fprintf('Total - ');
    toc(functionTimer)
    
end

function [ propTest ] = parForPropTest(groupingData, sliceData)
    [tbl,chi2,chi2p,labels] = crosstab(groupingData, round(sliceData, 0));
    if isnan(chi2)
        propTest = struct('chi2', 0, 'chi2p', 1, 'fisherp', 1);
    else
        [fishh,fisherp,stats] = fishertest(tbl);
        propTest = struct('chi2', chi2, 'chi2p', chi2p, 'fisherp', fisherp);
    end
    
    
    
    
        
end
