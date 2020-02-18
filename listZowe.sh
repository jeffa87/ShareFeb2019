
#Checks status of job and gets output when complete
retry_get_job_output()
{
	jobID=$1
	status="UNKNOWN"
	while [[ "$status" != "OUTPUT" ]]; do
    	echo "Checking status of job $jobID"
    	status=$(zowe zos-jobs view job-status-by-jobid "$jobID" --zosmf-profile $profile --rff status --rft string)
    	echo "Current status is $status"
	done;
	zowe zos-jobs download output $jobID --zosmf-profile $profile
}

#Get input needed to run script
read -p "Please enter a zowe profile name: "  profile
read -p "Please enter the ID you wish to list: "  listID
listID=$(echo $listID | tr a-z A-Z)

#Dynamically create jcl
(
	echo "//LISTX JOB (123200000),'LIST ACID',CLASS=A,MSGCLASS=X " 
	echo "//STEP1    EXEC  PGM=IKJEFT01" 
	echo "//SYSTSPRT DD   SYSOUT=*" 
	echo "//SYSTSIN  DD   *" 
	echo "TSS LIST ${listID}" 
) > file.jcl

#Submit job and get jobID
jobID=$(zowe zos-jobs submit local-file file.jcl --zosmf-profile $profile --rff jobid --rft string)

#Call function to checks status of job and get output when complete
retry_get_job_output $jobID

echo "#################################JCL OUTPUT START#################################"
cat output/$jobID/STEP1/SYSTSPRT.txt
echo "#################################JCL OUTPUT END###################################"

read -p "Press any key to continue... " -n1 -s