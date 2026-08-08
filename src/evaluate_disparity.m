function [metrics,evaluation] = evaluate_disparity(disparity,gt,valid_mask)
%EVALUATE_DISPARITY Compute standard pixel-error metrics.

    valid_mask=valid_mask & isfinite(disparity) & isfinite(gt);
    if ~any(valid_mask(:)), error('Ground truth has no valid pixels.'); end
    absolute_error=abs(double(disparity)-double(gt));
    values=absolute_error(valid_mask);

    metrics.ValidPixels=nnz(valid_mask);
    metrics.MAE_px=mean(values);
    metrics.RMSE_px=sqrt(mean(values.^2));
    metrics.BPR_0_5_pct=mean(values>0.5)*100;
    metrics.BPR_1_0_pct=mean(values>1.0)*100;
    metrics.BPR_2_0_pct=mean(values>2.0)*100;

    evaluation.absolute_error=absolute_error;
    evaluation.absolute_error(~valid_mask)=NaN;
    evaluation.bad_pixel_map=false(size(gt));
    evaluation.bad_pixel_map(valid_mask)=absolute_error(valid_mask)>1;
end

