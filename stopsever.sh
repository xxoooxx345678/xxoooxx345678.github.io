while true
do
    hp=$(ps -W | grep hugo | awk '{print "/PID " $4}')
    if ! [ -z "$hp" ];
    then
        taskkill /F $hp
    else
        exit
    fi
done