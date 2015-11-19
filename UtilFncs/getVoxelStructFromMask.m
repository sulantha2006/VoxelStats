function [mat] = getVoxelStructFromMask(vector, mask_slices, image_elements, numberOfslices)
    mat = zeros(image_elements, numberOfslices);
    mat(mask_slices) = vector;
end

