function normalizedData = rescale(data)
% data is a matrix to be rescaled from [-1,1] for machine learning purposes
% Gregory Poore
% Dec 2015

% Find min and max
minVal = min(data(:));
maxVal = max(data(:));

% Calculate normalizedData

normalizedData = ((data-minVal)./(maxVal-minVal) - 0.5)*2;
