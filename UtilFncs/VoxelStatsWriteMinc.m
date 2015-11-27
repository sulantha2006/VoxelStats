function VoxelStatsWriteMinc( data, filename, ref_file, noOfSlices, dataType )
switch nargin
    case 4
        dataType = 'short';
end
h = newimage(filename, [0 noOfSlices], ref_file, dataType);
putimages(h, data, 1:noOfSlices);
closeimage(h);

end

