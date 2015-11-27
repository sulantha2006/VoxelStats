function [multiVarMap] = getMultiVarData(imageType, mainDataTable, multivalueVariables, totalSlices, image_elements, mask_slices)
    multiVarMap = containers.Map();
    for var = multivalueVariables
        U = matlab.lang.makeUniqueStrings(var{1});
        switch imageType
            case {'mnc','MNC', 'minc', 'MINC'}
                eval([U '= readmultiValuedMincData(mainDataTable.' var{1,1} ',' num2str(totalSlices) ',mask_slices);']);
            case {'nii','NII', 'nifti', 'NIFTI'}
                eval([U '= readmultiValuedNiftiData(mainDataTable.' var{1,1} ',' num2str(totalSlices) ',mask_slices);']);
            otherwise
                fprintf('Unknown Image type')
                exit
        end
        str = strcat('multiVarMap(''', var{1,1}, ''') = ', U, ';' );
        eval([str]);
    end
end

