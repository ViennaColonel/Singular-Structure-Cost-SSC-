function run_tests()
%RUN_TESTS No dataset or previously generated binary required.
rng(72,'twister');left=rand(13,17);right=circshift(left,[0 -2]);
c=ssc.paperConfig(-1:4);
[s,e]=ssc.costVolume(left,right,c.disparities,5,[1 2 3],true);
assert(isequal(size(s),[13 17 6]) && all(s(:)>=0 & s(:)<=1));
assert(max(abs(s(3:end-2,5:end-2,4)),[],'all')<1e-12);
[identity,~]=ssc.costVolume(left,2*left+0.3,0:1,5,[1 2 3],true);
assert(max(identity(:,:,1),[],'all')<1e-12);
for name={'SAD','Census','SADCensus'}
    c.baseline=name{1};b=ssc.baselineCost(left,right,c);
    [f,w]=ssc.fuse(b,s,e,.15);assert(all(isfinite(f(:))) && all(w(:)<=.15));
    z=ssc.fuse(b,s,e,0);assert(max(abs(z(:)-b(:)))<1e-12);
end
c.baseline='Census';c.baselineConvention='left';b=ssc.baselineCost(left,right,c);
assert(all(b(:,1:4,6)==255,'all'));
m=ssc.metrics([0 1 2],[0 0 0],true(1,3));assert(abs(m.BPR_1_0_pct-100/3)<1e-12);
volume=repmat(reshape([4 0 7],1,1,3),4,5,1);
d=ssc.sgm(volume,2,8,0);assert(all(d(:)==1));
fprintf('PASS: geometry, affine invariance, normalization, boundaries, metrics and SGM.\n');
end
