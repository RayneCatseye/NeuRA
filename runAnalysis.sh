#!/bin/bash 

set -e
 
# DTI Script to automate the unpacking and processing stages 
 
function makeLog { 
  location= # Location of the output log file 
 
  # Ensure the file exists 
  mkdir -p ${location} 
  log="${location}/log.txt" 
  touch ${log} 
 
  user=$(whoami) 
  datetime=$(date) 
 
  # Write linebreak and details to file 
  echo "******************************" >> ${log} 
  echo "${user} | ${datetime} | DTI.sh" >> ${log} 
  echo "" >> ${log} 
} 
 
# Iterates over each input argument from the commandline 
if [ $# = 0 ] 
  then 
    echo "Please add patient numbers to be assessed, separated by spaces"
    echo "e.g ${0} 888 999 100_1"
else 
  for num in $@; 
    do 
      makeLog ${num} # Sets the log up for the session 
      ./DTI.sh ${num} 2>&1 | tee -a ${location}"/log.txt" 
      # tee adds all output (including errors) to the log file 
      echo "Analysis of ${num} completed. Please check the output." 
    done 
fi 
