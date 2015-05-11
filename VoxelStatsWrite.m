function VoxelStatsWrite( data, filename, ref_file, noOfSlices )

h = newimage(filename, [0 noOfSlices], ref_file);
putimages(h, data, 1:noOfSlices);
closeimage(h);

end

