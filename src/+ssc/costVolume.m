function [cost,energy]=costVolume(left,right,disparities,window,modes,weighted)
%COSTVOLUME Singular-structure cost, using left(y,x) and right(y,x-d).
% Images: finite H-by-W doubles. Cost: H-by-W-by-D in [0,1]. Invalid
% correspondences have cost 1. Energy is the retained left singular-value sum.
% Each patch is scalar-mean centered; SVD signs are handled by absolute inner
% products of the corresponding U and V vectors separately.
arguments
    left (:,:) double {mustBeFinite}
    right (:,:) double {mustBeFinite}
    disparities (1,:) double {mustBeInteger,mustBeFinite}
    window (1,1) double {mustBeInteger,mustBePositive}=5
    modes (1,:) double {mustBeInteger,mustBePositive}=[1 2 3]
    weighted (1,1) logical=true
end
assert(isequal(size(left),size(right)) && mod(window,2)==1);
modes=unique(modes,'stable');assert(~isempty(modes) && max(modes)<=window);
[ul,vl,sl]=describe(left,window,max(modes));
[ur,vr,sr]=describe(right,window,max(modes));
[height,width]=size(left);cost=ones(height,width,numel(disparities));
energy=sum(sl(:,:,modes),3);
for j=1:numel(disparities)
    d=disparities(j);x=max(1,1+d):min(width,width+d);xr=x-d;
    numerator=zeros(height,numel(x));el=numerator;er=numerator;
    for k=modes
        au=abs(sum(ul(:,x,:,k).*ur(:,xr,:,k),3));
        av=abs(sum(vl(:,x,:,k).*vr(:,xr,:,k),3));
        if weighted
            w=sqrt(max(sl(:,x,k).*sr(:,xr,k),0));
            lk=max(sl(:,x,k),0);rk=max(sr(:,xr,k),0);
        else
            w=ones(size(numerator));lk=w;rk=w;
        end
        numerator=numerator+w.*(au+av);el=el+lk;er=er+rk;
    end
    similarity=numerator./(2*sqrt(el.*er)+eps);
    cost(:,x,j)=1-min(max(similarity,0),1);
end
end

function [u,v,s]=describe(image,window,rank)
[h,w]=size(image);pad=floor(window/2);
% Replicated padding without requiring Image Processing Toolbox.
iy=[ones(1,pad),1:h,h*ones(1,pad)];
ix=[ones(1,pad),1:w,w*ones(1,pad)];padded=image(iy,ix);
u=zeros(h,w,window,rank);v=u;s=zeros(h,w,rank);
for y=1:h
    for x=1:w
        patch=padded(y:y+window-1,x:x+window-1);
        patch=patch-mean(patch(:));[a,b,c]=svd(patch,'econ');
        u(y,x,:,:)=reshape(a(:,1:rank),1,1,window,rank);
        v(y,x,:,:)=reshape(c(:,1:rank),1,1,window,rank);
        s(y,x,:)=diag(b(1:rank,1:rank));
    end
end
end
