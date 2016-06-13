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
echo
read -p "Please provide your ${red}MH username:${normal}${bold} " vUSERNM

# Download file using SCP to current directory
echo "${normal}We will download the Client Database file into a temporal location..."
scp -pq $vUSERNM@10.6.11.11:/mnt/asp/utils/bin/include/ops_webtech_data.txt ./
echo "File downloaded."

# Ask for Client Name
read -p "${normal}What ${red}client${normal}  do you want to work on: ${bold}" vCLIENTNAME
# Ask for Environment type (Production or Staging or Test)
read -p "${normal}What ${red}environment${normal} do you want to work on (Production, Staging, Test...): ${bold}" vENVIRONMENT
echo "${normal}"

# Get unique URLS and ask client which one they want to work on
vOPTIONS=($(grep --color=auto -i "$vCLIENTNAME" $vFILENAME | grep --color=auto -i $vENVIRONMENT | awk 'BEGIN { FS = "\t" } ; {print $14}' | sort | uniq))

# Send to the user the list of URLS that we found and make them select one
echo "${green}We found this options: ${normal}"
vCOUNTER=0
for i in "${vOPTIONS[@]}"
do
  echo "$vCOUNTER) $i"
  vCOUNTER=$[$vCOUNTER +1]
done
echo

# Ask to select one of the options above
read -p "Input the above ${red}id number${normal} you want to work on: ${bold}" vARRAYID
# Set the Working url
vWORKINGURL=${vOPTIONS[$vARRAYID]}


if [ "$vWORKINGURL" == "" ]; then
	echo "ERROR: Wrong Input, exiting"
	exit 1
fi

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
    vAPPSIP+=$(grep --color=auto "$appname" ops_webtech_data.txt | awk 'BEGIN { FS="\t"}; {print $1}')
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

# Ask for a specific date in regular expresion to search for
vCURDATE=`date +%Y-%m-%d`
read -p "Input the ${red}Start Date${normal} you want to search (YYYY-MM-DD) (e.g: lower than end date): ${bold}" vSTARTDATE
echo "${normal}"
read -p "Input the ${red}End Date${normal} you want to search (YYYY-MM-DD) (e.g: higher than start date): ${bold}" vENDDATE
echo "${normal}"

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

# Ask what user pk1 to search for
read -p "Input the ${red}User PK1${normal} you want to search (example: 284407): ${bold}" vUSERPK1
echo "${normal}"

# Connect to server
vCOUNTER=0
for h in "${vAPPSIP[@]}"; do
  echo "Connmecting to ${vAPPS[$vCOUNTER]}"
  for day in "${datearrange[@]}"; do
    ssh  -o StrictHostKeyChecking=no $vUSERNM@$h grep --color=auto -H $vUSERPK1 /usr/local/blackboard/logs/tomcat/bb-access-log.$day.txt | awk '{print $1, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18}'
    ssh  -o StrictHostKeyChecking=no $vUSERNM@$h zgrep --color=auto $vUSERPK1 /usr/local/blackboard/asp/${vAPPS[$vCOUNTER]}/tomcat/bb-access-log.$day.txt.gz | awk '{print $1, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18}'
  done
  echo "Disconnecting from ${vAPPS[$vCOUNTER]}"
done
