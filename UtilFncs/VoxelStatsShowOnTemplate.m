function VoxelStatsShowOnTemplate( stat_mat, template_file, imageType )
    [image_slices, image_height, image_width, ~, image_steps, template_data] = readMaskSlices(imageType, template_file);
    voxel_dims = [image_steps(3), image_steps(2), image_steps(1)];
    image_dims = [image_slices, image_height, image_width];
    
    image_slices_n = image_dims(1);
    image_height_n = image_dims(2);
    image_width_n = image_dims(3);
    
    slice_length = voxel_dims(1);
    voxel_height = voxel_dims(2);
    voxel_width = voxel_dims(3);
    
    image_slices_n_rs = ceil(image_slices_n*slice_length);
    image_height_n_rs = ceil(image_height_n*voxel_height);
    image_width_n_rs = ceil(image_width_n*voxel_width);
    
    stats_mat_3d_t = reshape(stat_mat, image_width_n , image_height_n, image_slices_n);
    stats_mat_3d = permute(stats_mat_3d_t, [2,1,3]);
    
    xSlice_avg = imresize(squeeze(nanmean(stats_mat_3d, 1)), [image_width_n_rs, image_slices_n_rs]);
    ySlice_avg = imresize(squeeze(nanmean(stats_mat_3d, 2)), [image_height_n_rs, image_slices_n_rs]);
    zSlice_avg = imresize(squeeze(nanmean(stats_mat_3d, 3)), [image_height_n_rs, image_width_n_rs]);
    
    template_mat_3d_t = reshape(template_data, image_width_n , image_height_n, image_slices_n);
    template_mat_3d = permute(template_mat_3d_t, [2,1,3]);
    
    xSlice_avg_template = imresize(squeeze(mean(template_mat_3d, 1)), [image_width_n_rs, image_slices_n_rs]);
    ySlice_avg_template = imresize(squeeze(mean(template_mat_3d, 2)), [image_height_n_rs, image_slices_n_rs]);
    zSlice_avg_template = imresize(squeeze(mean(template_mat_3d, 3)), [image_height_n_rs, image_width_n_rs]);
    
    xSlice_avg_pos = xSlice_avg.*(xSlice_avg>0);
    xSlice_avg_neg = xSlice_avg.*(xSlice_avg<0);
    ySlice_avg_pos = ySlice_avg.*(ySlice_avg>0);
    ySlice_avg_neg = ySlice_avg.*(ySlice_avg<0);
    zSlice_avg_pos = zSlice_avg.*(zSlice_avg>0);
    zSlice_avg_neg = zSlice_avg.*(zSlice_avg<0);
    
    clim_up = max(max(xSlice_avg_pos));
    clim_down = min(min(xSlice_avg_neg));
    
    
    clim_up_temp = max(max(xSlice_avg_template));
    clim_down_temp = 0;
    
    fig = figure('Name','Voxel Stats Show');
    set(fig, 'PaperPositionMode', 'auto');
    set(fig, 'position', [300, 300, 950, 540]);
    
    t1 = axes('Position',[0.05, 0.5, 0.28, 0.4]);
    t11 = imagesc(flipud(zSlice_avg_template));
    title('Axial')
    axis equal;axis off;
    t1.CLim = [clim_down_temp clim_up_temp];
    colormap(t1, gray(256));
    hold on
    t2 = axes('Position',[0.05, 0.5, 0.28, 0.4]);
    p1= imagesc(flipud(zSlice_avg_pos));
    axis equal;axis off;
    t2.CLim = [0.02 clim_up];
    colormap(t2, spectral(256));
    hold off
    alpha(p1, 0.5);
    
    
    t1 = axes('Position',[0.33, 0.5, 0.25, 0.4]);
    t11 = imagesc(rot90(xSlice_avg_template));
    title('Coronal')
    axis equal;axis off;
    t1.CLim = [clim_down_temp clim_up_temp];
    colormap(t1, gray(256));
    hold on
    t2 = axes('Position',[0.33, 0.5, 0.25, 0.4]);
    p1= imagesc(rot90(xSlice_avg_pos));
    axis equal;axis off;
    t2.CLim = [0.02 clim_up];
    colormap(t2, spectral(256));
    hold off
    alpha(p1, 0.5);
    
    
    t1 = axes('Position',[0.60, 0.5, 0.27, 0.4]);
    t11 = imagesc(rot90(ySlice_avg_template));
    title('Sagittal')
    axis equal;axis off;
    t1.CLim = [clim_down_temp clim_up_temp];
    colormap(t1, gray(256));
    hold on
    t2 = axes('Position',[0.60, 0.5, 0.27, 0.4]);
    p1= imagesc(rot90(ySlice_avg_pos));
    axis equal;axis off;
    t2.CLim = [0.02 clim_up];
    colormap(t2, spectral(256));
    hold off
    alpha(p1, 0.5);
    
    
    t1 = axes('Position',[0.05, 0.05, 0.28, 0.4]);
    t11 = imagesc(flipud(zSlice_avg_template));
    title('Axial')
    axis equal;axis off;
    t1.CLim = [clim_down_temp clim_up_temp];
    colormap(t1, gray(256));
    hold on
    t2 = axes('Position',[0.05, 0.05, 0.28, 0.4]);
    p1= imagesc(flipud(zSlice_avg_neg));
    axis equal;axis off;
    t2.CLim = [clim_down -0.02];
    colormap(t2, [spectral(256);[0 0 0]]);
    hold off
    alpha(p1, 0.5);
    
    
    t1 = axes('Position',[0.33, 0.05, 0.25, 0.4]);
    t11 = imagesc(rot90(xSlice_avg_template));
    title('Coronal')
    axis equal;axis off;
    t1.CLim = [clim_down_temp clim_up_temp];
    colormap(t1, gray(256));
    hold on
    t2 = axes('Position',[0.33, 0.05, 0.25, 0.4]);
    p1= imagesc(rot90(xSlice_avg_neg));
    axis equal;axis off;
    t2.CLim = [clim_down -0.02];
    colormap(t2, [spectral(256);[0 0 0]]);
    hold off
    alpha(p1, 0.5);
    
    
    t1 = axes('Position',[0.60, 0.05, 0.27, 0.4]);
    t11 = imagesc(rot90(ySlice_avg_template));
    title('Sagittal')
    axis equal;axis off;
    t1.CLim = [clim_down_temp clim_up_temp];
    colormap(t1, gray(256));
    hold on
    t2 = axes('Position',[0.60, 0.05, 0.27, 0.4]);
    p1= imagesc(rot90(ySlice_avg_neg));
    axis equal;axis off;
    t2.CLim = [clim_down -0.02];
    colormap(t2, [spectral(256);[0 0 0]]);
    hold off
    alpha(p1, 0.5);
    
    
    cb0 = axes('Position',[0.87, 0.5, 0.1, 0.4]);
    colormap(cb0, spectral(256));
    axis off;
    cb = colorbar;
    cbPos = get(cb, 'position');
    set(cb, 'position', [cbPos(1) 0.1+cbPos(2) cbPos(3) 0.5*cbPos(4)]);
    caxis([0.02 clim_up])
    
    cb1 = axes('Position',[0.87, 0.05, 0.1, 0.4]);
    colormap(cb1, spectral(256));
    axis off;
    cb = colorbar;
    cbPos = get(cb, 'position');
    set(cb, 'position', [cbPos(1) 0.1+cbPos(2) cbPos(3) 0.5*cbPos(4)]);
    set( cb, 'YDir', 'reverse' );
    caxis([clim_down -0.02])
    
end

