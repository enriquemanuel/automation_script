#!/bin/sh

## Enhancement requests
## - Add a debug mode.

## ToDo's
## -------------------
## Search in date range
## Be more efficient in searches to only search the required directory (archived or not)
## Add different logs to search
## Maybe store the password locally to not ask for it for every connection
## Don't connect to DBs to search

## Done
## -------------------
## 2016-05-24 - Modified the colors to work only with tput instead of HEX
## 2016-05-24 - Release V1.02
## 2016-05-24 - Ability to search all Opsmart Clients and list them
## 2016-05-23 - Ability to connect using user provided credentials. Not storing them in any way.
## 2016-05-20 - Beta release date. Written by Enrique Valenzuela

## Before we get started, make sure this is being run from a writeable location.

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)
vFILENAME='ops_webtech_data.txt'

######### FUNCTIONS #############
function connect2ssh (){
  declare -a hosts=("${@}")
  for h in  "${hosts[@]}"
  do
    echo -n $h

    # ssh -t xxx
  done
}

function ifDataMiningRemoveDB (){
  declare -a hosts=("${@}");
  declare -a temphosts=();
  for h in "${hosts[@]}"
  do
    if [[ ${h} != *"db0"* ]]; then
      temphosts+=($h);
    fi
  done
  echo ${temphosts[@]}
}

function trap2exit (){

  echo "\n${normal}Exiting...";
  if [[ -f $vFILENAME ]]; then
    rm -rf $vFILENAME
  fi
  exit 0;
}

# remove file if user is doing CNTRL+C
trap trap2exit SIGHUP SIGINT SIGTERM


vFILENAME='ops_webtech_data.txt'

echo
echo "We are downloading the client list to work on"


# Read the Username for credentials
echo
#read -p "Please provide your ${red}MH username:${normal}${bold} " vUSERNM

# Download file using SCP to current directory
#echo "${normal}We will download the Client Database file into a temporal location..."
#scp -pq $vUSERNM@10.6.11.11:/mnt/asp/utils/bin/include/$vFILENAME ./
scp -pq evalenzuela@10.6.11.11:/mnt/asp/utils/bin/include/$vFILENAME ./
#echo "File downloaded."

