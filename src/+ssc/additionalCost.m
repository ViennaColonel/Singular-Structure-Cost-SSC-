function cost=additionalCost(reference,support,c)
%ADDITIONALCOST Archived ZNCC, gradient and BT comparators, shared utilities.
% Coordinates intentionally retain support(x) versus reference(x+d).
% This is the paper protocol; do not describe it as left-reference matching.
[h,w]=size(reference);cost=zeros(h,w,numel(c.disparities));
kernel=ones(c.window);n=c.window^2;
switch c.baseline
    case 'ZNCC'
        sumS=conv2(support,kernel,'same');sumS2=conv2(support.^2,kernel,'same');
    case 'Gradient'
        gx=[-.5 0 .5];gy=gx';
        rx=conv2(reference,gx,'same');ry=conv2(reference,gy,'same');
        sx=conv2(support,gx,'same');sy=conv2(support,gy,'same');
    case 'BT'
        [smin,smax]=interval(support);[rmin,rmax]=interval(reference);
end
for j=1:numel(c.disparities)
    d=c.disparities(j);
    switch c.baseline
        case 'ZNCC'
            q=shift(reference,d);sq=conv2(q,kernel,'same');sq2=conv2(q.^2,kernel,'same');
            numerator=conv2(support.*q,kernel,'same')-sumS.*sq/n;
            denominator=sqrt(max(sumS2-sumS.^2/n,0).*max(sq2-sq.^2/n,0));
            cost(:,:,j)=1-max(-1,min(1,numerator./max(denominator,eps)));
        case 'Gradient'
            cost(:,:,j)=conv2(abs(sx-shift(rx,d))+abs(sy-shift(ry,d)),kernel,'same');
        case 'BT'
            q=shift(reference,d);qmin=shift(rmin,d);qmax=shift(rmax,d);
            ds=max(max(support-qmax,qmin-support),0);
            dr=max(max(q-smax,smin-q),0);
            cost(:,:,j)=conv2(min(ds,dr),kernel,'same');
    end
end
f=(c.window-1)/2;
cost(:,1:f,:)=repmat(cost(:,f+1,:),1,f);
cost(:,end-f+1:end,:)=repmat(cost(:,end-f,:),1,f);
cost(1:f,:,:)=repmat(cost(f+1,:,:),f,1);
cost(end-f+1:end,:,:)=repmat(cost(end-f,:,:),f,1);
lo=min(cost(:));hi=max(cost(:));
if hi>lo,cost=255*(cost-lo)/(hi-lo);else,cost=zeros(size(cost));end
end
function q=shift(image,d)
w=size(image,2);x=min(max((1:w)+d,1),w);q=image(:,x);
end
function [lo,hi]=interval(image)
left=[image(:,1),image(:,1:end-1)];right=[image(:,2:end),image(:,end)];
lo=min(cat(3,image,(image+left)/2,(image+right)/2),[],3);
hi=max(cat(3,image,(image+left)/2,(image+right)/2),[],3);
end
