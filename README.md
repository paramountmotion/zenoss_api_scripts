# zenoss_api_scripts

These scripts are NOT created, maintained, or supported by Zenoss Inc. Please DO NOT contact Zenoss for help with anything on this page. 

The scripts are purely the effort of one bored tech who wants to share what he makes to help people make their jobs easier. Feel free to use them, but if you have any problems with them either troubleshoot them yourself, or if you're good with scripting feel free to commit a change. 



component-group-state-change.sh : Finds each component in a component group, sets them to monitored or unmonitored in batches. Used because you can't currently set individual components into a production state in the UI (even though the interface makes it look like you can). You could put this on a cron job to make maintenance windows, say if you were going to turn off a program while its database is undergoing maintenance each week but you still want to monitor the rest of the software and hardware on the server.
