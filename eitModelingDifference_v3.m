function [img, imgr, imgH, imgrH] = eitModelingDifference_v3()
% Gregory Poore
% BME 462 Design

%% Make common model and modify parameters

% Setup parameters
zElec = 50; % Ohms
stimStyle = '{op}'; % '{ad}' == adjacent | '{op}' == opposite
amperage = 1.00; % Amps
dim = 2; % 2 for 2D circle, 3 for 3D cylinder
SNR = 4*rand(1);
startNum = 3;
removedMarbleNum = [1, 20, 23, 46, 49]; % appears to be X, X+1, X+8 or X+9
% Saved removal numbers:
% [1, 20, 23, 46, 49] gets rid of 4 corners
% [2, 3, 11] % 

% Make model
nElec = 40;
imdl = mk_common_model('e2d1c', nElec); % of inv_model 2D data structure
%imdl = mk_common_model('b3cr', nElec) % of inv_model 3D data structure

imdl.reconst_type = 'difference';
for (i = 1:length(nElec))
    imdl.fwd_model.electrode(i).z_contact = [zElec];
end

% Change stimulation and measurement parameters
options = {'meas_current','no_rotate_meas','balance_inj'};
[stim, meas_select] = mk_stim_patterns(nElec,1,stimStyle,...
    stimStyle,options, amperage);
imdl.fwd_model.stimulation = stim;
imdl.fwd_model.meas_select = meas_select;


%% Make image (i.e. conductivity value expression set)

img = mk_image(imdl);

%% Add 3D marble set for initial data to solve forward model

marbleCoord = marbleCoordinates(1/9, dim);

DelC1 = 1; % conductivity change of each marble
img.elem_data = 1;
for(i = 1:length(marbleCoord))
    targets{i} = mk_c2f_circ_mapping(img.fwd_model, ...
        transpose(marbleCoord(i,:)) );
    img.elem_data = img.elem_data + DelC1*targets{i}(:,1);
end

vh = fwd_solve(img); % homogenous voltage data struct
imgAllMarbles = img;


%% Remove 3 marbles

%% Add 3D marble set and remove 3 to solve forward model

marbleCoord = marbleCoordinates(1/9, dim);
marbleCoordDrop3 = marbleCoord;
marbleCoordDrop3(removedMarbleNum,:) = [];

DelC1 = 1; % conductivity change of each marble
img.elem_data = 1;
for(i = 1:length(marbleCoordDrop3))
    targets{i} = mk_c2f_circ_mapping(img.fwd_model, ...
        transpose(marbleCoordDrop3(i,:)) );
    img.elem_data = img.elem_data + DelC1*targets{i}(:,1);
end

vi = fwd_solve(img); % this returns the inhomogenous voltage data structure

%% Add noise

% for function
addNoise = 1;
if(addNoise == 1)
    vi = add_noise(SNR, vi, vh);
end

%% Difference EIT solver

% Use Gauss-Newton one step solver for difference EIT

imgr = inv_solve(imdl, vh, vi);

%% Plotting
figure(1); clf
show_fem(imgAllMarbles)
title('FEM Conductivity Map of Hexagonal Marbles')

figure(2); clf
imgH = subplot(1,2,1)
show_fem(img)
title('Location of marble removals')

imgrH = subplot(1,2,2)
show_fem(imgr)
%image_levels(imgr, [0])
titleString = sprintf('SNR = %0.1f, Amp = %0.2f, Adjacent Stimulation',SNR, amperage);
title(titleString);
imgr.calc_colours.cb_shrink_move = [0.3,0.8,-0.02];
common_colourbar([imgH imgrH],imgr)
suptitle('Marble Removal - EIT Difference Reconstruction')


% h3 = subplot(1,3,3)
% show_fem(imgr)
% %image_levels(imgr, [0])
% titleString = sprintf('SNR = %0.1f, Amp = %0.2f, Opposite Stimulation',SNR, amperage);
% title(titleString);
% imgr.calc_colours.cb_shrink_move = [0.3,0.8,-0.02];
% common_colourbar([h2 h3],imgr)
% suptitle('Effect of Simulation Pattern on Difference EIT Reconstruction When Removing 1 Marble')

% h4 = subplot(1,3,3)
% show_fem(imgr)
% %image_levels(imgr, [0])
% titleString = sprintf('SNR = %0.1f, Amp = %0.2f',SNR, amperage);
% title(titleString);
% % imgr.calc_colours.cb_shrink_move = [0.3,0.8,-0.02];
% % common_colourbar([h2 h3 h4],imgr)
% suptitle('Effect of Amperage on Difference EIT Reconstruction When Removing 1 Marble')

