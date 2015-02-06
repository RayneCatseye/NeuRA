#!/bin/bash
set -e

# DTI Script to automate the unpacking and processing stages

# Performs fetching and analysis of the brain images
# Should probably be broken down into subfunctions at some stage
# Input: ${1}=number to be analysed
# Make the orig folder
echo "Making the orig folder."
origin="/subjects/${1}/mri/orig/"
mkdir -p ${origin}
echo "Done."

# Create symbolic links between the raw MRI data and the orig folder
echo "Creating symbolic links to raw MRI data."
ln -sv /${1}/NIFTI/3DCORT1CLEAR.nii.gz ${origin}
ln -sv /${1}/NIFTI/3DCORT1CLEAR2CLEAR.nii.gz ${origin}
echo "Done"

# Run mri_convert (|| : is error handling)
echo "Running mri_convert on both data batches."
mri_convert ${origin}3DCORT1CLEAR.nii.gz ${origin}001.mgz || echo "Conversion of 001.mgz failed."
mri_convert ${origin}3DCORT1CLEAR2CLEAR.nii.gz ${origin}002.mgz || echo "Conversion of 002.mgz failed."
# There may be only 1 T1, but that's okay.
echo "Done."

location="/mridata/workingdata/HIV/subjects/"

# Run autoreconbatch
echo "Running autoreconbatch."
cd ${location};
for i in "${1}";
do
 echo "$i";
 recon-all -all -s $i;
done
echo "Done"

# create analysis directory
echo "Making DTI working directory."
working_dir="${location}${1}/DTI/analyze/DTI_${1}_1"
mkdir -p ${working_dir}
echo "Done."

# copy the DTI files from the archive to the new directory
echo "Copying DTI file."
newDir=${working_dir}/DTI_${1}_1
fslsplit /mridata/scans/HIV/${1}/NIFTI/xDTiAxialSENSE.nii.gz ${newDir} -t
echo "Done."

# Unzip the .gzip file
echo "Unzipping file."
gunzip "${working_dir}/DTI*.gz"
echo "Done."

# Change permissions to be accessible to all
chmod 775 ${working_dir}/DTI*

# Copy b0 up one level
cp ${working_dir}/DTI_${1}_10000.nii ${working_dir}/../b0DTI_${1}_10000.nii

# Calls BET (Brain Extraction Tool) on the .nii file
echo "Calling the BET."
bet ${working_dir}/DTI_${1}_10000.nii ${working_dir}/DTI_${1}_mask -f 0.2 -g -0.1 -v -m
echo "Done."

# Unzip and modify permissions on the mask file
gunzip ${working_dir}/DTI_${1}_mask_mask.nii.gz
chmod 777 ${working_dir}/DTI_${1}_mask_mask.nii

# Change filetype for all .nii files
echo "Changing filetypes."
for i in $(ls ${working_dir}/*.nii);
  do
    fslchfiletype ANALYZE ${i} ${i};
  done

for i in $(ls ${working_dir}/*.nii);
  do
    rm ${i};
  done
echo "Done."

# Change permissions of the newly created files
chmod 777 ${working_dir}/DTI*
