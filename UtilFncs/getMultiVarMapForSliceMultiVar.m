function [mapForSlice, numberOfModels, isEnd] = getMultiVarMapForSliceMultiVar(multiVarMap, multivalueVariables, index, numOfModels, blockSize)
    mapForSlice = containers.Map();
    isEnd = 0;
    for var = multivalueVariables
        varData = multiVarMap(var{1,1});
        if (((index-1)*blockSize)+1) > numOfModels
            numberOfModels = 0;
            isEnd = 1;
        elseif (index*blockSize > numOfModels) && ((((index-1)*blockSize)+1) < numOfModels)
            mapForSlice(var{1,1}) = varData(:,(((index-1)*blockSize)+1):end);
            numberOfModels = numOfModels - (((index-1)*blockSize)+1);
        else
            mapForSlice(var{1,1}) = varData(:,(((index-1)*blockSize)+1):(index*blockSize));
            numberOfModels = blockSize;
        end
    end
end

