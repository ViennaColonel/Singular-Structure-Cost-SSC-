function [cost,weight]=fuse(base,structural,energy,maxWeight)
%FUSE Historical volume-level scaling and spatial SSC confidence weighting.
% base in [0,255], structural in [0,1]; output in [0,255]. Weight depends
% on retained singular-value sums, not on spectral gaps. No per-curve min-max.
arguments
    base (:,:,:) double {mustBeFinite,mustBeNonnegative}
    structural (:,:,:) double {mustBeFinite}
    energy (:,:) double {mustBeFinite,mustBeNonnegative}
    maxWeight (1,1) double {mustBeInRange(maxWeight,0,1)}=0.15
end
assert(isequal(size(base),size(structural)) && isequal(size(energy),[size(base,1),size(base,2)]));
scale=max(base(:));if scale>1,base=base/scale;end
structural=min(max(structural,0),1);
confidence=energy/(mean(energy(:))+1e-6);
confidence(confidence>1)=1;confidence(confidence<0.1)=0;
weight=maxWeight*confidence;
cost=255*((1-weight).*base+weight.*structural);
end
