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

echo
echo "We are downloading the client list to work on"


# Read the Username for credentials
echo
#read -p "Please provide your ${red}MH username:${normal}${bold} " vUSERNM

# Download file using SCP to current directory
#echo "${normal}We will download the Client Database file into a temporal location..."
#scp -pq $vUSERNM@10.6.11.11:/mnt/asp/utils/bin/include/ops_webtech_data.txt ./
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
    echo "-------------------------------------------------------------------------------------"
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
    echo "-------------------------------------------------------------------------------------"
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
echo
echo "${bold}NOTE: ${normal}If the above is not correct, please CTRL+C to exit the app and restart it."
echo

# Here we will need to define the actions that we will allow the user to perform
# Generic Action Menu
declare -a vACTIONS=('Data Mining' 'List Patches' 'Execute Audits Listing' 'Review CRON')

# Data Mining Sub Menu
declare -a vACTION_DATAMINING=('Access Logs' 'Bb Services' 'Bb SQL')
# other submenus ----


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
    echo "-------------------------------------------------------------------------------------"
    echo "${bold}${red}ERROR:${normal} Invalid option, please try again."
    echo "-------------------------------------------------------------------------------------"
    echo
  fi

done

# STEP 3: Display sub menu depending on action
# set the sub Menu
echo "${vACTIONS[$vACTIONID]}"



# Ask for a specific date in regular expresion to search for
vCURDATE=`date +%Y-%m-%d`
read -p "Input the ${red}Date${normal} you want to search (YYYY-MM-DD): ${bold}" vSTARTDATE
#read -p "Input the ${red}End Date${normal} you want to search (YYYY-MM-DD): ${bold}" vENDDATE
echo "${normal}"


# Set up the path and the date to search for.
# Since we don't know when the archived logs occurred, we are searching in the archived and current locations
vDATE=""
vPATH=""
if [[ $vCURDATE -eq $vSTARTDATE ]]; then
	vDATE="."$vCURDATE".txt"
else
	vDATE="."$vCURDATE".txt.gz"
fi


# Ask what user pk1 to search for
read -p "Input the ${red}User PK1${normal} you want to search (example: 284407): ${bold}" vUSERPK1
echo "${normal}"



# Connect to server
vCOUNTER=0
for h in "${vAPPSIP[@]}";
do
	echo "Connecting to ${vAPPS[$vCOUNTER]}"
	ssh  -o StrictHostKeyChecking=no $vUSERNM@$h zgrep --color=auto -H $vUSERPK1 /usr/local/blackboard/logs/tomcat/bb-access-log$vDATE | awk '{print $1, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18}'
	ssh  -o StrictHostKeyChecking=no $vUSERNM@$h grep --color=auto -H $vUSERPK1 /usr/local/blackboard/asp/*/tomcat/bb-access-log$vDATE | awk '{print $1, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18}'
	echo "Disconnecting from ${vAPPS[$vCOUNTER]}"
	echo "---------------------"
	echo ""
	vCOUNTER=$[$vCOUNTER +1]
done
