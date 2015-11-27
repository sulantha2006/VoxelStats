function [mask_slices_n, mask_height, mask_width, mask_slices] = readMaskSlices( imageType, maskFile )

    switch imageType
        case {'mnc','MNC', 'minc', 'MINC'}
            [mask_slices_n, mask_height, mask_width, mask_slices] = getMaskSlicesMinc(maskFile);
        case {'nii','NII', 'nifti', 'NIFTI'}
            [mask_slices_n, mask_height, mask_width, mask_slices] = getMaskSlicesNifti(maskFile);
        otherwise
            fprintf('Unknown Image type')
            exit
    end

end