# Security Loop
# Get Input of Client and Environment
# If nothing is found then ask again.
until ((0));
do
  # Ask for Client Name
  read -p "${normal}What ${red}client${normal}  do you want to work on: ${bold}" vCLIENTNAME
  # Ask for Environment type (Production or Staging or Test)
  read -p "${normal}What ${red}environment${normal} do you want to work on (Production, Staging, Test...): ${bold}" vENVIRONMENT
  echo "${normal}"

  vOPTIONS=($(grep --color=auto -i "$vCLIENTNAME" $vFILENAME | grep --color=auto -i $vENVIRONMENT | awk 'BEGIN { FS = "\t" } ; {print $14}' | sort | uniq))

  if [ ${#vOPTIONS[@]} -eq 0 ]; then
    echo "${normal} -------------------------------------------------------------------------------------"
    echo "${bold}${red}ERROR:${normal} We could not found any information with your parameters, please try again."
    echo "-------------------------------------------------------------------------------------"
    echo
  else
    echo "${green}We found this options: ${normal}"
    vCOUNTER=0
    for i in "${vOPTIONS[@]}"
    do
      echo "$vCOUNTER) $i"
      vCOUNTER=$[$vCOUNTER +1]
    done
    echo
    break
  fi
done


# Ask to select one of the options above
until ((0));
do
  # Ask to select one of the options above
  read -p "Input the above ${red}id number${normal} you want to work on: ${bold}" vARRAYID
  # Set the Working url
  vWORKINGURL=${vOPTIONS[$vARRAYID]}

  if  [[ "$vWORKINGURL" == "" ]]; then
    echo "${normal} -------------------------------------------------------------------------------------"
    echo "${bold}${red}ERROR:${normal} Invalid option, please try again."
    echo "-------------------------------------------------------------------------------------"
    echo
  else
    break
  fi
done

# Now lets find the App Servers to work
vAPPS=($(grep --color=auto -i "$vCLIENTNAME" $vFILENAME | grep --color=auto -i $vENVIRONMENT | grep --color=auto -i $vWORKINGURL | awk 'BEGIN { FS="\t"}; {print $3}' | sed  's/_/-/g'))
vAPPSIP=($(grep --color=auto -i "$vCLIENTNAME" $vFILENAME | grep --color=auto -i $vENVIRONMENT | grep --color=auto -i $vWORKINGURL | awk 'BEGIN { FS="\t"}; {print $1}'))
# deleting the file so we are always up to date
#rm -rf $vFILENAME


# Display the list of serverst that we found based on their criteria
echo "${normal}We found the following Apps to work based on your input: "
vCOUNTER=1
for servername in "${vAPPS[@]}"
do
  echo "$vCOUNTER) $servername"
  vCOUNTER=$[$vCOUNTER +1]
done

# Here we will need to define the actions that we will allow the user to perform
# Generic Action Menu
declare -a vACTIONS=('Data Mining' 'List Patches' 'Execute Audits Listing (APP)' 'Execute Audits Listing (DB)' 'Review CRON' 'Custom')


# We should have a multiple step process
# Step 1: List Actions
# Step 2: Confirm Action
# Step 3: Display submenu options depending on the action
# Step 4: Confirm Sub action

# STEP 1: Display the list of possible actions
echo "${normal}What ${red}Action${normal} would you like to execute"
vCOUNTER=0
for action in "${vACTIONS[@]}"
do
  echo "$vCOUNTER) $action"
  vCOUNTER=$[$vCOUNTER +1]
done
echo

# STEP 2: Get the Action selected by the user
# Check if selected value exists if not make him try again
vTEMPVAR=0
until ((0));
do
  read -p "Input the above ${red}id number${normal} of the action you want to perform: ${bold}" vACTIONID
  var=${vACTIONS[$vACTIONID]}
  for item in "${vACTIONS[@]}"; do
    if [[ $var == "$item" ]]; then
      vTEMPVAR=1
      continue
    fi
  done
  if [[ $vTEMPVAR == 1 ]]; then
    break
  else
    echo "${normal} -------------------------------------------------------------------------------------"
    echo "${bold}${red}ERROR:${normal} Invalid option, please try again."
    echo "-------------------------------------------------------------------------------------"
    echo
  fi
done
echo

# call to function
result=$(ifDataMiningRemoveDB ${vAPPS[@]})



# STEP 3: Display sub menu depending on action
# set the sub Menu
vSELECTEDACTION="${vACTIONS[$vACTIONID]}"

# Data Mining
# Multi Step process
# 1. Validate if its Data Mining
# 2. Display the available logs at this time
##### Data Mining Sub Menu
declare -a vACTION_DATAMINING=('Access Logs' 'Bb Services' 'Bb SQL')
# 3. Request Start Date
# 4. Request End Date (not yet implemented)
# 5.
if [[ "$vSELECTEDACTION" == "Data Mining" ]]; then
  # ask the user what log they want to look at
  echo "${normal}What ${red}LOG${normal} do you want to grep today:"
  vCOUNTER=0
  for log in "${vACTION_DATAMINING[@]}"
  do
    echo "$vCOUNTER) $log"
    vCOUNTER=$[$vCOUNTER +1]
  done
  echo

  until ((0));
  do
    read -p "Input the above ${red}id number${normal} of the LOG you want to perform: ${bold}" vLOGID
    var=${vACTION_DATAMINING[$vLOGID]}
    vTEMPVAR=0
    for item in "${vACTION_DATAMINING[@]}"; do
      if [[ $var == "$item" ]]; then
        vTEMPVAR=1
        continue
      fi
    done
    if [[ $vTEMPVAR == 1 ]]; then
      break
    else
      echo "${normal} -------------------------------------------------------------------------------------"
      echo "${bold}${red}ERROR:${normal} Invalid option, please try again."
      echo "-------------------------------------------------------------------------------------"
      echo
    fi
  done


  # Data Mining, so need a loop for all the information
  vCURDATE=`date +%Y-%m-%d`
  read -p "Input the ${red}Date${normal} you want to search (YYYY-MM-DD): ${bold}" vSTARTDATE
  # need to get date range
  # future function
  #read -p "Input the ${red}End Date${normal} you want to search (YYYY-MM-DD): ${bold}" vENDDATE

  # Set up the path and the date to search for.
  # Since we don't know when the archived logs occurred, we are searching in the archived and current locations
  vDATE=""
  vPATH=""
  if [[ $vCURDATE -eq $vSTARTDATE ]]; then
  	vDATE="."$vCURDATE".txt"
  else
  	vDATE="."$vCURDATE".txt.gz"
  fi


elif [[ "$vSELECTEDACTION" == "List Patches" ]]; then
  echo "User Election chose List Patches"
elif [[ "$vSELECTEDACTION" == "List Patches" ]]; then
  echo "User Election chose List Patches"
elif [[ "$vSELECTEDACTION" == "Execute Audits Listing" ]]; then
  echo "User Election chose Execute Audits Listing"
elif [[ "$vSELECTEDACTION" == "Review CRON" ]]; then
  echo "User Election chose Review CRON"
elif [[ "$vSELECTEDACTION" == "Custom" ]]; then
  echo "User Election chose Custom"
fi
