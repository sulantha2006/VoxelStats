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

