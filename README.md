# automation_script
The idea of this repository is to start with a data mining script to automate the connectivity and work to any Blackboard Server in Managed Hosting Cloud Services to perform those activities. Afterwards to continue improving the actions to be performed.

## Summary
Since we perform several data mining capabilities to many clients, sometimes checking for Academic Dishonest, sometimes analyzing what the user was doing, it was shown as a good opportunity to create a script to perform such actions in an automated manner. For this reason, it was created a script to be able to automate the connectivity and perform data mining.

### Example A
In this example will request for your username and password since it does not have Private / Publick key enabled
````bash
$ ./data_mining.sh 

We are downloading the client list to work on

Please provide your MH username: tempuser
We will download the Client Database file into a temporal location...
File downloaded.
What client  do you want to work on: University Of Cau
What environment do you want to work on (Production, Staging, Test...): Demo

We found this options: 
0) university-demo.blackboard.com

Input the above id number you want to work on: 0
We found the following Apps to work based on your input: 
1) serverXX-app001


NOTE: If the above is not correct, please CTRL+C to exit the app and restart it.

Input the Date you want to search (YYYY-MM-DD): 2016-05-24

Input the User PK1 you want to search (example: 284407): 284407

Connecting to 
tempuser@serverXX-app001.mhint's password: 
/usr/local/blackboard/logs/tomcat/bb-access-log.2016-05-24.txt:186.204.239.236 _166276_1 [24/May/2016:12:40:02 -0300] "GET /webapps/blackboard/execute/content/file?cmd=view&content_id=_3284407_1&course_id=_125698_1 HTTP/1.1" 302 - "Mozilla/5.0 (Linux; Android 5.1; ASUS_Z00VD Build/LMY47I) AppleWebKit/537.36
````

### Example B
In this example will not request for your a password since it does  have Private / Publick key enabled
````bash
$ ./data_mining.sh 

We are downloading the client list to work on

Please provide your MH username: evalenzuela
We will download the Client Database file into a temporal location...
File downloaded.
What client  do you want to work on: University Of Cau
What environment do you want to work on (Production, Staging, Test...): Demo

We found this options: 
0) university-demo.blackboard.com

Input the above id number you want to work on: 0
We found the following Apps to work based on your input: 
1) serverXX-app001


NOTE: If the above is not correct, please CTRL+C to exit the app and restart it.

Input the Date you want to search (YYYY-MM-DD): 2016-05-24

Input the User PK1 you want to search (example: 284407): 284407

Connecting to serverXX-app001
/usr/local/blackboard/logs/tomcat/bb-access-log.2016-05-24.txt:186.204.239.236 _166276_1 [24/May/2016:12:40:02 -0300] "GET /webapps/blackboard/execute/content/file?cmd=view&content_id=_3284407_1&course_id=_125698_1 HTTP/1.1" 302 - "Mozilla/5.0 (Linux; Android 5.1; ASUS_Z00VD Build/LMY47I) AppleWebKit/537.36
````
