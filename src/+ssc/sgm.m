function disparity=sgm(cost,P1,P2,minDisparity)
%SGM Eight fixed directions; ties select the first (smallest) disparity.
% Native code is optional; the MATLAB implementation follows identical path
% order and transition arithmetic. No left-right check or post-filtering.
arguments
    cost (:,:,:) double {mustBeFinite}
    P1 (1,1) double {mustBePositive}
    P2 (1,1) double {mustBePositive}
    minDisparity (1,1) double {mustBeInteger}=0
end
assert(P2>P1 && size(cost,3)>=2);
if exist('ssc.sgm_native','file')==3
    disparity=ssc.sgm_native(cost,P1,P2,minDisparity);return
end
[h,w,nd]=size(cost);total=zeros(size(cost));
directions=[1 0;1 1;0 1;-1 1;-1 0;-1 -1;0 -1;1 -1];
for k=1:8
    dx=directions(k,1);dy=directions(k,2);path=zeros(size(cost));
    for sy=1:h
        for sx=1:w
            if sx-dx>=1 && sx-dx<=w && sy-dy>=1 && sy-dy<=h,continue;end
            x=sx;y=sy;first=true;
            while x>=1 && x<=w && y>=1 && y<=h
                v=reshape(cost(y,x,:),1,nd);
                if ~first
                    prev=reshape(path(y-dy,x-dx,:),1,nd);mn=min(prev);
                    transition=min(min(prev,[Inf prev(1:end-1)+P1]), ...
                        min([prev(2:end)+P1 Inf],mn+P2));
                    v=v+transition-mn;
                end
                path(y,x,:)=v;total(y,x,:)=reshape(total(y,x,:),1,nd)+v;
                first=false;x=x+dx;y=y+dy;
            end
        end
    end
end
[~,index]=min(total,[],3);disparity=index-1+minDisparity;
end
