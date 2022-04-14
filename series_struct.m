% series_struct.m
%
% Usage  : series_struct series_name
% Example: series_struct hmi.lev0e  
%
% Notes: jsoc_info | parse_json returns 
% struct {'status': double, 'names':[% ], 'n': double}

function results = series_struct(series_name)

if (nargin <1)
    fprintf ('Series name not specified.\n');
    return;
end

try
   url_string = strcat('http://jsoc.stanford.edu/cgi-bin/ajax/jsoc_info?op=series_struct&ds=',series_name);
   json_content = urlread(url_string);
  
   results = parse_json(json_content);

catch
    disp(lasterror);
    return;
end

if (results.status > 0) % Note: status type is double
   fprintf ('Fail to get a response from JSOC\n');
   return;
end

%disp(results);


% Keywords {'name': , 'type': , 'units': , 'note': }
fprintf('\nKeywords:\n');
for k=1:length(results.keywords)    
    %fprintf ('  %s\n',results.keywords{k}.name);
    fprintf ('  %-30s\t%s\n',results.keywords{k}.name, results.keywords{k}.note);    
end

% Segments
fprintf('\nSegments:\n');
for k=1:length(results.segments)    
    fprintf ('  %s\n',results.segments{k}.name);
    fprintf('\n');
    disp(results.segments{k})
end

% Links
fprintf('\nLinks:\n');
for k=1:length(results.links)    
    fprintf ('  %s\n',results.link{k}.name);
end


% DB Indexes
fprintf('DB Index:\n');
disp(results.dbindex)

% Intervals
fprintf('\nInterval:\n');
disp(results.Interval)

fprintf('\n');

return
