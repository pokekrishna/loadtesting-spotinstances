#!/bin/bash

###############FIRST SCRIPT TO BE RUN


touch /tmp/LoadTesting.log
> /tmp/LoadTesting.log

echo "About to configure aws cli!"
sleep 1

> EC2instanceproperties.sh

#call script to configure aws cli
bash awscliconfig.sh | tee /tmp/LoadTesting.log

#input name of project
while [ true ]
do
        echo -ne "Enter project name: "
        read PROJECT
	aws s3 ls | grep LoadTesting_$PROJECT
        if [ $? -eq 0 ]
        then
                echo "Bucket already exists"
        else
                break
        fi
done

#declare name of S3 buckets
BUCKET_INSTALL="LoadTesting"_$PROJECT
BUCKET_RESULT="LoadTestingResults"_$PROJECT

#write variables
cat <<here >> EC2instanceproperties.sh
export PROJECT=$PROJECT
export BUCKET_INSTALL=LoadTesting_$PROJECT
export BUCKET_RESULT=LoadTestingResults_$PROJECT
here

#edit script to pass variables to JMeter master
sed -i '/PROJECT=/d' configJMeterMaster.sh
sed -i "/#!\/bin\/bash/a PROJECT=$PROJECT;BUCKET_INSTALL=$BUCKET_INSTALL;BUCKET_RESULT=LoadTestingResults_$PROJECT;" configJMeterMaster.sh

echo "About to launch Jenkins Master Instance!"
sleep 5

#call script to create aws resources
bash creationAWSresources.sh | tee /tmp/LoadTesting.log

#call script to launch jenkins master instance
bash launchJenkins.sh | tee /tmp/LoadTesting.log
