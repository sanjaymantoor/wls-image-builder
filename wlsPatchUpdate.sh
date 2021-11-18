#!/bin/bash
# This script does patch updates to WLS 

#Function to output message to StdErr
function echo_stderr ()
{
    echo "$@" >&2
}

#Function to display usage message
function usage()
{
  echo_stderr "./wlsPatchUpdate.sh <<< <parameters>"
}

#Function to cleanup all temporary files
function cleanup()
{
    echo "Cleaning up temporary files..."
    sudo rm -rf ${wlsPatchWork}
}

function downloadUsingWget()
{
	sudo mkdir -p ${wlsPatchWork}
	sudo rm -rf ${wlsPatchWork}/*
	
	filename=${downloadURL##*/}
	for in in {1..5}
	do
		cd ${wlsPatchWork}
		wget $downloadURL
		if [ $? != 0 ];
     	then
        	echo "${filename} patch download failed with $downloadURL. Trying again..."
			sudo rm -f $filename
     	else 
        	echo "${filename} patch downloaded successfully"
        break
     fi
   done
   
}

function updatePatch()
{
	cd ${wlsPatchWork}
	echo "WLS patch details before applying patch"
	runuser -l oracle -c "$oracleHome/OPatch/opatch lspatches"
	filename=${downloadURL##*/}
	unzip $filename
	sudo chown -R $username:$groupname ${wlsPatchWork}
	sudo chmod -R 755 ${wlsPatchWork}
	#Check whether it is bundle patch
	patchListFile=`find . -name linux64_patchlist.txt`
	ls -lt ${patchListFile}
	if [[ "${patchListFile}" == *"linux64_patchlist.txt"* ]]; 
	then
		echo "Applying Stack Patch Bundle"
		command="${oracleHome}/OPatch/opatch napply -silent -oh ${oracleHome}  -phBaseFile linux64_patchlist.txt"
		echo $command
		runuser -l oracle -c "cd ${wlsPatchWork}/*/binary_patches ; ${command}"
	else
		echo "Applying regular wls patch"
		cd *
		command="${oracleHome}/OPatch/opatch apply -silent"
		echo $command
		runuser -l oracle -c "${command}"
	fi
	echo "WLS patch details after applying patch"
	runuser -l oracle -c "$oracleHome/OPatch/opatch lspatches"
}


#main script starts here

read downloadURL

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(readlink -f ${CURR_DIR})"
oracleHome="/u01/app/wls/install/oracle/middleware/oracle_home"
wlsPatchWork="/u01/app/wlspatch"
groupname="oracle"
username="oracle"

if [ $downloadURL != "none" ];
then
	downloadUsingWget
	updatePatch
	cleanup
fi
