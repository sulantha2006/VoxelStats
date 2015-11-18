function [ c_struct ] = VoxelStatsROC( inputTable, dataColumn, groupColumnName, mask_file )
functionTimer = tic;
mainDataTable = readtable(inputTable);
    %%Get Mask data
    [slices, image_height, image_width, mask_slices] = getMaskSlices(mask_file);
    image_elements = image_height * image_width;
    
    eval(['multiVarData = readmultiValuedMincData(mainDataTable.' dataColumn ',' num2str(slices) ', mask_slices);']);
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

function [ roc ] = parForROC(groupingData, sliceData)
    [fpr,tpr,th,auc] = perfcurve(groupingData, sliceData, 1);
    
    dist = sqrt(fpr.^2 + (1 - tpr).^2);
    [best, best_one_index] = min(dist);
    roc = struct('th',th(best_one_index), 'tpr',tpr(best_one_index), 'fpr', fpr(best_one_index));
        
end

function [sliceData, numberOfModels, isEnd] = getMultiVarForSlice(multiVarData, index, numOfModels, blockSize)
    isEnd = 0;
        if (((index-1)*blockSize)+1) > numOfModels
            numberOfModels = 0;
            isEnd = 1;
        elseif (index*blockSize > numOfModels) && ((((index-1)*blockSize)+1) < numOfModels)
            sliceData = multiVarData(:,(((index-1)*blockSize)+1):end);
            numberOfModels = numOfModels - (((index-1)*blockSize)+1);
        else
            sliceData = multiVarData(:,(((index-1)*blockSize)+1):(index*blockSize));
            numberOfModels = blockSize;
        end
end

function [mat] = getVoxelStructFromMask(vector, mask_slices, image_elements, numberOfslices)
    mat = zeros(image_elements, numberOfslices);
    mat(mask_slices) = vector;
end