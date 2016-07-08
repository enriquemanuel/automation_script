#!/bin/sh
#title           :automator.sh
#description     :This script will do Data mining on the Tomcat Access Logs.
#author		       :enriquemanuel.me (Enrique Valenzuela) - https://github.com/enriquemanuel/
#date            :2016-06-13
#version         :0.8
#usage           :sh automator.sh

#==============================================================================

## 2016-05-20 - Beta release date.
## Written by Enrique Valenzuela

## Before we get started, make sure this is being run from a writeable location.
cwd=`pwd`
if [ ! -w "$cwd" ]; then
  echo "${red}${bold}Error:${normal} Current Directory is not writeable by you."
  exit 0
fi

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)

vFILENAME='ops_webtech_data.txt'
declare -a vDATERANGE=()
echo
echo "We are downloading the client list to work on"

# some back up functions
function trap2exit (){

  echo "\n${normal}Exiting...";
  if [[ -f $vFILENAME ]]; then
    rm -rf $vFILENAME
  fi
  exit 0;
}


# Read the Username for credentials
trap trap2exit SIGHUP SIGINT SIGTERM
echo
read -p "Please provide your ${red}MH username:${normal}${bold} " vUSERNM

# Download file using SCP to current directory
echo "${normal}We will download the Client Database file into a temporal location..."
scp -pq $vUSERNM@10.6.11.11:/mnt/asp/utils/bin/include/ops_webtech_data.txt ./
echo
echo ">>> File downloaded ..."
echo

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
vTEMPAPPS=($(grep --color=auto -i "$vCLIENTNAME" $vFILENAME | grep --color=auto -i $vENVIRONMENT | grep --color=auto -i $vWORKINGURL | awk 'BEGIN { FS="\t"}; {print $3}' | sed  's/_/-/g'))

# remove DB from list of apps
declare -a vAPPS=();
for h in "${vTEMPAPPS[@]}"; do
  if [[ ${h} != *"db0"* ]]; then
    vAPPS+=($h);
  fi
done
declare -a vAPPSIP=()
for eachapp in "${vAPPS[@]}"; do
    appname=$(echo $eachapp | sed 's/-/_/g')
    tempip=$(grep --color=auto "$appname" ops_webtech_data.txt | awk 'BEGIN { FS="\t"}; {print $1}')
    vAPPSIP+=($tempip)

done


# deleting the file so we are always up to date
rm -rf $vFILENAME

# Display the list of serverst that we found based on their criteria
echo "${normal}We found the following Apps to work based on your input: "
vCOUNTER=1
for servername in "${vAPPS[@]}"; do
  echo "$vCOUNTER) $servername"
  vCOUNTER=$[$vCOUNTER +1]
done
echo
echo "${bold}NOTE: ${normal}If the above is not correct, please CTRL+C to exit the app and restart it."
echo

# this outer check is to validate if the start date is lower than the end date
until ((0)); do
  # Ask for Start date
  until ((0)); do
    read -p "Input the ${red}Start Date${normal} you want to search (YYYY-MM-DD) (e.g: lower than end date): ${bold}" vSTARTDATE
    echo "${normal}"
    if [[ $vSTARTDATE =~ ^[0-9]{4}-(0[0-9]|1[0-2])-([0-2][0-9]|3[0-1])$ ]]; then
      break
    else
      echo "${normal} -------------------------------------------------------------------------------------"
      echo "${bold}${red}ERROR:${normal} Invalid Start date, please try again."
      echo "-------------------------------------------------------------------------------------"
      echo
    fi
  done
  # Ask for End date
  until ((0)); do
    read -p "Input the ${red}End Date${normal} you want to search (YYYY-MM-DD) (e.g: higher than start date): ${bold}" vENDDATE
    echo "${normal}"
    if [[ $vENDDATE =~ ^[0-9]{4}-(0[0-9]|1[0-2])-([0-2][0-9]|3[0-1])$ ]]; then
      break
    else
      echo "${normal} -------------------------------------------------------------------------------------"
      echo "${bold}${red}ERROR:${normal} Invalid End date, please try again."
      echo "-------------------------------------------------------------------------------------"
      echo
    fi
  done
  # check if start date is lower than end date
  if [[ "$vSTARTDATE" > "$vENDDATE" ]]; then
    echo "${normal} -------------------------------------------------------------------------------------"
    echo "${bold}${red}ERROR:${normal} Start Date is higher than End Date"
    echo "-------------------------------------------------------------------------------------"
    echo
  else
    break
  fi
