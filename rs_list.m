% rs_list.m
%
% Usage  : rs_list querry_string
% Example: rs_list 'hmi.lev0e[1800000-1800001]&key=T_OBS,FSN,*online*,*sunum*,*recnum*,*size*,*retain*,*logdir*'
%
%          rs_list mdi.vw_V_lev18[1996.05.01_12:00/5d&rs_list&key=DATAMEAN,T_OBS&seg=**NONE**] ?
%
%          a=rs_list('su_timh.supersid_test_data_3&key=**ALL**&segment=**ALL**')
%          a=rs_list('su_timh.supersid_test_data_3[][NWC]&key=StationID,Site&segment=**ALL**')
%          rs_list 'su_production.lev0_test[66051-90090]&key=FSN,T_OBS,'
%
%          rs_summary hmi.lev0e[1800000-1800100]
%          rs_list 'hmi.lev0e[1800000-1800100]&key=T_OBS,FSN'
%          a=rs_list('hmi.lev0e[1800000-1800001]&key=');
%          a=rs_list('hmi.lev0e[1800000-1800001]&key=T_OBS,FSN,*online*');
%          a=rs_list('hmi.lev0e[1800000-1800001]&key=T_OBS,FSN,*online*,*sunum*,*recnum*,*size*,*retain*,*logdir*');





function results = rs_list(querry_string)

if (nargin <1)
    fprintf ('Usage: rs_list "querry_string".\n\n');
    return;
end

try
   url_string = strcat('http://jsoc.stanford.edu/cgi-bin/ajax/jsoc_info?op=rs_list&ds=',querry_string);
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



% Keywords {'name': , 'type': , 'units': , 'note': }
fprintf('\nKeywords:\n');
for k=1:length(results.keywords)    
    fprintf ('  %s\n',results.keywords{k}.name);  
end

% Print records found
fprintf('\n');
for j=1:results.count
    for k=1:length(results.keywords)
        if ischar(results.keywords{k}.values{j})
            fprintf('%s\t',results.keywords{k}.values{j});
        else
            fprintf('%f\t',results.keywords{k}.values{j});            
        end
    end
    fprintf('\n');
end

fprintf('\nRecords found %d\n',results.count);

%{
% Segments
fprintf('\nSegments:\n');
for k=1:length(results.segments)    
    fprintf ('  %s\n',results.segments{k}.name);
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
%for k=1:length(results.dbindex)    
%    fprintf ('  %s\n',results.dbindex.name);
%end


%disp(results.keywords);

% Printing series names
%{
for k=1:length(results.names)    
    fprintf ('  %s\n',results.names{k}.name);
end

fprintf('\nNumber of series matched [%s] = %d\n',filter_string, results.n );
%}
%}


return
