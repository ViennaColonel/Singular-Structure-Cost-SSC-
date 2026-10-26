function cost=baselineCost(left,right,c)
%BASELINECOST SAD, Census, or SAD-Census with an explicit coordinate contract.
% 'paper' preserves the published experiment code, including its limitations.
% 'left' uses left-reference SAD and rejects out-of-image candidates for all
% baselines after normalization. Results from these two modes must not be mixed.
arguments
    left (:,:) double {mustBeFinite}
    right (:,:) double {mustBeFinite}
    c (1,1) struct
end
assert(isequal(size(left),size(right)) && all(size(left)>c.window));
assert(mod(c.window,2)==1 && c.window>=3);
assert(ismember(c.baselineConvention,{'paper','left'}));
assert(ismember(c.baseline,{'SAD','Census','SADCensus','ZNCC','Gradient','BT'}));
if ismember(c.baseline,{'ZNCC','Gradient','BT'})
    assert(strcmp(c.baselineConvention,'paper'),'Additional historical baselines support the paper convention only.');
    cost=ssc.additionalCost(left,right,c);return
end
[h,w]=size(left);ds=c.disparities;cost=zeros(h,w,numel(ds));
paper=strcmp(c.baselineConvention,'paper');
if ~strcmp(c.baseline,'SAD')
    % SAD-Census historically compares 255-scaled doubles; preserve this order.
    if strcmp(c.baseline,'SADCensus'),a=left*255;b=right*255;else,a=left;b=right;end
    fl=census(a);fr=census(b);
end
for j=1:numel(ds)
    d=ds(j);valid=max(1,1+d):min(w,w+d);xr=valid-d;
    switch c.baseline
        case 'SAD'
            if paper
                % Historical right-coordinate cost, evaluated at x downstream.
                x=max(1,1-d):min(w,w-d);
                e=zeros(h,w);e(:,x)=abs(right(:,x)-left(:,x+d));
            else
                x=valid;e=zeros(h,w);e(:,x)=abs(left(:,x)-right(:,xr));
            end
            assert(~isempty(x));e(:,1:x(1))=repmat(e(:,x(1)),1,x(1));
            e(:,x(end):end)=repmat(e(:,x(end)),1,w-x(end)+1);
        case 'Census'
            e=sum(xor(fl,circshift(fr,[0 d 0])),3);
            mask=true(h,w);mask(:,valid)=false;e(mask)=0;
        case 'SADCensus'
            shifted=zeros(h,w);shifted(:,valid)=b(:,xr);
            features=false(size(fr));features(:,valid,:)=fr(:,xr,:);
            ad=abs(a-shifted);ham=sum(xor(fl,features),3);
            e=(1-exp(-ad/10))+(1-exp(-ham/30));
            mask=true(h,w);mask(:,valid)=false;e(mask)=2;
    end
    cost(:,:,j)=conv2(e,ones(c.window),'same');
end
if ~strcmp(c.baseline,'SADCensus')
    n=(c.window-1)/2;
    cost(:,1:n,:)=repmat(cost(:,n+1,:),1,n);
    cost(:,end-n+1:end,:)=repmat(cost(:,end-n,:),1,n);
    cost(1:n,:,:)=repmat(cost(n+1,:,:),n,1);
    cost(end-n+1:end,:,:)=repmat(cost(end-n,:,:),n,1);
end
lo=min(cost(:));hi=max(cost(:));
if hi>lo
    cost=255*(cost-lo)/(hi-lo);
elseif paper && strcmp(c.baseline,'SAD')
    error('ssc:DegeneratePaperSAD','Historical SAD yields NaN on a constant volume; choose a nondegenerate input or the left convention.');
else
    cost=zeros(size(cost));
end
if ~paper
    for j=1:numel(ds)
        invalid=(1:w)-ds(j)<1 | (1:w)-ds(j)>w;
        cost(:,invalid,j)=255;
    end
end
end

function bits=census(image)
[dx,dy]=meshgrid(-2:2,-2:2);offsets=[dx(:),dy(:)];
offsets(all(offsets==0,2),:)=[];bits=false([size(image),24]);
for k=1:24
    bits(:,:,k)=image>circshift(image,[-offsets(k,2),-offsets(k,1)]);
end
end