done

# Create Date Ranges
if date -v 1d > /dev/null 2>&1; then
  currentDateTs=$(date -j -f "%Y-%m-%d" $vSTARTDATE "+%s")
  endDateTs=$(date -j -f "%Y-%m-%d" $vENDDATE "+%s")
  offset=86400

  while [ "$currentDateTs" -le "$endDateTs" ]
  do
    date=$(date -j -f "%s" $currentDateTs "+%Y-%m-%d")
    datearrange+=($date)
    currentDateTs=$(($currentDateTs+$offset))
  done
else
  d=$1
  while [ "$d" != "$vENDDATE" ]; do
    datearrange+=('$d')
    d=$(date -I -d "$d + 1 day")
  done
fi

# Ask what string to search for
read -p "Input the ${red}Information String${normal} you want to search (wrap in double quotes if using special characters): ${bold}" vSTRINGSEARCH
echo "${normal}"

# Ask if the client wants to save to file or not
read -p "Do you ${bold}${red}want to save${normal} the output to a file? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo
  # Connect to server
  # Do not save to file
  vCOUNTER=0
  for h in "${vAPPSIP[@]}"; do
    echo "Connecting to ${vAPPS[$vCOUNTER]}"
    for day in "${datearrange[@]}"; do
      ssh -o StrictHostKeyChecking=no $vUSERNM@$h grep --color=auto -H $vSTRINGSEARCH /usr/local/blackboard/logs/tomcat/bb-access-log.$day.txt | awk '{print $1, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18}'
      ssh -o StrictHostKeyChecking=no $vUSERNM@$h zgrep --color=auto $vSTRINGSEARCH /usr/local/blackboard/asp/${vAPPS[$vCOUNTER]}/tomcat/bb-access-log.$day.txt.gz | awk '{print $1, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18}'
    done
    echo "Disconnecting from ${vAPPS[$vCOUNTER]}"
    echo ""
    vCOUNTER=$[$vCOUNTER+1]
  done
else
  # Save to file
  currentdate=`date +%Y-%m-%d`
  clientname="$(echo "${vCLIENTNAME}" | tr -d '[[:space:]]')"
  filename="automator-$vUSERNM-$currentdate-$clientname.log"
  # Connect to server
  echo
  vCOUNTER=0
  for h in "${vAPPSIP[@]}"; do
    echo "Connecting to ${vAPPS[$vCOUNTER]}"
    echo "Connecting to ${vAPPS[$vCOUNTER]}" >> $filename
    for day in "${datearrange[@]}"; do
      ssh -o StrictHostKeyChecking=no $vUSERNM@$h grep --color=auto -H $vSTRINGSEARCH /usr/local/blackboard/logs/tomcat/bb-access-log.$day.txt | awk '{print $1, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18}' >> $filename
      ssh -o StrictHostKeyChecking=no $vUSERNM@$h zgrep --color=auto $vSTRINGSEARCH /usr/local/blackboard/asp/${vAPPS[$vCOUNTER]}/tomcat/bb-access-log.$day.txt.gz | awk '{print $1, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18}' >> $filename
    done
    echo "Disconnecting from ${vAPPS[$vCOUNTER]}"
    echo "Disconnecting from ${vAPPS[$vCOUNTER]}" >> $filename
    echo "" >> $filename
    echo ""
    vCOUNTER=$[$vCOUNTER+1]
  done
fi
