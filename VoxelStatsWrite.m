function VoxelStatsWrite( data, filename, ref_file, noOfSlices, imageType )
switch nargin
    case 4
        imageType = 'short';
end
h = newimage(filename, [0 noOfSlices], ref_file, imageType);
putimages(h, data, 1:noOfSlices);
closeimage(h);

end

