function VoxelStatsShow( stat_mat, image_dims, voxel_dims)

    figure_layout_width_slices = 8;
    figure_layout_height_slices = 4;

    image_slices_n = image_dims(1);
    image_height_n = image_dims(2);
    image_width_n = image_dims(3);
    
    slice_length = voxel_dims(1);
    voxel_height = voxel_dims(2);
    voxel_width = voxel_dims(3);
    
    image_slices_n_rs = ceil(image_slices_n*slice_length);
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
    
    xSlice_avg = imresize(squeeze(mean(stats_mat_3d, 1)), [image_width_n_rs, image_slices_n_rs]);
    ySlice_avg = imresize(squeeze(mean(stats_mat_3d, 2)), [image_height_n_rs, image_slices_n_rs]);
    zSlice_avg = imresize(squeeze(mean(stats_mat_3d, 3)), [image_height_n_rs, image_width_n_rs]);
    
    
    image_mat_pos = image_mat.*(image_mat>0);
    image_mat_neg = image_mat.*(image_mat<0);
    xSlice_avg_pos = xSlice_avg.*(xSlice_avg>0);
    xSlice_avg_neg = xSlice_avg.*(xSlice_avg<0);
    ySlice_avg_pos = ySlice_avg.*(ySlice_avg>0);
    ySlice_avg_neg = ySlice_avg.*(ySlice_avg<0);
    zSlice_avg_pos = zSlice_avg.*(zSlice_avg>0);
    zSlice_avg_neg = zSlice_avg.*(zSlice_avg<0);
    
    clim_up = max(max(xSlice_avg_pos));
    clim_down = min(min(xSlice_avg_neg));
    
    
    
    
    fig = figure('Name','Voxel Stats Show');
    set(fig, 'PaperPositionMode', 'auto');
    set(fig, 'position', [300, 300, 950, 540]);
    
    p3 = subplot('Position',[0.05, 0.5, 0.28, 0.4]);
    imagesc(flipud(zSlice_avg_pos));
    title('Axial')
    axis equal;axis off;
    colormap(p3, spectral(256));
    caxis([0.02 clim_up]);
    
    
    p1 = subplot('Position',[0.33, 0.5, 0.25, 0.4]);
    imagesc(rot90(xSlice_avg_pos));
    title('Coronal');
    axis equal;axis off;
    caxis([0.02 clim_up]);
    colormap(p1, spectral(256));
    caxis([0.02 clim_up]);
    
    p2 = subplot('Position',[0.60, 0.5, 0.27, 0.4]);
    imagesc(rot90(ySlice_avg_pos));
    title('Sagittal');
    axis equal;axis off; 
    colormap(p2, spectral(256));
    caxis([0.02 clim_up]);
    

    
    p6 = subplot('Position',[0.05, 0.05, 0.28, 0.4]);
    imagesc(flipud(zSlice_avg_neg));
     title('Axial')
    axis equal;axis off;
    colormap(p6, [spectral(256);[0 0 0]]);
    caxis([clim_down -0.02]);
    
    
    p4 = subplot('Position',[0.33, 0.05, 0.25, 0.4]);
    imagesc(rot90(xSlice_avg_neg));
    title('Coronal');
    axis equal;axis off;
    colormap(p4,  [spectral(256);[0 0 0]]);
    caxis([clim_down -0.02]);
    
    p5 = subplot('Position',[0.60, 0.05, 0.27, 0.4]);
    imagesc(rot90(ySlice_avg_neg));
    title('Sagittal');
    axis equal;axis off; 
    colormap(p5, [spectral(256);[0 0 0]]);
    caxis([clim_down -0.02]);
    

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
    
    set(fig,'Color',[0.1 0.1 0.1],'InvertHardcopy','off');
    
    
%     p7 = subplot(2,7,[8,9,10]);
%     imagesc(rot90(image_mat_pos,2)); 
%     set( get(p4,'XLabel'), 'String', 'Slice View' );
%     c=colorbar; colormap(spectral(256));
%     axis equal; axis off;  
%     background='white';
%     whitebg(gcf,background);
%     set(gcf,'Color',background,'InvertHardcopy','off');
%     ax = gcf;
%     axpos = ax.Position;
%     cpos = c.Position;
%     %cpos = [0.9, 0.22, 0.5*cpos(3), 0.7*cpos(4)];
%     c.Position = cpos;
%     ax.Position = axpos;
%     
%     
%     
%     p8 = subplot(2,7,[12,13,14]);
%     imagesc(rot90(image_mat_neg,2)); 
%     set( get(p4,'XLabel'), 'String', 'Slice View' );  
%     c=colorbar; colormap(spectral(256));
%     
%     axis equal; axis off;  
%     background='white';
%     whitebg(gcf,background);
%     set(gcf,'Color',background,'InvertHardcopy','off');
%     ax = gcf;
%     axpos = ax.Position;
%     cpos = c.Position;
%     %cpos = [0.9, 0.22, 0.5*cpos(3), 0.7*cpos(4)];
%     c.Position = cpos;
%     ax.Position = axpos;
end

