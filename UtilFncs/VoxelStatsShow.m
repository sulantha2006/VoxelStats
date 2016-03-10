function VoxelStatsShow( stat_mat, image_dims, voxel_dims)

    figure_layout_width_slices = 4;
    figure_layout_height_slices = 3;

    image_slices_n = image_dims(1);
    image_height_n = image_dims(2);
    image_width_n = image_dims(3);
    
    slice_length = voxel_dims(1);
    voxel_height = voxel_dims(2);
    voxel_width = voxel_dims(3);
    
    image_height_n_rs = ceil(image_height_n*voxel_height);
    image_width_n_rs = ceil(image_width_n*voxel_width);

    slice_start = round(image_slices_n/10);
    slices_showing_n = image_slices_n*0.8;
    slice_spacing = floor(slices_showing_n/(figure_layout_width_slices*figure_layout_height_slices));
    image_mat = zeros(image_height_n_rs*figure_layout_height_slices, image_width_n_rs*figure_layout_width_slices);

    stats_mat_3d_t = reshape(stat_mat, image_width_n , image_height_n, image_slices_n);
    stats_mat_3d = permute(stats_mat_3d_t, [2,1,3]);

    slices_count = 0;
    for i = 1:figure_layout_height_slices
        for j = 1:figure_layout_width_slices
            image_mat(image_height_n_rs*(i-1)+1:image_height_n_rs*i,image_width_n_rs*(j-1)+1:image_width_n_rs*j) = imresize(stats_mat_3d(:,:,slice_start+slices_count*slice_spacing), [image_height_n_rs, image_width_n_rs]);
            slices_count = slices_count +1;
        end
    end
    
    figure('Name','Voxel Stats Show')
    imagesc(rot90(image_mat,2)); 
    colorbar; colormap(spectral(256));
    axis equal; axis off;  
    background='white';
    whitebg(gcf,background);
    set(gcf,'Color',background,'InvertHardcopy','off');
    ax = gcf;
    axpos = ax.Position;
    cpos = c.Position;
    cpos(3) = 0.5*cpos(3);
    c.Position = cpos;
    ax.Position = axpos;
end

