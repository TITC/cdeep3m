#!/usr/bin/octave -qf
%
% PreprocessTraining
% Makes augmented hdf5 datafiles from raw and label images
%
% Syntax : PreprocessTraining /ImageData/training/images/ /ImageData/training/labels/ /ImageData/augmentedtraining/
%
%
%----------------------------------------------------------------------------------------
%% PreprocessTraining for Deep3M -- NCMIR/NBCR, UCSD -- Author: M Haberl -- Date: 10/2017
%----------------------------------------------------------------------------------------
%
% Adapted to speed up time
% reduced Runtime from >20min for 1024x1024x100 dataset to ~1-2 min
%


% ----------------------------------------------------------------------------------------
%% Initialize
% ----------------------------------------------------------------------------------------
warning("off")
disp('Starting Training data Preprocessing');
pkg load hdf5oct
pkg load image
script_dir = fileparts(make_absolute_filename(program_invocation_name()));
addpath(genpath(script_dir));

arg_list = argv ();
if numel(arg_list)<4; disp('Use -> PreprocessTraining /ImageData/training/images/ /ImageData/training/labels_1/ /ImageData/training/labels_2/ /ImageData/augmentedtraining/'); return; end

tic
trainig_img_path = arg_list{1};
disp('Training Image Path:');disp(trainig_img_path); 
label_1_img_path = arg_list{2};
disp('Training Label_1 Path:');disp(label_1_img_path); 
label_2_img_path = arg_list{3};
disp('Training Label_2 Path:');disp(label_2_img_path); 

outdir = arg_list{4};
disp('Output Path:');disp(outdir); 

% ----------------------------------------------------------------------------------------
%% Load training images
% ----------------------------------------------------------------------------------------

disp('Loading:');
disp(trainig_img_path);
[imgstack] = imageimporter(trainig_img_path);
disp('Verifying images');
checkpoint_nobinary(imgstack);
imgstack(:,:,:,1)=imgstack;
% ----------------------------------------------------------------------------------------
%% Load train data
% ----------------------------------------------------------------------------------------

disp('Loading:');
disp(label_1_img_path);
[lblstack_1] = imageimporter(label_1_img_path);
disp('Verifying labels_1');
checkpoint_isbinary(lblstack_1);


disp('Loading:');
disp(label_2_img_path);
[lblstack_2] = imageimporter(label_2_img_path);
disp('Verifying labels_2');
checkpoint_isbinary(lblstack_2)

% ----------------------------------------------------------------------------------------
%% Check size of images and labels
% ----------------------------------------------------------------------------------------

[imgstack, lblstack_1] = check_img_dims(imgstack, lblstack_1, 325);
[imgstack, lblstack_2] = check_img_dims(imgstack, lblstack_2, 325);

% ----------------------------------------------------------------------------------------

%-----------------------------------------------------------------------------------------
%%merge data (w,h,idx,channel)
lblstack(:,:,:,1)=lblstack_1;
lblstack(:,:,:,2)=lblstack_2;
%-----------------------------------------------------------------------------------------


%% Augment the data, generating 16 versions and save
% ----------------------------------------------------------------------------------------

%imshow(labels_arr(:,:,1))
%data_arr=permute(imgstack,[3 1 2]); %from tiff to h5 /100*1000*1000
%labels_arr=permute(lblstack,[3 1 2]); %from tiff to h5 /100*1000*1000
%[outdir,name,ext] = fileparts(save_file);

img_v1 =single(imgstack);
lb_v1 =single(lblstack);

d_details = '/data';
l_details = '/label';
if ~exist(outdir,'dir'), mkdir(outdir); end
ext = '.h5';

disp('Augmenting training data 1-8 and 9-16'); 
for i=1:8
    %% v1-8
    [img,lb]=augment_data(img_v1,lb_v1,i);
    
    %% v9-16
    inv_img = flip(img,3); %var 9 -16
    inv_lb = flip(lb,3);  %var 9 -16

    %% v1-8
    img=permute(img,[3 1 2 4]); %from tiff to h5 /100*1000*1000
    lb=permute(lb,[3 1 2 4]); %from tiff to h5 /100*1000*1000
    filename = fullfile(outdir, sprintf('training_full_stacks_v%s%s', num2str(i), ext));
    fprintf('Saving: %s\n', filename);
    h5write(filename,d_details,img);
    h5write(filename,l_details,lb);

    clear img lb
    %% v9-16
    inv_img = permute(inv_img,[3 1 2 4]); %from tiff to h5 /100*1000*1000
    inv_lb  = permute(inv_lb,[3 1 2 4]);  %from tiff to h5 /100*1000*1000
    filename = fullfile(outdir, sprintf('training_full_stacks_v%s%s', num2str(i+8), ext));
     fprintf('Saving: %s\n', filename);
    h5write(filename,d_details,inv_img);
    h5write(filename,l_details,inv_lb); 
    clear inv_img inv_lb
end


% ----------------------------------------------------------------------------------------
%% Completed
% ----------------------------------------------------------------------------------------

toc
disp('-> Training data augmentation completed');
fprintf('Training data stored in %s\n', outdir);
fprintf('For training your model please run runtraining.sh %s <desired output directory>\n', outdir);
