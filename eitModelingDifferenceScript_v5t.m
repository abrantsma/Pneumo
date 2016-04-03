% Gregory Poore
% BME 462 Design

% Time Everything:
tic()

%% Make common model and modify parameters

% Setup parameters
zElec = 50; % Ohms
stimStyleInject = '{op}'; % '{ad}' == adjacent | '{op}' == opposite
stimStyleMeasure = '{mono}'; % '{ad}' == adjacent | '{op}' == opposite
amperage = 0.020; % Amps
dim = 2; % 2 for 2D circle, 3 for 3D cylinder
SNR = 3; %4*rand(1);
startNum = 3;
removedMarbleNum = [19, 20, 26]; % appears to be X, X+1, X+8 or X+9
% Saved removal numbers:
% [1, 20, 23, 46, 49] "X"
% [2, 3, 11] center
% [8,9,17] bottom middle triad
% [19, 20, 26] upper right

t1 = toc()

% Make model
nElec = 20;
load common_model1; % of inv_model 2D data structure
%imdl = mk_common_model('b3cr', nElec) % of inv_model 3D data structure
t1a = toc()
imdl.reconst_type = 'difference';
for (i = 1:length(nElec))
    imdl.fwd_model.electrode(i).z_contact = [zElec];
end

t2 = toc()

% Change stimulation and measurement parameters
options = {'meas_current','no_rotate_meas','balance_inj'};
[stim, meas_select] = mk_stim_patterns(nElec,1,...
    [1,11],...
    [1],...
    options, amperage);
imdl.fwd_model.stimulation = stim;
imdl.fwd_model.meas_select = meas_select;

t3 = toc()

%% Make image (i.e. conductivity value expression set)

img = mk_image(imdl);
imgNoMarbles = img;
% figure(); clf
% show_fem(imgNoMarbles)
% title('FEM Mesh with 13164 Nodes')

t4 = toc()

%% Add 3D marble set for initial data to solve forward model

marbleCoord = marbleCoordinates_v2(1/9, 1/10, dim);

t5 = toc()

DelC1 = -1; % conductivity change of each marble
img.elem_data = 1;
targets = cell(1, length(marbleCoord));
transposed_marbleCoord = transpose(marbleCoord);
transposed_cells_of_marbleCoord = num2cell(transposed_marbleCoord, 1);
targets = parcellfun(4, @(xyzr)mk_c2f_circ_mapping(img.fwd_model, xyzr), transposed_cells_of_marbleCoord, octavez"UniformOutput", false);
t5a = toc()
for(i = 1:length(marbleCoord))
    img.elem_data = img.elem_data + DelC1*targets{i}(:,1);
end

t6 = toc()

vh = fwd_solve(img); % homogenous voltage data struct
imgAllMarbles = img;

t7 = toc()

%% Add 3D marble set and remove 3 to solve forward model

marbleCoordDrop3 = marbleCoord;
marbleCoordDrop3(removedMarbleNum,:) = [];

t8 = toc()

DelC1 = -1; % conductivity change of each marble
img.elem_data = 1;
targets = cell(1, length(marbleCoord));
transposed_marbleCoordDrop3 = transpose(marbleCoordDrop3);
transposed_cells_of_marbleCoordDrop3 = num2cell(transposed_marbleCoordDrop3, 1);
targets = parcellfun(4, @(xyzr)mk_c2f_circ_mapping(img.fwd_model, xyzr), transposed_cells_of_marbleCoordDrop3, "UniformOutput", false);
t8a = toc()
for(i = 1:length(marbleCoordDrop3))
    img.elem_data = img.elem_data + DelC1*targets{i}(:,1);
end

t9 = toc()

vi = fwd_solve(img); % this returns the inhomogenous voltage data structure

t10 = toc()

%% Add noise

% for function
addNoise = 1;
if(addNoise == 1)
    vi = add_noise(SNR, vi, vh);
end

t11 = toc()

%% Detect measurement and stimulation pattern

switch stimStyleInject
    case '{ad}'
        stimName = 'Adjacent';
    case '{op}'
        stimName = 'Opposite';
    case '{mono}'
        stimName = 'Monopole';
end

switch stimStyleMeasure
    case '{ad}'
        measName = 'Adjacent';
    case '{op}'
        measName = 'Opposite';
    case '{mono}'
        measName = 'Monopole';
end

t12 = toc()

%% Difference EIT solver

% Use Gauss-Newton one step solver for difference EIT

imgr = inv_solve(imdl, vh, vi);

t13 = toc()

%% Plotting
% figure(1); clf
% show_fem(imgAllMarbles)
% title('FEM Conductivity Map of Hexagonal Marbles')
titleString = sprintf('SNR = %0.1f, Amp = %0.2f, %s Stimulation, %s Measure',...
    SNR, amperage, stimName, measName);

figure(2);
clf
imgH = subplot(1,2,1)
show_fem(img)
title('Location of marble removal')

t14 = toc()

imgrH = subplot(1,2,2)
show_fem(imgr)
%image_levels(imgr, [0])
title(titleString);

t15 = toc()

% imgrG = subplot(1,3,3)
% show_fem(imgr)
% %image_levels(imgr, [0])
% titleString = sprintf('SNR = %0.1f, Amp = %0.2f, Opposite Stimulation',SNR, amperage);
% title(titleString);
% imgr.calc_colours.cb_shrink_move = [0.3,0.8,-0.02];
% common_colourbar([imgH imgrH imgrG],imgr)
% suptitle('Marble Removal - EIT Difference Reconstruction')







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

