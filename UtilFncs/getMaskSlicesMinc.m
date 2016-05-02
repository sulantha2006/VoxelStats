function [mask_slices_n, mask_height, mask_width, mask_slices, voxel_dims, slices_data] = getMaskSlicesMinc(mask_file)
    mask = [];
    for retry=1:5
        try
            mask = openimage(mask_file);
            mask_slices_n = getimageinfo(mask, 'NumSlices');
            mask_height = getimageinfo(mask, 'ImageHeight');
            mask_width = getimageinfo(mask, 'ImageWidth');
            mask_slices_t = getimages(mask, 1:mask_slices_n);
            voxel_dims = getimageinfo(mask, 'Steps');
            break;
        catch
            fprintf('File reading failed for : %s \nSleeping 5s before retrying...', mask_file);
            try
                closeimage(mask);
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
    mask_slices = mask_slices_t > 0.9;
    slices_data = mask_slices_t;
    closeimage(mask);
end
