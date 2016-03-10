function [mask_slices_n, mask_height, mask_width, mask_slices, voxel_dims] = getMaskSlicesMinc(mask_file)
    mask = [];
    try
        mask = openimage(mask_file);
        mask_slices_n = getimageinfo(mask, 'NumSlices');
        mask_height = getimageinfo(mask, 'ImageHeight');
        mask_width = getimageinfo(mask, 'ImageWidth');
        mask_slices_t = getimages(mask, 1:mask_slices_n);
        voxel_dims = getimageinfo(mask, 'Steps');
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
        voxel_dims = getimageinfo(mask, 'Steps');
        fprintf('Done...\n');
    end
    mask_slices = mask_slices_t > 0.9;
    closeimage(mask);
end
