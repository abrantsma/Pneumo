function [imgr,vh,vi] = imageReconstruction_v2(csvBaseline,csvAdj,meshComplexity,...
    imagePrior, hyperSet, fixedNFValue, nodalSolve)

% csvBaseline: voltage values with columns being electrodes numbered 1
% through n and rows being oppositely stimulated electrodes beginning with
% 1 & (n/2+1)
% csvAdj: voltage values after conductivity map change; same format as
% csvBaseline
% meshComplexity: integer 1-10, where 1 is the lowest resolution FEM mesh
% and 10 is the highest FEM resolution; note that computing time does NOT
% likely scale linearly 
% imagePrior: Bayesian prior for image reconstruction; options include
% 'Tik', 'NOSER', 'La', 'totVar', 'none'; default is 'none'
% hyperSet: select a lambda hyperparameter to control the degree of
% regularization; options include 'none', Val for heuristic (e.g. 0.01), 
% or 'Auto' for the fixedNF method; default is 'none'
% fixedNFValue: value to iterate to using the fixedNF method
% nodalSolve: 'T' to solve at the nodes or 'F' to solve using the FEM
% triangles; this smoothens the image at low poly values; default is 'T'
% Gregory Poore
% BME 462 Design
% Image Reconstruction

%% Running notes

% - NOSER prior and totVar with their given hyperP work well
% - For Nov20ThreeClumped2Sheet1.csv, fixedNF gave hyperSet = 0.0182

%% Check function inputs

if(nargin==6)
    nodalSolve = 'T';
elseif(nargin==5)
    fixedNFValue = 0.4;
    nodalSolve = 'F'
elseif(nargin==4)
    hyperSet = 'none';
    fixedNFValue = 0.4;
    nodalSolve = 'T';
elseif(nargin==3)
    imagePrior = 'none';
    hyperSet = 'none';
    fixedNFValue = 0.4;
    nodalSolve = 'T';
elseif(nargin==2)
    meshComplexity = 3;
    imagePrior = 'none';
    hyperSet = 'none';
    fixedNFValue = 0.4;
    nodalSolve = 'T';
elseif(nargin<2)
    error('Need to give data to analyze!')
end

meshComplexityOptions = ['a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' 'i' 'j'];
meshChoice = meshComplexityOptions(meshComplexity);
meshString = sprintf('%s2d1c',meshChoice);

%% Initialize

% If you have not already, make sure to load into the EIDROS directory and
% enter 'run startup.m' to initialize the package

% Read in data
baseline = csvread(csvBaseline);
config1  = csvread(csvAdj);

% Setup parameters
zElec = 20; % Ohms
stimStyleInject = '{op}'; % '{ad}' == adjacent | '{op}' == opposite
stimStyleMeasure = '{mono}'; % '{ad}' == adjacent | '{op}' == opposite
amperage = 0.007; % Amps
imagePrior = imagePrior % 'Tik' = Tikhonov, 'NOSER' = NOSER, 'La' = LaPlace, 
% 'none'= Default prior set, 'totVar'.

% Note that many of the priors have preferred hyperparameters, meaning that
% hyperSet should be 'none' unless you have a reason to calculate it using
% the fixed NF method or heuristic.

hyperSet = hyperSet % 'Auto' = automatic selection, Val (e.g. 0.01), or
% 'none'; Note that 'Auto' can take a while to run but has good results
fixedNFValue = fixedNFValue; % only applies when 'Auto' is selected for the 
% hyperSet variable, which uses the fixedNF method
nodalSolve = nodalSolve; % Solve on FEM triangles or nodes? Nodes are smoother

%% Make mesh and inverse model

% Make model
nElec = 20;
imdl = mk_common_model(meshString, nElec); % of inv_model 2D data structure

imdl.reconst_type = 'difference';
for (i = 1:length(nElec))
    imdl.fwd_model.electrode(i).z_contact = [zElec];
end

% Change stimulation and measurement parameters
options = {'meas_current', 'no_balance_inj', 'no_balance_meas'};
[stim, meas_select] = mk_stim_patterns(nElec,1,...
    [0,10],...
    [10],...
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

vh = reshape(transpose(baseline),[400,1]);
vi = reshape(transpose(config1),[400,1]);

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

if(isnumeric(hyperSet))
    imdl.hyperparameter.value = hyperSet;
elseif(hyperSet=='Auto')
    % Uses fixed NF method
    imdl.hyperparameter = rmfield(imdl.hyperparameter,'value');
    imdl.hyperparameter.func = @choose_noise_figure;
    imdl.hyperparameter.noise_figure= fixedNFValue;
    imdl.hyperparameter.tgt_elems= 1:4;
elseif(hyperSet=='none')
    % Nothing
end

%% Difference EIT solver

% Solve at nodes or FEM triangles? Nodes are smoother. Note that this is
% NOT compatible with Total Variance Reconstruction
if(nodalSolve=='T')
    imdl.solve = @nodal_solve;
elseif(nodalSolve=='F')
    % Nothing
end

% Use Gauss-Newton one step solver for difference EIT
imgr = inv_solve(imdl, vh, vi);

%% Plotting
figure(1); clf
% subplot(1,2,1)
% z = calc_slices(imgr);
% c = calc_colours(z);
% h = mesh(z,c);
% set(h, 'CDataMapping', 'direct' );
% view(173,34)
% 
% subplot(1,2,2)
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