#!/usr/bin/octave -qf
% Merge LargeData
%
% After segmentation of smaller image packages this
% script will stitch the initial dataset back together
% Assumes Packages are in the subdirectories of 1fm / 3fm / 5fm
% an expects a de_augmentation_info.mat in the parent directory thereof.
%
% Runs after StartPostProcessing which merges the 16variations
% and already removed z-padding.
%
%
% Use: Merge_LargeData ~/prediction/1fm
% expects de_augmentation_info.mat in the parent directory
%
%------------------------------------------------------------------
%% NCMIR/NBCR, UCSD -- Author: M Haberl -- Date: 10/2017
%------------------------------------------------------------------

disp('Starting to merge large image dataset');
pkg load image
script_dir = fileparts(make_absolute_filename(program_invocation_name()));
addpath(genpath(script_dir));
addpath(genpath(strcat(script_dir,filesep(),'scripts',filesep())));
addpath(genpath(strcat(script_dir,filesep(),'scripts',filesep(),'functions')));

arg_list = argv ();

if numel(arg_list) == 0;
disp('Use -> Merge_LargeData ~/prediction/1fm'); 
return;
else  
 fm_dir = arg_list{1};   
end

tic
if fm_dir(end)==filesep; fm_dir=fm_dir(1:end-1); end %fixing special case which can cause error
[parent_dir,~,ext] = fileparts(fm_dir);
de_aug_file = fullfile(parent_dir,'de_augmentation_info.mat');
disp('Processing:');disp(de_aug_file); 
load(de_aug_file,'packages','num_of_pkg','imagesize','zplanes','z_blocks');

%% Merge Z-sections   
 % first combine images from the same x/y areas through all z-planes
 disp('Combining image stacks');
     for x_y_num = 1:numel(packages)
         imcounter = 0; %Reset imagecounter to combine next Package
         combined_folder = fullfile(fm_dir, sprintf('Pkg_%03d',x_y_num));
         mkdir(combined_folder);
         for z_plane = 1:(numel(z_blocks)-1)
             in_folder = fullfile(fm_dir, sprintf('Pkg%03d_Z%02d',x_y_num, z_plane));
             disp(['Reading:', in_folder]);
             imlist =  read_files_in_folder(in_folder);
             imlist =  filter_files(imlist,'.png');
             for file = 1:numel(imlist)
                 imcounter = imcounter + 1;
                 in_filename = fullfile(in_folder,imlist(file).name);
                 out_filename = fullfile(combined_folder, sprintf('segmentation_%04d.png', imcounter));
                 movefile(in_filename, out_filename);
             end
             
         end
     end

z_found = numel(filter_files(read_files_in_folder(fullfile(fm_dir, sprintf('Pkg_001'))),'.png'));
fprintf('Expected number of planes: %s ... Found: %s planes\n', num2str(z_blocks(end)),num2str(z_found));
%% Now stitch individual sections
combined_folder = fullfile(fm_dir, sprintf('Pkg_%03d',1)); %read in the filenames of the first Pkg
filelist = read_files_in_folder(combined_folder);
for z_plane = 1:z_found %one z-plane at a time
fprintf('Merging image no. %s\n', num2str(z_plane));

for x_y_num = 1:numel(packages)
packagedir = fullfile(fm_dir, sprintf('Pkg_%03d',x_y_num));
filename = fullfile(packagedir, filelist(z_plane).name);
image_patch = (NaN(imagesize(1:2),'single')); %Initialize empty image inx/y not z

small_patch = single(imread(filename));
small_patch = single((255 /max(small_patch(:)))*small_patch);
area = packages{x_y_num};
if numel(packages)>1
insertsize = [(area(2)+1)-area(1),(area(4)+1)-area(3)];
if area(1)==1;small_patch = small_patch(13:end,:); end
if area(3)==1;small_patch = small_patch(:,13:end); end

image_patch(area(1):area(2),area(3):area(4)) = small_patch(1:insertsize(1),1:insertsize(2)); %insert image onto NaN blank image

else %if there is only one package
if imagesize(1)<=1012, start(1) = 13;else, start(1) = 1;end %define where the image has been padded
if imagesize(2)<=1012, start(2) = 13;else, start(2) = 1;end %define where the image has been padded
image_patch = small_patch(start(1):imagesize(1),start(2):imagesize(2));    
end

image_stack(:,:,x_y_num) = single(image_patch);
end

combined_plane = nanmean(image_stack,3);
save_plane = uint8((255 /max(combined_plane(:)))*combined_plane);
outfile = fullfile(fm_dir, sprintf('Segmented_%04d.png',z_plane));
%fprintf('Saving image %s\n', outfile);
imwrite(save_plane,outfile);

end
disp('Merging large image dataset completed');
toc
fprintf('Your results are in: %s\n', fm_dir);
