% exp_request.m
%
% Usage  : exp_request rs_querry_string
%
% Example: exp_request 'su_timh.supersid_test_data_3[][NWC][]'
%          a=exp_request('su_production.lev0f_hmi[706315]{image}');
%          a=exp_resquest ('su_production.lev0f_hmi[#^]{image}');
%


function results = exp_request(querry_string)

if (nargin <1)
    fprintf ('Usage: exp_request "rs_querry_string".\n\n');
    return;
end

try

    url_string = strcat('http://jsoc.stanford.edu/cgi-bin/ajax/jsoc_fetch?op=exp_request&ds=',querry_string);
    url_string = strcat(url_string,'&method=url_quick');
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

disp(results);

if ((int32(results.wait) == 0) & (int32(results.status) == 0))
   url = 'http://jsoc.stanford.edu/';
   url = strcat(url, (results.data{1}.filename));
      
   fprintf('%s\n\n',url);
   
   % Read and display text file
   %csv_file = urlread(url);
   %disp(csv_file);
   
   % Write the text file to disk
   try
   [path_string, name, extension, version] = (fileparts(results.data{1}.filename));
   file_name = strcat(name, extension);
   urlwrite(url,file_name);
   catch
       disp(lasterror);
       return;
   end
   
   fprintf('%s downloaded!\n',file_name);
     
end


return
