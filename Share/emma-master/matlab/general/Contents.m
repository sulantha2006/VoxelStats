% EMMA - general medical image analysis tool ($Name:  $)
%
% High-level MINC I/O functions
%   openimage     - Open an image volume stored in a MINC file.
%   newimage      - Create a new MINC file.
%   getimageinfo  - Get information about an opened MINC file.
%   getimages     - Get whole or partial images from an open MINC file.
%   putimages     - Put whole images into a MINC file created with newimage.
%   getblooddata  - Get blood data associated with a dynamic PET study.
%   getmask       - Interactively calculate a threshold mask.
%   resampleblood - Get resampled blood data from a data set.
%   closeimage    - Close an image volume.
%
% Low-level (CMEX or standalone executables) MINC I/O functions
%
%   mireadimages  - Read images from a MINC file (used by getimages).
%   mireadvar     - Read a hyperslab from any NetCDF variable.
%   micreate      - Create a new MINC file from scratch.
%   miwriteimages - Write images to a MINC file (used by putimages).
%   miinquire     - Get netCDF variable, dimension, or attribute information.
%
%     Note: these seven functions should not generally be called by 
%     general purpose image analysis applications.  Use the high-
%     level functions instead.
%
% General utility functions (numeric)
%   deriv         - Calculate the derivative of a numerical function.
%   lookup        - Fast CMEX function for linear interpolation.
%   nconv         - Convolution of two vectors with not necessarily unit spacing.
%   nfmins        - Minimize a function of several variables.
%   nframeint     - Fast CMEX integration across frames.
%   ntrapz        - Fast CMEX function for trapezoidal integration.
%   rescale       - Multiply a matrix by a scalar.
%   
% General utility functions (image processing)
%   getmask       - Returns a mask that is the same size as the passed image.
%   getpixel      - Use this instead of ginput.
%   gettaggedhist - Get a histogram of tagged points within a volume.
%   getvolumehist - Get a histogram of a volume.
%   hotmetal      - Generate the RGB numbers for a hotmetal colourmap.
%   maketac       - Generate a time-activity curve from a set of data.
%   smooth        - Perform a simple spatial smoothing on an image.
%   spectral      - Generate the RGB numbers for a spectral colourmap.
%   
% General utility (image volume geometry, tag and transform files)
%   loadtagfile   - Load coordinates from an MNI tag file.
%   viewimage     - View an image.
%   getvoxeltoworld - Compute the raw voxel-to-world transform for a volume.
%   worldtovoxel  - Convert world coordinates to voxel coordinates.
%   voxeltoworld  - Convert voxel coordinates to world coordinates.
%   pixelindex    - Generate a vector index for a point in an image vector.
%   gettaggedregion - Read all voxel values in a labelled volume.
%
% rCBF analysis functions
%   rcbfanalysis  - Perform two compartment rCBF analysis, and write out
%                   K1 and V0 in MINC files.
%   rcbfdemo      - Demonstrates the RCBF blood analysis package.
%   rcbf1         - Performs a single compartment rCBF analysis.
%   rcbf2         - Performs a full two compartment rCBF analysis, with
%                   blood dispersion and delay correction.
%
% Rat Data Analysis
%   ratbrain      - Analyze rat data.
%   ratdemo       - Rat data analysis demo.
%
% Region of Interest (ROI) functions
%   drawboxroi    - Draw a simple box ROI
%   drawpolyroi   - Draw a general polygonal ROI
%   drawroi       - Draws a given ROI on a given figure
%   getroi        - Get the normalized vertices of a ROI
%   makeroimask   - Create a mask from a set of ROIs
%   transferroi   - Copies ROIs from one figure to another

% $Id: Contents.m,v 1.14 1997-10-21 20:37:38 greg Rel $
