% Gregory Poore
% BME 462 Design

%% Make common model and modify parameters

% Setup parameters
zElec = 50; % Ohms
stimStyle = '{ad}'; % '{ad}' == adjacent | '{op}' == opposite
amperage = 1.02; % Amps
dim = 2;
SNR = 3;

imdl = mk_common_model('d2d1c', 20) % of inv_model 2D data structure
%imdl = mk_common_model('b3cr', 20) % of inv_model 3D data structure

imdl.reconst_type = 'difference';
for (i = 1:20)
    imdl.fwd_model.electrode(i).z_contact = [zElec];
end

% Change stimulation and measurement parameters
options = {'meas_current','no_rotate_meas','balance_inj'};
[stim, meas_select] = mk_stim_patterns(20,1,stimStyle,...
    stimStyle,options, amperage);
imdl.fwd_model.stimulation = stim;
imdl.fwd_model.meas_select = meas_select;


%% Make image (i.e. conductivity value expression set)

img = mk_image(imdl);

%% Add 3D marble set and remove 3 to solve forward model

marbleCoord = marbleCoordinates(1/9, dim);
marbleCoordDrop3 = marbleCoord;
marbleCoordDrop3([40,41,48],:) = []; % appears to be X, X+1, X+8 or X+9

DelC1 = 1; % conductivity change of each marble
img.elem_data = 1;
for(i = 1:length(marbleCoordDrop3))
    targets{i} = mk_c2f_circ_mapping(img.fwd_model, ...
        transpose(marbleCoordDrop3(i,:)) )
    img.elem_data = img.elem_data + DelC1*targets{i}(:,1);
end

vi = fwd_solve(img); % this returns the inhomogenous voltage data structure

%% Add noise

% for function
addNoise = 0;
if(addNoise == 1)
    vi = add_noise(SNR, vi);
end

%% Difference EIT solver

% Use Gauss-Newton one step solver for difference EIT

imdl.solve.inv_solve_abs_core.max_iterations =50;
imgr = inv_solve_abs_core(imdl, vi);

%% Plotting

figure(2); clf
h2 = subplot(1,2,1)
show_fem(img)
title('Location of 3 marble removal')

h3 = subplot(1,2,2)
show_fem(imgr)
%image_levels(imgr, [0])
titleString = sprintf('SNR = %0.1f',SNR);
title(titleString);
imgr.calc_colours.cb_shrink_move = [0.3,0.8,-0.02];
common_colourbar([h2 h3],imgr)

suptitle('Absolute EIT Reconstruction When Removing 3 Marbles')

