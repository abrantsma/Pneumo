function hexagonArrayOutput = hexagonCoordinates(numMarbleOnDiameter,...
    scalingFactor, totalRadius, dimensions)
% numMarbleOnDiameter: number of marbles at maximum diameter; must be an 
% odd integer
% scalingFactor: if 1, the marbles will touch; if <1, the marbles will be
% in their correction positions with some space between them (default is 1)
% totalRadius: total radius of circled measured system (default is 1)
% dimensions: 2 for 2D marble cross-sections, 3 for 3D spheres (default is
% 2)

%% Check for bad inputs

if(nargin<4)
    dimensions = 2;
elseif(nargin<3)
    totalDiameter = 1;
    dimensions = 2;
elseif(nargin<2)
    scalingFactor = 1;
    totalDiameter = 1;
    dimensions = 2;
end

if(mod(numMarbleOnDiameter,2)==0)
    error('Number of marbles on diameter must be odd')
end

%% Make array of hexagonal locations

% EIDORS input is [xloc yloc zloc radius]
% first marble is at [0,0,0] location

% Setup for finding hexagonal perimeter
numMarbleOnRadius = (numMarbleOnDiameter+1)/2; % inclusive of first marble
perimeterMarbleNumber = repmat(1,numMarbleOnRadius); % create blank matrix

% For loop calculates number of marbles on each hexagonal perimeter
for(i=1:numMarbleOnRadius)
    perimeterMarbleNumber(i) = 6*(i-1);
    
    if(perimeterMarbleNumber(i)==0)
        perimeterMarbleNumber(i)=1;
    end
end

%hexagonArrayOutput = zeros(sum(perimeterMarbleNumber),4);
% Setup for calculating array
marbleArray = cell(numMarbleOnRadius,1); % store in cell to concat later
hexMarbleRadius = totalRadius/numMarbleOnDiameter; % gives number of radii 
% from center to edge of circle

% Double for loop to create array of hexagonal locations
for(i=1:numMarbleOnRadius)
    for(j=1:perimeterMarbleNumber(i))
        radAngles = linspace(0,2*pi, perimeterMarbleNumber(i));
        
        


end


