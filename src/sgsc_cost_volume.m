function [cost,energy_map] = sgsc_cost_volume(left,right,window_size, ...
        disparity_range,target_modes,use_weighting)
%SGSC_COST_VOLUME Compute the Spectral-Gap Structural Cost volume.

% Local image patches are represented by ordered spectral modes. Matching
% cost measures the structural disagreement between corresponding modes.

    if max(target_modes)>window_size
        error('A requested SGSC mode exceeds sgsc_window.');
    end
    left=double(left); right=double(right);
    max_mode=max(target_modes);
    [u_left,v_left,sigma_left]=extract_features(left,window_size,max_mode);
    [u_right,v_right,sigma_right]=extract_features(right,window_size,max_mode);

    [height,width]=size(left);
    disparities=disparity_range(1):disparity_range(2);
    cost=ones(height,width,numel(disparities));
    energy_map=sum(sigma_left(:,:,target_modes),3);

    for index=1:numel(disparities)
        disparity=disparities(index);
        start_x=max(1,1+disparity);
        end_x=min(width,width+disparity);
        if start_x>end_x, continue; end
        left_columns=start_x:end_x;
        right_columns=left_columns-disparity;
        weighted_sum=zeros(height,numel(left_columns));
        weight_sum=zeros(height,numel(left_columns));

        for mode=target_modes
            ul=u_left(:,left_columns,:,mode);
            vl=v_left(:,left_columns,:,mode);
            sl=sigma_left(:,left_columns,mode);
            ur=u_right(:,right_columns,:,mode);
            vr=v_right(:,right_columns,:,mode);
            sr=sigma_right(:,right_columns,mode);
            similarity_u=abs(sum(ul.*ur,3));
            similarity_v=abs(sum(vl.*vr,3));
            raw_cost=1-similarity_u.*similarity_v;
            if use_weighting
                weight=sqrt(sl.*sr);
            else
                weight=ones(size(raw_cost));
            end
            weighted_sum=weighted_sum+raw_cost.*weight;
            weight_sum=weight_sum+weight;
        end
        cost(:,left_columns,index)=weighted_sum./(weight_sum+1e-9);
    end
end

function [feature_u,feature_v,sigma] = extract_features(image,window,max_mode)
    [height,width]=size(image);
    padding=floor(window/2);
    padded=padarray(image,[padding padding],'replicate','both');
    feature_u=zeros(height,width,window,max_mode);
    feature_v=zeros(height,width,window,max_mode);
    sigma=zeros(height,width,max_mode);
    for row=1:height
        for column=1:width
            patch=padded(row:row+window-1,column:column+window-1);
            patch=patch-mean(patch(:));
            [u,s,v]=svd(patch,'econ');
            for mode=1:max_mode
                feature_u(row,column,:,mode)=u(:,mode);
                feature_v(row,column,:,mode)=v(:,mode);
                sigma(row,column,mode)=s(mode,mode);
            end
        end
    end
end
