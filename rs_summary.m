% rs_summary.m
%
% Usage  : rs_summary series_name
% Example: rs_summary hmi.lev0e  
%
% Notes: jsoc_info | parse_json returns 


function results = rs_summary(series_name)

if (nargin <1)
    fprintf ('Series name not specified.\n\n');
    return;
end

try
   url_string = strcat('http://jsoc.stanford.edu/cgi-bin/ajax/jsoc_info?op=rs_summary&ds=',series_name);
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

disp(results);

return
