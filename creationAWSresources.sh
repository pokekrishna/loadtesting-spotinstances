#!/bin/bash

######## TO CREATE VPC, IGW, ROUTE TABLE, SUBNET, SECURITY GROUP, KEYPAIR

source EC2instanceproperties.sh

echo -ne "Create VPC (y/n)? "
read create_VPC
if [ $create_VPC == 'y' ]
then
        echo -ne "Enter CIDR Block: "
        read cidr
        VPC=$(aws ec2 create-vpc --cidr-block $cidr | grep -o "vpc-[0-9,a-z,A-Z]*")
        aws ec2 create-tags --resources $VPC --tags Key=Name,Value=VPC_$PROJECT
        echo "VPC created, VpcId= "$VPC
	echo "Creating Internet Gateway!"
        IGW=`aws ec2 create-internet-gateway | grep -o "igw-[0-9,a-z,A-Z]*"`
        aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC
        RTB=`aws ec2 create-route-table --vpc-id $VPC | grep -o "rtb-[0-9,a-z,A-Z]*"`
        echo "Done!"
else
	echo -ne "Enter VpcID: "
	read VPC
fi

echo -ne "Create Subnet (y/n)? "
read create_subnet
if [ $create_subnet == 'y' ]
then
	echo -ne "Enter CIDR Block: "
        read cidr
	Subnet=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block $cidr | grep -o "subnet-[0-9,a-z,A-Z]*")
	aws ec2 create-tags --resources $Subnet --tags Key=Name,Value=Subnet_$PROJECT
        echo "Subnet created, Subnet Id= "$Subnet
	aws ec2 associate-route-table --route-table-id $RTB --subnet-id $Subnet
	aws ec2 create-route --route-table-id $RTB --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW
	
else
        echo -ne "Enter SubnetId: "
        read Subnet
fi

echo -ne "Create Security Group (y/n)? "
read create_sg
if [ $create_sg == 'y' ]
then
	# create a security group
	echo -ne "Enter name of Security Group: "
	read SG
	SecurityGroup=$(aws ec2 create-security-group --group-name $SG --description "Load Testing Security Group" --vpc-id $VPC | grep -o "sg-[0-9,a-z,A-Z]*")
	aws ec2 authorize-security-group-ingress --group-id $SecurityGroup --protocol tcp --port 80 --cidr 0.0.0.0/0
	aws ec2 authorize-security-group-ingress --group-id $SecurityGroup --protocol tcp --port 22 --cidr 0.0.0.0/0	
	echo "Security Group created, Security Group ID= "$SecurityGroup

	# getting the ID of the default security group 
	DefaultSecurityGroup=`aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC" --query "SecurityGroups[].[GroupName,GroupId]"  | tr -s ' ' ' ' | tr -s '\t' ' ' | egrep '^default ' | cut -d ' ' -f2`
else
	# use the Security Group entered by the user 
	echo -ne "Enter Security Group Id: "
        read SecurityGroup

    # assign DefaultSecurityGroup as SecurityGroup.
    DefaultSecurityGroup=$SecurityGroup
fi

echo -ne "Create Key Pair (y/n)? "
read create_key
echo "Enter name of Key pair: "
read KeyPairName
if [ $create_key == 'y' ]
then
	echo "Saved the key in "$KeyPairName".pem"
	aws ec2 create-key-pair --key-name $KeyPairName --query 'KeyMaterial' --output text > ./$KeyPairName.pem
	chmod 400 ./$KeyPairName.pem
fi

cat <<here >> EC2instanceproperties.sh
export VPC=$VPC
export Subnet=$Subnet
export SecurityGroup=$SecurityGroup
export DefaultSecurityGroup=$DefaultSecurityGroup
export KeyPairName=$KeyPairName
here








