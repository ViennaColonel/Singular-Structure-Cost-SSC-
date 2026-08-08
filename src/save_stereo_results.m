function save_stereo_results(output_dir,disparity,left,right,gt,valid_mask, ...
        metrics,evaluation,config,run_info)
%SAVE_STEREO_RESULTS Save exact disparity, PNG outputs, metadata and plots.

    save(fullfile(output_dir,'disparity.mat'),'disparity');
    save(fullfile(output_dir,'run_info.mat'),'config','run_info','metrics');

    scaled=double(disparity)*config.png_disparity_scale;
    if any(scaled(:)<0) || any(scaled(:)>65535)
        warning('16-bit disparity PNG is clipped; disparity.mat remains exact.');
    end
    scaled=min(max(scaled,0),65535);
    imwrite(uint16(round(scaled)),fullfile(output_dir,'disparity_x256.png'));

    save_disparity_figure(disparity,output_dir,config.figure_resolution);
    if ~isempty(gt)
        metric_table=struct2table(metrics);
        writetable(metric_table,fullfile(output_dir,'metrics.csv'));
        save_evaluation_figures(left,right,disparity,gt,valid_mask, ...
            evaluation,metrics,output_dir,config.figure_resolution);
    end
end

function save_disparity_figure(disparity,output_dir,resolution)
    figure_handle=figure('Visible','off','Color','w','Position',[100 100 850 650]);
    imagesc(disparity); axis image off; colormap(turbo); colorbar;
    title('Estimated disparity (pixels)','FontName','Times New Roman', ...
        'FontWeight','normal');
    set(gca,'FontName','Times New Roman','FontSize',11);
    print(figure_handle,fullfile(output_dir,'disparity_visualization.png'), ...
        '-dpng',sprintf('-r%d',resolution));
    close(figure_handle);
end

function save_evaluation_figures(left,right,disparity,gt,valid_mask, ...
        evaluation,metrics,output_dir,resolution)
    warning_state=warning('query','MATLAB:callback:error');
    warning('off','MATLAB:callback:error');
    restore_warning=onCleanup(@() warning( ...
        warning_state.state,warning_state.identifier));

    valid_gt=gt(valid_mask);
    maximum=ceil(max(valid_gt));
    shown_gt=gt; shown_gt(~valid_mask)=NaN;

    f=figure('Visible','off','Color','w','Position',[50 50 1800 1050]);
    tiledlayout(2,3,'TileSpacing','compact','Padding','compact');
    ax=nexttile; imshow(left,[],'Parent',ax); title(ax,'Left image');
    ax=nexttile; imshow(right,[],'Parent',ax); title(ax,'Right image');
    ax=nexttile; imagesc(ax,disparity,[0 maximum]); axis(ax,'image');
    axis(ax,'off'); colormap(ax,turbo); colorbar(ax);
    title(ax,sprintf('Estimated disparity (MAE %.2f px)',metrics.MAE_px));
    ax=nexttile; imagesc(ax,shown_gt,[0 maximum]); axis(ax,'image');
    axis(ax,'off'); colormap(ax,turbo); colorbar(ax); title(ax,'Ground truth');
    ax=nexttile; imagesc(ax,evaluation.absolute_error,[0 5]);
    axis(ax,'image'); axis(ax,'off'); colormap(ax,parula); colorbar(ax);
    title(ax,sprintf('Absolute error (RMSE %.2f px)',metrics.RMSE_px));
    ax=nexttile; imagesc(ax,evaluation.bad_pixel_map,[0 1]);
    axis(ax,'image'); axis(ax,'off'); colormap(ax,gray(2));
    title(ax,sprintf('Bad pixels >1 px (%.2f%%)',metrics.BPR_1_0_pct));
    axes_list=findall(f,'Type','axes');
    set(axes_list,'FontName','Times New Roman','FontSize',11);
    print(f,fullfile(output_dir,'evaluation_panel.png'), ...
        '-dpng',sprintf('-r%d',resolution));
    close(f);
    clear restore_warning;
end

