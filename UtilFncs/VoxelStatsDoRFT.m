function [ corrected_stats_mat ] = VoxelStatsDoRFT( stats_mat, image_dims, search_vol, num_voxels, fwhm, ...
    df, peak_pval, clus_th)
%VoxelStatsDoRFT Will perform rft pbased MCC on the statistics 
%supplied and the paramters. 
%Thresholds are calculated from the stat_threshold function in surfstat
%toolbox. 
%Current implementation assumes isotropic fields in the image. 

[peak_th, extent_th, peak_th_1 extent_th_1] = ...
    stat_threshold(search_vol,num_voxels,fwhm,df,peak_pval,clus_th,[]);
clus_th_n = tinv(clus_th,df);
clus_th_p = -1*clus_th_n;

voxel_size = search_vol/num_voxels;

image_slices_n = image_dims(1);
image_height_n = image_dims(2);
image_width_n = image_dims(3);

stats_mat_pos = stats_mat.*(stats_mat>clus_th_p);
stats_mat_neg = stats_mat.*(stats_mat<clus_th_n);

stats_mat_3d_t = reshape(stats_mat_pos, image_width_n , image_height_n, image_slices_n);
stats_mat_3d = permute(stats_mat_3d_t, [2,1,3]);
[labelMat labels] = bwlabeln(stats_mat_3d, 6);
regionProps = regionprops(labelMat, 'Area');
areaForClust = cat(1, regionProps.Area);
TotalClusters_pos = sum(areaForClust>(extent_th/voxel_size))
stat_mat_3d_finalClusts = stats_mat_3d.*(ismember(labelMat, find(areaForClust>(extent_th/voxel_size))));
if length(stat_mat_3d_finalClusts) > 0
    stat_mat_corrected = permute(stat_mat_3d_finalClusts, [2,1,3]);
    stat_mat_corrected_pos = reshape(stat_mat_corrected, [image_width_n*image_height_n, image_slices_n]);
else
    stat_mat_corrected_pos = zeros(image_width_n*image_height_n, image_slices_n);
end

stats_mat_3d_t = reshape(stats_mat_neg, image_width_n , image_height_n, image_slices_n);
stats_mat_3d = permute(stats_mat_3d_t, [2,1,3]);
[labelMat labels] = bwlabeln(stats_mat_3d, 6);
regionProps = regionprops(labelMat, 'Area');
areaForClust = cat(1, regionProps.Area);
TotalClusters_neg = sum(areaForClust>(extent_th/voxel_size))
stat_mat_3d_finalClusts = stats_mat_3d.*(ismember(labelMat, find(areaForClust>(extent_th/voxel_size))));
if length(stat_mat_3d_finalClusts) > 0
    stat_mat_corrected = permute(stat_mat_3d_finalClusts, [2,1,3]);
    stat_mat_corrected_neg = reshape(stat_mat_corrected, [image_width_n*image_height_n, image_slices_n]);
else
    stat_mat_corrected_neg = zeros(image_width_n*image_height_n, image_slices_n);
end

corrected_stats_mat = stat_mat_corrected_pos + stat_mat_corrected_neg;

end

