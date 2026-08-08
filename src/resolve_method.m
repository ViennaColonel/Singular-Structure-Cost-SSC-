function method = resolve_method(method_name)
%RESOLVE_METHOD Normalize method names and describe required cost terms.

    id = upper(char(string(method_name)));
    id = regexprep(id,'[\s\-\+]','_');
    id = regexprep(id,'_+','_');
    id = regexprep(id,'^_|_$','');

    aliases = struct( ...
        'SADCENSUS','SAD_CENSUS', ...
        'ADCENSUS','SAD_CENSUS', ...
        'AD_CENSUS','SAD_CENSUS', ...
        'SADCENSUS_SGSC','SAD_CENSUS_SGSC', ...
        'ADCENSUS_SGSC','SAD_CENSUS_SGSC', ...
        'AD_CENSUS_SGSC','SAD_CENSUS_SGSC', ...
        ... % Legacy method names kept as input aliases.
        'POD','SGSC', ...
        'SAD_POD','SAD_SGSC', ...
        'CENSUS_POD','CENSUS_SGSC', ...
        'SADCENSUS_POD','SAD_CENSUS_SGSC', ...
        'SAD_CENSUS_POD','SAD_CENSUS_SGSC', ...
        'ADCENSUS_POD','SAD_CENSUS_SGSC', ...
        'AD_CENSUS_POD','SAD_CENSUS_SGSC');
    if isfield(aliases,id), id=aliases.(id); end

    switch id
        case 'SAD'
            method = make_method(id,'SAD','SAD',false);
        case 'CENSUS'
            method = make_method(id,'Census','CENSUS',false);
        case 'SAD_CENSUS'
            method = make_method(id,'SAD-Census','SAD_CENSUS',false);
        case 'SGSC'
            method = make_method(id,'SGSC','NONE',true);
        case 'SAD_SGSC'
            method = make_method(id,'SAD + SGSC','SAD',true);
        case 'CENSUS_SGSC'
            method = make_method(id,'Census + SGSC','CENSUS',true);
        case 'SAD_CENSUS_SGSC'
            method = make_method(id,'SAD-Census + SGSC','SAD_CENSUS',true);
        otherwise
            error(['Unknown method "%s". Use SAD, CENSUS, SAD_CENSUS, ', ...
                'SGSC, SAD_SGSC, CENSUS_SGSC, or SAD_CENSUS_SGSC.'],id);
    end
end

function method = make_method(id,display_name,traditional,uses_sgsc)
    method.id=id;
    method.display_name=display_name;
    method.traditional=traditional;
    method.uses_sgsc=uses_sgsc;
    method.is_fusion=uses_sgsc && ~strcmp(traditional,'NONE');
end
