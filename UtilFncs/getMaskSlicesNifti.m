function [mask_slices_n, mask_height, mask_width, mask_slices] = getMaskSlicesNifti(mask_file)
    mask = [];
    try
        mask = load_nii(mask_file);
        mask_slices_n = mask.hdr.dime.dim(4);
        mask_height = mask.hdr.dime.dim(3);
        mask_width = mask.hdr.dime.dim(2);
        mask_slices_t = reshape(mask.img, [], mask_slices_n);
    catch
        fprintf('File reading failed for : %s \nSleeping 5s before retrying...', mask_file);
        try
            clear mask;
        end
        pause(5);
        mask = load_nii(mask_file);
        mask_slices_n = mask.hdr.dime.dim(4);
        mask_height = mask.hdr.dime.dim(3);
        mask_width = mask.hdr.dime.dim(2);
        mask_slices_t = reshape(mask.img, [], mask_slices_n);
        fprintf('Done...\n');
    end
    mask_slices = mask_slices_t > 0;
    clear mask;
end
