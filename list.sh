
# Get job output and retries if job is not complete
retry_get_job_output()
{
	echo "Retrying to get job output"
	ftp -nv $system << 	EOF >FTPOUT.txt
		user $id $password
		prompt
		quote site filetype=jes JESJOBNAME=${id}* JESSTATUS=OUTPUT JESOWNER=${id}*
		get $JOBNUM output.log
EOF

	cat FTPOUT.txt

	if grep -q "not found" FTPOUT.txt; then
		echo "Sleeping 3 seconds until next job output retry"
		sleep 3
		retry_get_job_output
	fi
}

#Get input needed to run script
read -p "Please enter the LPAR hostname: "  system
read -p "Please enter an ID for $system: "  id
id=$(echo $id | tr a-z A-Z)
read -s -p "Please enter a password for $system: "  password
read -p "
Please enter the ID you wish to list: "  listID
listID=$(echo $listID | tr a-z A-Z)

# Dynamically create jcl
(
	echo "//${id}X JOB (123200000),'LIST ACID',CLASS=A,MSGCLASS=X " 
	echo "//STEP1    EXEC  PGM=IKJEFT01" 
	echo "//SYSTSPRT DD   SYSOUT=*" 
	echo "//SYSTSIN  DD   *" 
	echo "TSS LIST ${listID}" 
) > file.jcl

unix2dos file.jcl

ftp -nv $system << EOF >FTPOUT.txt
		user $id $password
		quote site filetype=jes
		put file.jcl
		quit
EOF

cat FTPOUT.txt
#Retrieve Job Number
JOBNUM=$(grep "250-It is known to JES as" FTPOUT.txt | cut -d " " -f 7)
retry_get_job_output
echo "#################################JCL OUTPUT START#################################"
cat output.log
echo "#################################JCL OUTPUT END###################################"

read -p "Press any key to continue... " -n1 -s
