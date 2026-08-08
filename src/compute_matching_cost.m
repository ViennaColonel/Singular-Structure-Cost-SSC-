function [cost_volume, info] = compute_matching_cost(left,right,config,method)
%COMPUTE_MATCHING_COST Build the traditional/SGSC/fusion matching cost.

    traditional_cost = [];
    sgsc_cost = [];
    energy_map = [];

    if ~strcmp(method.traditional,'NONE')
        traditional_cost = traditional_cost_volume( ...
            left,right,config,method.traditional);
    end
    if method.uses_sgsc
        [sgsc_cost,energy_map] = sgsc_cost_volume(left,right, ...
            config.sgsc_window,config.disparity_range,config.sgsc_modes, ...
            config.sgsc_use_weighting);
    end

    if method.is_fusion
        cost_volume = fuse_cost_volumes(traditional_cost,sgsc_cost, ...
            energy_map,config.fusion_lambda);
        info.cost_scale = '0-255 fused';
    elseif method.uses_sgsc
        cost_volume = sgsc_cost * config.sgsc_only_cost_scale;
        info.cost_scale = sprintf('SGSC x %.4g',config.sgsc_only_cost_scale);
    else
        cost_volume = traditional_cost;
        info.cost_scale = '0-255 normalized';
    end
    info.method = method.id;
    info.minimum = min(cost_volume(:));
    info.maximum = max(cost_volume(:));
end

function C = traditional_cost_volume(left,right,config,cost_name)
    left255 = im2double(left)*255;
    right255 = im2double(right)*255;
    [height,width] = size(left255);
    disparities = config.disparity_range(1):config.disparity_range(2);
    C = zeros(height,width,numel(disparities),'double');
    box_filter = ones(config.block_size);

    needs_census = strcmp(cost_name,'CENSUS') || ...
        strcmp(cost_name,'SAD_CENSUS');
    if needs_census
        census_left = census_transform(left255,config.census_window);
        census_right = census_transform(right255,config.census_window);
    end

    for index = 1:numel(disparities)
        disparity = disparities(index);
        [shifted_right,valid] = shift_support(right255,disparity);

        switch cost_name
            case 'SAD'
                pixel_cost = abs(left255-shifted_right);
                maximum_cost = 255;
            case 'CENSUS'
                shifted_census = shift_support(census_right,disparity);
                pixel_cost = sum(xor(census_left,shifted_census),3);
                maximum_cost = size(census_left,3);
            case 'SAD_CENSUS'
                shifted_census = shift_support(census_right,disparity);
                ad = abs(left255-shifted_right);
                hamming = sum(xor(census_left,shifted_census),3);
                pixel_cost = 1-exp(-ad/config.ad_lambda) + ...
                    1-exp(-hamming/config.census_lambda);
                maximum_cost = 2;
            otherwise
                error('Unsupported traditional cost: %s',cost_name);
        end

        pixel_cost(~valid) = maximum_cost;
        C(:,:,index) = conv2(pixel_cost,box_filter,'same');
    end
    C = normalize_cost(C,255);
end

function census = census_transform(image,window_size)
    half_h=floor(window_size(1)/2);
    half_w=floor(window_size(2)/2);
    padded=padarray(image,[half_h half_w],'replicate','both');
    [height,width]=size(image);
    census=false(height,width,window_size(1)*window_size(2)-1);
    bit=0;
    for dy=-half_h:half_h
        for dx=-half_w:half_w
            if dx==0 && dy==0, continue; end
            bit=bit+1;
            neighbor=padded((1:height)+half_h+dy, ...
                (1:width)+half_w+dx);
            census(:,:,bit)=image>neighbor;
        end
    end
end

function [shifted,valid] = shift_support(data,disparity)
    [height,width,depth]=size(data);
    if ismatrix(data), depth=1; end
    shifted=zeros(height,width,depth,'like',data);
    valid=false(height,width);
    if disparity>=0
        if disparity<width
            shifted(:,1+disparity:end,:)=data(:,1:width-disparity,:);
            valid(:,1+disparity:end)=true;
        end
    else
        amount=-disparity;
        if amount<width
            shifted(:,1:width-amount,:)=data(:,1+amount:end,:);
            valid(:,1:width-amount)=true;
        end
    end
    if depth==1, shifted=reshape(shifted,height,width); end
end

function normalized = normalize_cost(cost,maximum)
    low=min(cost(:)); high=max(cost(:));
    if high>low
        normalized=maximum*(double(cost)-double(low))/double(high-low);
    else
        normalized=zeros(size(cost),'double');
    end
end
