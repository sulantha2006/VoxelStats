function [ c_struct, slices_p, image_height_p, image_width_p, coeff_vars] = VoxelStatsLM( stringModel, data_file, mask_file, multivalueVariables, categoricalVars, includeString )
functionTimer = tic;
mainDataTable = readtable(data_file);
    
    if length(includeString) > 0
        incStr = strrep(includeString, 'mdt.', 'mainDataTable.');
        eval(['mainDataTable_rows = ' incStr ';']);
        mainDataTable = mainDataTable(mainDataTable_rows, :);
    end
    
    multiVarMap = containers.Map();
    
    %% Parsing Model String
    usedVars = {};
    
    temp = strsplit(stringModel, '~');
    responseVar = temp(1);
    U = matlab.lang.makeUniqueStrings(responseVar{1});
    eval([U '= mainDataTable.' responseVar{1,1} ';']);
    usedVars = [usedVars responseVar{1,1}];
    
    temp1 = strsplit(temp{1,2}, '+');
    for t_var = temp1
        c = t_var{1};
        if isempty(strfind(t_var{1}, '*'))
            U = matlab.lang.makeUniqueStrings(t_var{1});
            eval([U '= mainDataTable.' t_var{1,1} ';']);
            usedVars = [usedVars t_var{1,1}];
        else
            temp2 = strsplit(t_var{1}, '*');
            for t_var2 = temp2
                U = matlab.lang.makeUniqueStrings(t_var2{1});
                eval([U '= mainDataTable.' t_var2{1,1} ';']);
                usedVars = [usedVars t_var2{1,1}];
            end
        end
    end
   
    


%%Get Mask data
[slices, image_height, image_width, mask_slices] = getMaskSlices(mask_file);

%%Get info from Voxel files.
image_elements = image_height * image_width;

fprintf('Reading Data: \n');
readDataTimer = tic;
multiVarMap = getMultiVarData(mainDataTable, multivalueVariables, slices, image_elements, mask_slices);
fprintf('File Read - ');
toc(readDataTimer)
dataTable = mainDataTable(:,usedVars);


%%Run Analysis
% Run only one voxel to get information
templm = parForVoxelLM(dataTable, stringModel, 1, categoricalVars, multivalueVariables, multiVarMap);
varsInRegressionNames = templm.CoefficientNames;
nVarsInRegression = length(varsInRegressionNames);
%%Done one voxel fitlm

%Number of Analysis
numOfModels = sum(sum(mask_slices));
totalDataSlices = 200;
tStruct = zeros(numOfModels,nVarsInRegression);
eStruct = zeros(numOfModels,nVarsInRegression);
fprintf('Analysis Starting: \n');
analysisTimer = tic;
%Slicing data
for sliceCount = 1:totalDataSlices
    fprintf('Artificial Slice - %d - ', sliceCount);
    artificialSliceTimer = tic;
    blockSize = ceil(numOfModels/totalDataSlices);
    [multiVarMapForSlice, numberOfModels_t, isEnd] = getMultiVarMapForSlice(multiVarMap, multivalueVariables, sliceCount, numOfModels, blockSize);
    if isEnd
        toc(artificialSliceTimer)
        break;
    end
    slices_t = zeros(numberOfModels_t, nVarsInRegression);
    slices_e = zeros(numberOfModels_t, nVarsInRegression);
    parfor k = 1:numberOfModels_t
        lm = parForVoxelLM(dataTable, stringModel, k, categoricalVars, multivalueVariables, multiVarMapForSlice);
        slices_t(k, :) = lm.Coefficients.tStat';
        slices_e(k, :) = lm.Coefficients.Estimate';
    end
    tStruct((((sliceCount-1)*blockSize)+1):(((sliceCount-1)*blockSize)+numberOfModels_t),:) = slices_t;
    eStruct((((sliceCount-1)*blockSize)+1):(((sliceCount-1)*blockSize)+numberOfModels_t),:) = slices_e;
    toc(artificialSliceTimer)
end
fprintf('Analysis Done - ');
toc(analysisTimer)
slices_p = slices;
image_height_p = image_height;
image_width_p = image_width;
finalTStruct=[];
finalEStruct=[];
for x = 1:length(varsInRegressionNames)
    finalTStruct.(regexprep(varsInRegressionNames{x}, '\W', '')) = getVoxelStructFromMask(tStruct(:,x), mask_slices, image_elements, slices);
    finalEStruct.(regexprep(varsInRegressionNames{x}, '\W', '')) = getVoxelStructFromMask(eStruct(:,x), mask_slices, image_elements, slices);
end
c_struct = struct('tValues', finalTStruct, 'eValues', finalEStruct);
coeff_vars = varsInRegressionNames;
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

function [multiVarMap] = getMultiVarData(mainDataTable, multivalueVariables, totalSlices, image_elements, mask_slices)
    multiVarMap = containers.Map();
    for var = multivalueVariables
        U = matlab.lang.makeUniqueStrings(var{1});
        eval([U '= readmultiValuedMincData(mainDataTable.' var{1,1} ',' num2str(totalSlices) ',mask_slices);']);
        str = strcat('multiVarMap(''', var{1,1}, ''') = ', U, ';' );
        eval([str]);
    end
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

function [ model ] = parForVoxelLM(table, formula, k, categoricalVars, multivalueVariables, multiVarMap)
    for varName = multivalueVariables
        varData = multiVarMap(varName{1,1});
        str_cnt = strcat('table.',varName{1,1},' = varData(:,',num2str(k),');');
        eval([str_cnt]);   
    end  
    if length(categoricalVars{1}) > 0         
        model = fitlm(table, formula, 'CategoricalVars', categoricalVars);
    else
        model = fitlm(table, formula);
    end
        
end

function [mapForSlice, numberOfModels, isEnd] = getMultiVarMapForSlice(multiVarMap, multivalueVariables, index, numOfModels, blockSize)
    mapForSlice = containers.Map();
    isEnd = 0;
    for var = multivalueVariables
        varData = multiVarMap(var{1,1});
        if (((index-1)*blockSize)+1) > numOfModels
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

function [mat] = getVoxelStructFromMask(vector, mask_slices, image_elements, numberOfslices)
    mat = zeros(image_elements, numberOfslices);
    mat(mask_slices) = vector;
end
