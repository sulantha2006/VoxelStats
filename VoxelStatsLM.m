function [ c_struct, slices_p, image_height_p, image_width_p, coeff_vars] = VoxelStatsLM( imageType, stringModel, data_file, mask_file, multivalueVariables, categoricalVars, includeString, multiVarOperationMap )
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
    usedVarsStr = {};
    while true
        [str, s] = strtok(s, '+|-*()~ ');
        if isempty(str),  break;  end
        if all(ismember(str, '0123456789+-.eEdD')), continue; end
        if ismember(str, usedVarsStr), continue; end

        usedVarsStr = [usedVarsStr str];
        U = matlab.lang.makeUniqueStrings(str);
        eval([U '= mainDataTable.' str ';']);
        usedVars = [usedVars str];
    end

    %%Get Mask data
    
    [slices, image_height, image_width, mask_slices] = readMaskSlices(imageType, mask_file);

    %%Get info from Voxel files.
    image_elements = image_height * image_width;

    fprintf('Reading Data: \n');
    readDataTimer = tic;
    multiVarMap = getMultiVarData(imageType, mainDataTable, multivalueVariables, slices, image_elements, mask_slices);
    fprintf('File Read - ');
    toc(readDataTimer)
    dataTable = mainDataTable(:,usedVars);
    fprintf('Total files read - %d - ', height(dataTable));
    %%Do multi value operations if specified
    if nargin > 6 
        operationKeys = multiVarOperationMap.keys;
        for k_idx = 1:length(operationKeys)
            operation = eval([' multiVarOperationMap(''', operationKeys{k_idx}, ''');']);
            str = strcat('multiVarMap(''', operationKeys{k_idx}, ''') = multiVarMap(''', operationKeys{k_idx}, ''')' , operation, ';');
            eval([str]);
        end
    end


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
        [multiVarMapForSlice, numberOfModels_t, isEnd] = getMultiVarMapForSliceMultiVar(multiVarMap, multivalueVariables, sliceCount, numOfModels, blockSize);
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


