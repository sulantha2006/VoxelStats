function VoxelStatsWriteNifti( data, filename, ref_file )

    ref_input = load_nii(ref_file);
    ref_height = ref_input.hdr.dime.dim(3);
    ref_width = ref_input.hdr.dime.dim(2);
    ref_slices = ref_input.hdr.dime.dim(4);
    resh_data = reshape(data, ref_width, ref_height, ref_slices);
    ref_input.img = resh_data;
    save_nii(ref_input, filename);

end

