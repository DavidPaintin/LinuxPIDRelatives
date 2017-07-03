#!/bin/bash
#This scritpt takes a given PID and finds the PID, process number and network connection for all ancestors and predecesors up to 3 generations away
loopCount1=1
loopCount2=1
loopCount3=1
childrenProcess(){
	childrenCurrent=$(ps -ef | egrep [[:space:]]+[0-9]+[[:space:]]+"${1}"[[:space:]]+[0-9]\{1,3\}[[:space:]] | tr -s ' ' | cut -d' ' -f2)
	processCount=$(echo -n "$childrenCurrent" | grep -c '^')
}
#$1 is the PID and outputs the children processes PIDs in a list and the number of such processes as variables
parentProcess(){
        if [ $1 ]
	then
		ps -ef | egrep [[:space:]]+"${1}"[[:space:]]+[0-9]+[[:space:]]+[0-9]\{1,3\}[[:space:]] | tr -s ' ' | cut -d' ' -f3
	else
		echo -1 
	fi	 
}	
#$1 is the PID, finds the process in ps and outputs the PPID listed there
getProcessName(){
	if [ $1 -gt 0 ]
	then
		processName=$( ps -ef | egrep [[:space:]]+"${1}"[[:space:]]+"${2}"[[:space:]]+[0-9]\{1,3\}[[:space:]]+ | cut -c49- )
		if [[ $processName ]]
		then
			echo $processName
		else
			echo Process does not exist
		fi
	elif [ $1 -eq 0 ]
	then
		echo Process is the root command
	else
		echo Process does not exist
	fi
}
#$1 here is PID and $2 is PPID checks that a process name will be listed  and outputs the process name for $1
getNetworkConnection(){
	networkConn=$(sudo netstat -p | grep ESTABLISHED | egrep "${1}/${2}" | tr -s ' ' | cut -d' ' -f5 )
	if [ $networkConn ]
	then
		echo $networkConn
	else
		echo Not Connected
	fi
}
#Here $1 is PID and $2 is Process Name, searches in netstat for connection and outputs Foreign Address if there is one




if [[ $1 =~ ^[0-9]+$ ]]
#checks the input is a valid format
then
	#check grandparent exists and is not root
	if [[ -n  $(parentProcess $(parentProcess $1)) ]] && [[  $(parentProcess $(parentProcess $1)) -gt 0 ]]
	then
		currentProcess=$(parentProcess $(parentProcess $(parentProcess $1 )))
		currentProcessName=$(getProcessName $currentProcess $(parentProcess $currentProcess))
		echo -e "\e[39m Great Grandparent: PID: $currentProcess"	" Process Name: $currentProcessName"	"  Connection: $(getNetworkConnection $currentProcess $currentProcessName)"
	else
		echo -e "\e[39m No Great Grandparent"
	fi
	#checks parent exists and is not root
	if [[ $(parentProcess $1) -gt 0 ]] && [[ $(parentProcess $1) ]]
	then
		currentProcess=$(parentProcess $(parentProcess $1))
		currentProcessName=$(getProcessName $currentProcess $(parentProcess $currentProcess))
		echo Grandparent:PID: $currentProcess"	" Process Name: $currentProcessName"	" Connection: $(getNetworkConnection $currentProcess $currentProcessName)
	else
		echo No Grandparent
	fi
	#checks if process is root
	if [ $1 -gt 0 ]
	then
		currentProcess=$(parentProcess $1)
		currentProcessName=$(getProcessName $currentProcess $(parentProcess $currentProcess))
		echo Parent: PID: $currentProcess "	" Process Name: $currentProcessName"	"  Connection: $(getNetworkConnection $currentProcess $currentProcessName)
		currentProcess=$1
		currentProcessName=$(getProcessName $currentProcess $(parentProcess $currentProcess))
	        echo Process: PID: $currentProcess"  " Process Name: $currentProcessName"  "  Connection: $(getNetworkConnection $currentProcess $currentProcessName)
	else
		echo No Parent
		echo PID 0 is the root process
		currentProcess=$1
	fi


	childrenProcess $currentProcess
	numberChildren=$processCount
	children=$childrenCurrent


	#loops outputting all children, grandchildren and great grandchildren
	while [ $loopCount1 -le $numberChildren ]
	do
		currentProcess=$( echo "$children" | head -$loopCount1 | tail -1)
		currentProcessName=$(getProcessName $currentProcess $(parentProcess $currentProcess))
		echo -e "\e[36mChild Process $loopCount1: PID: $currentProcess "	" Process Name: $currentProcessName "	"  Connection: $(getNetworkConnection $currentProcess $currentProcessName)"
		childrenProcess $currentProcess
		numberGrandchildren=$processCount
		grandchildren=$childrenCurrent
		while [ $loopCount2 -le $numberGrandchildren ]
		do
			currentProcess=$( echo "$grandchildren" | head  -$loopCount2 | tail -1)
	        	currentProcessName=$(getProcessName $currentProcess $(parentProcess $currentProcess))
		        echo -e   "		\e[33mGrandchild Process $loopCount2: PID: $currentProcess "	" Process Name: $currentProcessName "	" Connection: $(getNetworkConnection $currentProcess $currentProcessName)"
			childrenProcess $currentProcess
			numberGreatGrandchildren=$processCount
			while [ $loopCount3 -le $numberGreatGrandchildren ]
			do
				currentProcess=$( echo "$childrenCurrent" | head  -$loopCount3 | tail -1)
	                	currentProcessName=$(getProcessName $currentProcess $(parentProcess $currentProcess))
		                echo -e "				  \e[92mGreat Grandchild Process $loopCount3: PID: $currentProcess "	" Process Name: $currentProcessName "	" Connection: $(getNetworkConnection $currentProcess $currentProcessName)"
				loopCount3=$(($loopCount3 + 1))
			done
			loopCount3=1
			loopCount2=$(($loopCount2 + 1))
		done
		loopCount2=1
		loopCount1=$(($loopCount1 + 1))
	done
else
	echo	Not a valid PID
fi
