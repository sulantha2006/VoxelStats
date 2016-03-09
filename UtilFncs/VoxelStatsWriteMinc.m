function VoxelStatsWriteMinc( data, filename, ref_file, dataType )
switch nargin
    case 3
        dataType = 'short';
end
[slices, image_height, image_width, mask_slices] = readMaskSlices('minc', ref_file);
h = newimage(filename, [0 slices], ref_file, dataType);
putimages(h, data, 1:slices);
closeimage(h);

end

