% series_list.m
%
% Usage  : series_list filter_string
% Example: series_list hmi  => list series with 'hmi' in the series name
%
% Notes: show_series|parse_json returns 
% struct {'status': double, 'names':[% ], 'n': double}

function series_list(filter_string)

if (nargin < 1)
    fprintf ('Usage: series_list filter_string.\n\n');
    %filter_string = 'NOT^dsds\.'
    return
end

try
   url_string = strcat('http://jsoc.stanford.edu/cgi-bin/ajax/show_series?ds=',filter_string);
   json_content = urlread(url_string);
   results = parse_json(json_content);

catch
    disp(lasterror);
    return;
end

if (results.status > 0) % Note: status type is double
   fprint ('Fail to get a response from JSOC\n');
   return;
end


% Printing series names

for k=1:length(results.names)    
    fprintf ('  %s\n',results.names{k}.name);
end

fprintf('\nNumber of series matched [%s] = %d\n\n',filter_string, results.n );

return
