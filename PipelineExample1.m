% DOT-HUB toolbox Pipeline Example 1.
%
% What follows is an example of a wrapper script that employs the main 
% steps of the toolbox. Most steps output variables into the work
% space and writes them as the key file types, so you can easily comment 
% out steps as you work through them and pick up where you left off, rather
% than re-running every step. The whole script runs in ~12 minutes on a 208
% MacBook Pro with 16Gb RAM.

% Example 1 is the simplest application of the toolbox to LUMO data. It is
% assumed that we have no subject-specific information about the position
% of the optodes (and therefore 3D positioning information is derived from
% the default 3D values in  the LUMOcap .json file) nor do we have
% subject-specific structural MRI; we use an adult atlas.
%
% The dataset is an adult visual eccentricity experiment equivalent to that
% described in Vidal-Rosas et. al. 2021(?) Neurophotonics (in review):
% "Evaluating a new generation of wearable high-density diffuse optical
% tomography technology via retinotopic mapping of the adult visual cortex"
%
% RJC, UCL, Dec 2020.

%% Specify paths of pre-defined elements (.LUMO, atlas .mshs, Homer2 preprocessing .cfg file).
[filepath,~,~] = fileparts(mfilename('fullpath'));
LUMODirName = [filepath '/ExampleData/Example1/Example1_VisualEccentricity.LUMO'];
origMeshFileName = [filepath '/ExampleMeshes/AdultMNI152.mshs'];
cfgFileName = [filepath '/ExampleData/Example1/preproPipelineExample1.cfg'];

%% Covert .LUMO to .nirs
[nirs, nirsFileName, SD3DFileName] = DOTHUB_LUMO2nirs(LUMODirName);

%% Run data quality checks
DOTHUB_dataQualityCheck(nirsFileName);

%disp('Examine data quality figures, press any key to continue');
%pause 

%% Run Homer2 pre-processing pipeline line by line, then write .prepro file:
% dod = hmrIntensity2OD(nirs.d);
% SD3D = enPruneChannels(nirs.d,nirs.SD3D,ones(size(nirs.t)),[0 1e6],12,[0 100],1); 
% dod = hmrBandpassFilt(dod,nirs.t,0,0.5);
% dc = hmrOD2Conc(dod,SD3D,[6 6]);
% dc = DOTHUB_hmrSSRegressionByChannel(dc,SD3D,11,4); %This is a custom SS regression script. 
% [dcAvg,dcAvgStd,tHRF] = hmrBlockAvg(dc,nirs.s,nirs.t,[-5 25]);
% 
% % Use code snippet from DOTHUB_writePREPRO to define contents of logs:
% [pathstr, name, ~] = fileparts(nirsFileName);
% ds = datestr(now,'yyyymmDDHHMMSS');
% preproFileName = fullfile(pathstr,[name '.prepro']);
% logData(1,:) = {'Created on: '; ds};
% logData(2,:) = {'Derived from data: ', nirsFileName};
% logData(3,:) = {'Pre-processed using:', mfilename('fullpath')};
% 
% [prepro, preproFileName] = DOTHUB_writePREPRO(preproFileName,logData,SD3D,tHRF,dodAvg,tHRF,dcAvg,dcStd);

% Alternatively, you can run a Homer2 pipeline based on a .cfg file and
% create a .prepro file automatically using:
[prepro, preproFileName] = DOTHUB_runHomerPrepro(nirsFileName,cfgFileName);

%% Register chosen mesh to subject SD3D and create rmap
[rmap, rmapFileName] = DOTHUB_meshRegistration(nirsFileName,origMeshFileName);
DOTHUB_plotRMAP(rmap)

%% Calculate Jacobian 
basis = [30 30 30];
[jac, jacFileName] = DOTHUB_makeToastJacobian(rmapFileName,basis);

%% Invert Jacobian
%Note that you can either separately calculate the inverse, or just run
%DOTHUB_reconstruction, which will then call the inversion itself
[invjac, invjacFileName] = DOTHUB_invertJacobian(jacFileName,preproFileName,'saveFlag',true,'reconMethod','multispectral','hyperParameter',0.01);

%% Reconstruction
%Reconstruct
[dotimg, dotimgFileName] = DOTHUB_reconstruction(preproFileName,[],invjacFileName,rmapFileName,'saveVolumeImages',true);

%% Display peak response results on atlas surface and in volume
timeRange = [10 15]; %seconds post-onset
fs = length(dotimg.tImg)./range(dotimg.tImg);
frameRange = round((timeRange + abs(min(dotimg.tImg))).*fs);
frames = frameRange(1):frameRange(2);
DOTHUB_plotSurfaceDOTIMG(dotimg,origMeshFileName,frames,'condition',3,'view',[0 20]);
DOTHUB_plotVolumeDOTIMG(dotimg,origMeshFileName,frames);



