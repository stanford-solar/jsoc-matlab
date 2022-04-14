% fits_view.m
%
% Usage  : fits_view image.fits
% Example: fits_view 'coffe_cup_sun_spot.fits'


function image_handle = fits_view(filename)

if (nargin <1)
    fprintf ('Usage: fits_view image.fits.\n\n');
    return;
end

try
    image_handle = fitsread(filename);
    imagesc(image_handle);

catch
    disp(lasterror);
    return;
end



