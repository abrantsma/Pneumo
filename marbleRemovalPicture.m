function img = marbleRemovalPicture(removedMarbleNum,meshComplexity);
% meshString: integer 1-10 for building FEM based on EIDORS point electrode model
% removedMarbleNum: numbers of which marbles to remove; numbers increase
% upwards in the same column after starting at the middle of the column;
% zero is placed at the dead center and then moves up to the top, then down
% from the bottom, then shift to the right one column and repeat; after
% furthest right column is reached, then move leftward. A proper numbering
% system based on geometry could be implemented if so desired.

% Gregory Poore
% BME 462 Design

%% Make common model and modify parameters

dim = 2; % 2 for 2D circle, 3 for 3D cylinder
%removedMarbleNum = [19, 20, 26]; % appears to be X, X+1, X+8 or X+9
% Saved removal numbers:
% [1, 20, 23, 46, 49] "X" spread through center
% [2, 3, 11] center
% [8,9,17] bottom middle triad
% [19, 20, 26] upper right

% Saved reconstruction values
% BigDataDataConfig1 (clumped): [3,4,12]
% BigDataDataConfig2 (spread): [6 20 45]
% Nov 20 - Clumped 1: [1 2 36]
% Nov 20 - Clumped 2: [3 4 38]
% Nov 20 - Clumped 3: [25 31 32]
% Nov 20 - Spread 1: [16 19 36]
% Nov 20 - Spread 2: [8 9 22 48]
% Nov 20 - Spread 3: [


if(nargin==1)
    meshComplexity = 7;
end

meshComplexityOptions = ['a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' 'i' 'j'];
meshChoice = meshComplexityOptions(meshComplexity);
meshString = sprintf('%s2d0d',meshChoice); % for point electrodes

% Make model
nElec = 20;
imdl = mk_common_model(meshString,nElec); % uses point electrodes in model


%% Make image (i.e. conductivity value expression set)

img = mk_image(imdl);


%% Add 3D marble set and remove 3 to solve forward model

marbleCoordDrop3 = marbleCoordinates_v2(1/9, 1/10, dim);
marbleCoordDrop3(removedMarbleNum,:) = [];

DelC1 = -1; % conductivity change of each marble
img.elem_data = 1;
for(i = 1:length(marbleCoordDrop3))
    targets{i} = mk_c2f_circ_mapping(img.fwd_model, ...
        transpose(marbleCoordDrop3(i,:)) );
    img.elem_data = img.elem_data + DelC1*targets{i}(:,1);
end

%% Plotting
figure(1); clf
subplot(1,2,1)
show_fem(img)
title('Location of marble removal')

