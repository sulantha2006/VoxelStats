function [resultMat] = readmultiValuedNiftiData( subjectList, totalSlices, mask_slices)
    [n m] = size(subjectList);
    resultMat = zeros(n, sum(sum(mask_slices)));
    for i = 1:n
        h = [];
        for retry=1:5
            try
                h = load_nii(subjectList{i,1});
                t = reshape(h.img, [], totalSlices);
                resultMat(i,:) = t(mask_slices)';
                break;
            catch
                fprintf('File reading failed for : %s \nSleeping 5s before retrying...\n', subjectList{i,1});
                try
                    clear h;
                end
                pause(5);
                if retry < 5
                    continue;
                else
                    fprintf('File reading failed and connot recover. ')
                    exit
                end
            end
        end
    end
end

