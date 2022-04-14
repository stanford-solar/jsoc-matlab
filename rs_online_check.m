% rs_online_check.m
%
% Usage  : rs_online_check querry_string
% Example: rs_online_check 'hmi.lev0e[1800000-1800001]'
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

%          a=rs_list('su_production.lev0f_hmi[706300-706500]&key=FSN,T_OBS,*online*);



function results = rs_online_check(querry_string)

if (nargin <1)
    fprintf ('Usage: rs_online_check "querry_string".\n\n');
    return;
end

try
   %querry_string = 'su_timh.awesome_1&key=**ALL**&seg=**ALL**';
   querry_string  = strcat(querry_string,'&key=*size*,*online*');
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


% Just check rs online status and total_size 
total_size = 0.0;
online = 'Yes';

for j=1:results.count
     
    if (strcmp(results.keywords{2}.values{j},'N'))
         online = 'No';
    end    
    total_size = total_size + str2double(results.keywords{1}.values{j});
    
end


% Note: results.counts is double
fprintf('Found %d records, (all) online = %s, size = %.0f\n', results.count, online, total_size);

%fprintf('Records found %0.1f\n', results.count);
%fprintf('Online = %s\n', online);
%fprintf('Size = %.0f\n', total_size);



fprintf('\n');



