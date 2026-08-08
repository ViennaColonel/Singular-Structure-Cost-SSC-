function disparity = sgm_optimize(cost,parameters)
%SGM_OPTIMIZE Aggregate eight SGM directions and select disparities.

    if parameters.directions~=8
        error('Only eight SGM directions are implemented.');
    end
    if parameters.P1<=0 || parameters.P2<=parameters.P1
        error('SGM penalties must satisfy P2 > P1 > 0.');
    end

    [height,width,depth]=size(cost);
    maximum_intercept=width+height;
    summed_cost=zeros(size(cost),'double');

    for direction=1:parameters.directions
        direction_cost=zeros(size(cost),'double');
        for intercept=-maximum_intercept:maximum_intercept
            indices=path_indices(direction,intercept,width,height,depth);
            if isempty(indices), continue; end
            slice=reshape(cost(indices),[],depth);
            direction_cost(indices)=path_cost(slice', ...
                parameters.P1,parameters.P2)';
        end
        summed_cost=summed_cost+direction_cost;
    end

    [~,labels]=min(summed_cost,[],3);
    disparity=labels+parameters.disparity_range(1)-1;
end

function indices = path_indices(direction,b,width,height,depth)
    switch direction
        case 1, a1=1; a2=0;  flip_order=false;
        case 2, a1=1; a2=1;  flip_order=false;
        case 3, a1=0; a2=1;  flip_order=false;
        case 4, a1=1; a2=-1; flip_order=true;
        case 5, a1=1; a2=0;  flip_order=true;
        case 6, a1=1; a2=1;  flip_order=true;
        case 7, a1=0; a2=1;  flip_order=true;
        case 8, a1=1; a2=-1; flip_order=false;
    end

    if a1~=0
        x=1:width;
        y=(a2*x+b)*a1;
        inside=y>=1 & y<=height;
    else
        y=1:height;
        x=-b*a2*ones(size(y));
        inside=x>=1 & x<=width;
    end
    x=x(inside); y=y(inside);
    if flip_order, x=fliplr(x); y=fliplr(y); end
    if isempty(x), indices=[]; return; end

    path_length=numel(x);
    x=repmat(x,1,depth)';
    y=repmat(y,1,depth)';
    z=repmat(1:depth,path_length,1); z=z(:);
    indices=sub2ind([height width depth],y,x,z);
end

function aggregated = path_cost(cost,P1,P2)
    labels=size(cost,1);
    columns=size(cost,2);
    label_values=1:labels;
    [previous,current]=meshgrid(label_values,label_values);
    penalty=zeros(labels);
    penalty(abs(current-previous)==1)=P1;
    penalty(abs(current-previous)>1)=P2;

    aggregated=zeros(size(cost));
    aggregated(:,1)=cost(:,1);
    for column=2:columns
        previous_cost=aggregated(:,column-1);
        transition=min(repmat(previous_cost',labels,1)+penalty,[],2);
        aggregated(:,column)=cost(:,column)+transition-min(previous_cost);
    end
end
