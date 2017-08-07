#!/bin/sh

# Your Zenoss server settings.
# The URL to access your Zenoss5 Endpoint
ZENOSS_URL="https://zenoss5.yourfqdn.com"
ZENOSS_USERNAME="admin"
ZENOSS_PASSWORD="password"
MONITORED="true" # Whether we're switching the components to monitored (true) or unmonitored (false)
COMPONENTGROUP="Test Component Group"  # The name of the component group in the UI
BATCHSIZE=10    #How many to do at once, probably limited by shell (it runs a curl command)

# End stuff most people will have to config



# ----------- Functions

function api() {   # Api request straight out of the Zenoss api wiki

ROUTER_ENDPOINT="$1"
ROUTER_ACTION="$2"
ROUTER_METHOD="$3"
DATA="$4"

RESPONSE=$(curl \
        -k \
        -u "$ZENOSS_USERNAME:$ZENOSS_PASSWORD" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$ROUTER_ACTION\",\"method\":\"$ROUTER_METHOD\",\"data\":[$DATA], \"tid\":1}" \
        "$ZENOSS_URL/zport/dmd/$ROUTER_ENDPOINT" \
        --silent)
}


# First we poll the component group

endpoint='componentgroup_router'
action='ComponentGroupRouter'
method='getComponents'
data=$(echo {\"uid\":\"/zport/dmd/ComponentGroups/$COMPONENTGROUP\"})
api "$endpoint" "$action" "$method" "$data"

numberofcomponents=$(echo $RESPONSE | jq ".result | .data | length")

COUNTER=0
unset queued

echo counter : $counter
echo components : $numberofcomponents

while ! [ $COUNTER -eq $numberofcomponents ]; do   # iterate over the returned uids and prepare an array so we can send in batches
        uid=$(echo $RESPONSE | jq ".result | .data |.[$COUNTER].uid" | sed 's/\"\(.*\)\"/\1/')
        if ! [[ $uid == *"maintenanceWindows"* ]]; then  # Skipping any maintenance windows that can be residing in a component group
                if [ ${#queued[@]} -eq 0 ]; then
                        queued[0]=$uid
                else
                        queued[${#queued[@]}]=$uid
                fi
                #echo ${#queued[@]}
        fi



        ((COUNTER++))
done

# At this point we have our full queue in the "queued" array

COUNTER=0
for i in ${queued[@]}; do
        if ! [ $COUNTER -eq 0 ]; then
                uidstring=$(echo $uidstring\",\"$i)
                if [ $(expr ${#queued[@]} % $BATCHSIZE) -eq 0 ] || [ $(expr $COUNTER + 1) -eq ${#queued[@]} ]; then    # if the batch has been reached or we've reached the end of the queue
                        endpoint='device_router'
                        action='DeviceRouter'
                        method='setComponentsMonitored'
                        data=$(echo {\"monitor\":$MONITORED\,\"uids\":[\"$uidstring\"]\,\"hashcheck\":3})
                        api "$endpoint" "$action" "$method" "$data"
                        unset uidstring
                        unset COUNTER
                        echo $RESPONSE
                else
                        ((COUNTER++))
                fi
        else
                uidstring=$i
                ((COUNTER++))
        fi
done
~        
   
