% Gregory Poore
% BME 462 Design
% Image Reconstruction

%% Initialize

% If you have not already, make sure to load into the EIDROS directory and
% enter 'run startup.m' to initialize the package

% Read in data
% baseline = csvread('BigDaddyDataBaseline1.csv');
% config1  = csvread('BigDaddyDataConfig1.csv');
% config2  = csvread('BigDaddyDataConfig2.csv');

% Setup parameters
zElec = 20; % Ohms
stimStyleInject = '{op}'; % '{ad}' == adjacent | '{op}' == opposite
stimStyleMeasure = '{mono}'; % '{ad}' == adjacent | '{op}' == opposite
amperage = 0.02; % Amps
imagePrior = 'NOSER'; % 'Tik' = Tikhonov, 'NOSER' = NOSER, 'La' = LaPlace, 
% 'none'= Default prior set, 'totVar'.

% Note that many of the priors have preferred hyperparameters, meaning that
% hyperSet should be 'none' unless you have a reason to calculate it using
% the fixed NF method or heuristic.

hyperSet = 'Auto'; % 'H'= Heuristic = 0.01, 'Auto' = automatic selection, 
% 'none'; Note that 'Auto' can take a while to run but has good results
fixedNFValue = 0.4; % only applies when 'Auto' is selected for the 
% hyperSet variable, which uses the fixedNF method
nodalSolve = 'T'; % Solve on FEM triangles or nodes? Nodes are smoother

%% Make mesh and inverse model

% Make model
nElec = 10;
imdl = mk_common_model('d2d1c', nElec); % of inv_model 2D data structure

imdl.reconst_type = 'difference';
for (i = 1:length(nElec))
    imdl.fwd_model.electrode(i).z_contact = [zElec];
end

% Change stimulation and measurement parameters
options = {'meas_current','no_rotate_meas','balance_inj'};
[stim, meas_select] = mk_stim_patterns(nElec,1,...
    stimStyleInject,...
    stimStyleMeasure,...
    options, amperage);
imdl.fwd_model.stimulation = stim;
imdl.fwd_model.meas_select = meas_select;

% Helpful way to check stim and meas pattern matrix:
% full(stim(i).stim_pattern) returns the i-th stimulation pattern in
% column vector format, where the row corresponds to the electrode
% number.
% full(stim(i).meas_pattern) returns the i-th measurement pattern in
% full matrix format, where the row corresponds to the measurement
% number (for that stimulation pair) and the columns correspond to the
% electrode numbers.
% http://sourceforge.net/p/eidors3d/mailman/message/29773983/

%% Convert data to vh and vi matrices

vh = reshape(transpose(baseline),[100,1]);
%vi1 = reshape(transpose(config1),[100,1]);
vi2 = reshape(transpose(config2),[100,1]);

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

%% Image prior and hyperparameter selection
% Note that EIT reconstructions form an ill-poised problem, where there is
% not a unique solution guaranteed. With many possible solutions, the
% one-step Gauss Newton solver uses a regularization method (i.e.
% penalization) by applying certain constraints on the solution. The
% magnitude of the penalization can be determined by the hyperparameter,
% which is listed under the inv_model data structure of the EIDORS program.
% Moreover, image priors (i.e. Bayesian) are utilized to help guide
% the solution of the problem.
%
% It appears that many approach the hyperparameter as a heuristic, but it
% should be made robust if at all possible, especially for field use. A
% good paper on this is called 'Objective Selection of Hyperparameter for
% EIT.' See also:
% http://eidors3d.sourceforge.net/tutorial/EIDORS_basics/tutorial120.shtml

% Set image prior

switch imagePrior
    case 'Tik'
        imdl.hyperparameter.value = 5e-5;
        imdl.RtR_prior=   @prior_tikhonov;
    case 'NOSER'
        imdl.hyperparameter.value = .05;
        imdl.RtR_prior=   @prior_noser;
    case 'La'
        imdl.hyperparameter.value = 6e-3; %1.5e-3 ideal for triplet removal
        imdl.RtR_prior=   @prior_laplace;
    case 'GHPF' % Gauss-HPF Prior
        imdl.RtR_prior=   @prior_gaussian_HPF;
    case 'GLikelihood'
        imdl.RtR_prior=   @prior_gaussian_likelihood;
    case 'totVar' % Total Variance Reconstruction
        imdl.hyperparameter.value = 3e-3;
        imdl.solve=       @inv_solve_TV_pdipm;
        imdl.R_prior=     @prior_TV;
        imdl.parameters.max_iterations= 50;
        imdl.parameters.term_tolerance= 1e-6;
        imdl.parameters.keep_iterations= 1;
    case 'none'
end

% Set hyperparameter value. 

% Note that many of the priors include
% estimated hyperparameters. These can be used by making hyperSet='none' in
% the initialization section, or an automated hyperparameter can be found
% by making hyperSet='Auto'

switch hyperSet
    case 'H' % Heuristic
        imdl.hyperparameter.value= .01;
    case 'Auto'
        % Uses fixed NF method
        imdl.hyperparameter = rmfield(imdl.hyperparameter,'value');
        imdl.hyperparameter.func = @choose_noise_figure;
        % Select the NF value; Graham & Adler (2005) found that a NF=1
        % gave them the lowest blur radius
        imdl.hyperparameter.noise_figure= fixedNFValue;
        imdl.hyperparameter.tgt_elems= 1:4;
    case 'none'
end

%% Difference EIT solver

% Solve at nodes or FEM triangles? Nodes are smoother. Note that this is
% NOT compatible with Total Variance Reconstruction
if(nodalSolve=='T')
    imdl.solve = @nodal_solve;
elseif(nodalSolve=='F')
    imdl.solve=[];
end

% Use Gauss-Newton one step solver for difference EIT
% vi1: clumped; vi2: spread
imgr = inv_solve(imdl, vh, vi2);

%% Plotting
figure(1); clf
subplot(1,2,1)
z = calc_slices(imgr);
c = calc_colours(z);
h = mesh(z,c);
set(h, 'CDataMapping', 'direct' );
view(173,34)

subplot(1,2,2)
show_fem(imgr)
titleString = sprintf('Reconstruction, Amp = %0.2f, %s Stimulation, %s Measure',...
    amperage, stimName, measName);
title(titleString)
colorbar


% figure(2);
% clf
% imgH = subplot(1,2,1)
% show_fem(img)
% title('Location of marble removal')
% 
% imgrH = subplot(1,2,2)
% show_fem(imgr)
% %image_levels(imgr, [0])
% title(titleString);