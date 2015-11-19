function [multiVarMap] = getMultiVarData(mainDataTable, multivalueVariables, totalSlices, image_elements, mask_slices)
    multiVarMap = containers.Map();
    for var = multivalueVariables
        U = matlab.lang.makeUniqueStrings(var{1});
        eval([U '= readmultiValuedMincData(mainDataTable.' var{1,1} ',' num2str(totalSlices) ',mask_slices);']);
        str = strcat('multiVarMap(''', var{1,1}, ''') = ', U, ';' );
        eval([str]);
    end
end

