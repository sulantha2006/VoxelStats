function [mask_slices_n, mask_height, mask_width, mask_slices, voxel_dims, slices_data] = readMaskSlices( imageType, maskFile )

    switch imageType
        case {'mnc','MNC', 'minc', 'MINC'}
            [mask_slices_n, mask_height, mask_width, mask_slices, voxel_dims, slices_data] = getMaskSlicesMinc(maskFile);
        case {'nii','NII', 'nifti', 'NIFTI'}
            [mask_slices_n, mask_height, mask_width, mask_slices, voxel_dims, slices_data] = getMaskSlicesNifti(maskFile);
        otherwise
            fprintf('Unknown Image type')
            exit
    end

end

