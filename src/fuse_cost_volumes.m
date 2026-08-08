function fused = fuse_cost_volumes(traditional,sgsc,energy_map,lambda)
%FUSE_COST_VOLUMES Adaptively fuse traditional and SGSC costs.

    traditional=normalize_zero_one(traditional);
    sgsc=min(max(double(sgsc),0),1);
    confidence=energy_map/(mean(energy_map(:))+1e-6);
    confidence=min(max(confidence,0),1);
    confidence(confidence<0.1)=0;
    confidence_volume=repmat(confidence,[1 1 size(traditional,3)]);
    sgsc_weight=lambda*confidence_volume;
    fused=(1-sgsc_weight).*traditional+sgsc_weight.*sgsc;
    fused=fused*255;
end

function result = normalize_zero_one(value)
    low=min(value(:)); high=max(value(:));
    if high>low
        result=(double(value)-double(low))/double(high-low);
    else
        result=zeros(size(value),'double');
    end
end
