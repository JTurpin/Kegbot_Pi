#!/bin/bash
Num_Instances=`ps ax | grep kegbot | wc -l`

echo $Num_Instances

# If kegbot is not running.
if [ $Num_Instances -lt 2 ]; then
        echo "kegbot.py isn't running"
        nohup python /root/kegbot/kegbot.py &
else
        echo "kegbot.py is running, move along, there's nothing to see here"
fi
