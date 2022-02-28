#!/bin/bash

AMAZONAMI1="ami-0a8b4cd432b1c3063"
AMAZONAMI2="ami-0231217be14a6f3ba"
KEYPAIR1="nanoec2"
KEYPATH="~/Downloads/nanoec2.pem"
USERDATA="userdata.sh"
KEYPAIR2="firstec2"

export AWS_DEFAULT_REGION="us-east-1"
echo "We are in $AWS_DEFAULT_REGION, let us begin our Assignment!"

# Create SG & Print SG ID
SGID=$(aws ec2 create-security-group --group-name SecurityGroupV --description "Assignment7SG" \
--query 'GroupId' --output text)

# Open Port 80 & 22 in SG
aws ec2 authorize-security-group-ingress --group-name SecurityGroupV --group-id "$SGID" --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name SecurityGroupV --group-id "$SGID" --protocol tcp --port 22 --cidr 0.0.0.0/0

# Create an EC2 
EC2ID=$(aws ec2 run-instances --image-id "$AMAZONAMI1" --instance-type t2.nano --security-group-ids "$SGID"\
	--key-name "$KEYPAIR1" --associate-public-ip-address --user-data file://$USERDATA \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Assignment7}]' --query 'Instances[*].InstanceId' --output text)

echo "Please wait until the new EC2 is created!"

sleep 60 

echo "Instance has been successfully created!"

echo "Please wait - it will take a minute!"

############# Task 2 ###################

# Create AMI from EC2 Instance in Task 1
EC2AMI=$(aws ec2 create-image --instance-id $EC2ID --name "MyAMI" --description "GoldenAMI" --query "ImageId" --output text) 

# Build a new EC2 in Virginia from the AMI we created
EC2NEW=$(aws ec2 run-instances --image-id "$AMAZONAMI1" --instance-type t2.nano --security-group-ids "$SGID"\
	--key-name "$KEYPAIR1" --associate-public-ip-address --user-data file://$USERDATA \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ChickenInstance}]' --query 'Instances[*].InstanceId' --output text) 

# Wait until EC2 is successfully created!
aws ec2 wait instance-status-ok --instance-ids "$EC2NEW"

# Take public IP from new instance
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$EC2NEW" \
        --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

sleep 10

echo "The image is available on our new instance!"

# SSH to our new instance
ssh -i $KEYPATH -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP "cat /usr/share/nginx/html/index.html"

echo "We successfully ssh into our EC2 and viewed the index.html content!"

sleep 15

export AWS_DEFAULT_REGION="us-east-2"
echo "We are in $AWS_DEFAULT_REGION"

echo "We are unable to see the AMI because they are Region Specific!"

sleep 15

export AWS_DEFAULT_REGION="us-east-1"
echo "We are in $AWS_DEFAULT_REGION"

# Copy AMI to Ohio Region 
ImageID2=$(aws ec2 copy-image --source-image-id $EC2AMI --source-region us-east-1 --region us-east-2 --name "My Ami 2" \
	--query "ImageId" --output text)
echo "The AMI was copied successfully!"

export AWS_DEFAULT_REGION="us-east-2"
echo "We are in $AWS_DEFAULT_REGION"

# Create SG in Ohio & Print SG ID
SGIDOHIO=$(aws ec2 create-security-group --group-name SecurityGroupO --description "Assignment7SGOHIO" \
--query 'GroupId' --output text)

# Open Port 80 & 22 in SG
aws ec2 authorize-security-group-ingress --group-name SecurityGroupO --group-id "$SGIDOHIO" --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name SecurityGroupO --group-id "$SGIDOHIO" --protocol tcp --port 22 --cidr 0.0.0.0/0

# Build a new EC2 in Ohio from the AMI we copied
EC2OHIO=$(aws ec2 run-instances --image-id "$AMAZONAMI2" --instance-type t2.nano --security-group-ids "$SGIDOHIO"\
	--key-name "$KEYPAIR2" --associate-public-ip-address --user-data file://$USERDATA \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ChickenInstance}]' --query 'Instances[*].InstanceId' --output text) 

# Wait until EC2 is successfully created!
aws ec2 wait instance-status-ok --instance-ids "$EC2OHIO"
echo "The EC2 has been created & you can see Jeff Bezos from the browser!"

################ Task 3 #######################

export AWS_DEFAULT_REGION="us-east-1"
echo "We are in $AWS_DEFAULT_REGION"

# Take public IP from the Virginia EC2
PUBLIC_IP_NANO=$(aws ec2 describe-instances --instance-ids "$EC2ID" \
        --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
sleep 10

# SSH to our Virginia EC2
ssh -i $KEYPATH -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP_NANO "free -m | tee memory.txt"
echo "This is the available memory on our EC2!"

# Stop the nano EC2
aws ec2 stop-instances --instance-ids $EC2ID --output text > /dev/null
echo "We need to stop our EC2 in order to resize it!"

aws ec2 wait instance-stopped --instance-ids $EC2ID
echo "Instance stopped!"

# Resize EC2
aws ec2 modify-instance-attribute --instance-id $EC2ID --instance-type "{\"Value\": \"t2.micro\"}"
echo "EC2 resized to t2.micro"

sleep 30

# Start the EC2 
aws ec2 start-instances --instance-ids $EC2ID --output text > /dev/null
echo "The resized EC2 is starting now!"

aws ec2 wait instance-status-ok --instance-ids $EC2ID
echo "The resized EC2 is up & running!"

# Take public IP from the Virginia EC2
PUBLIC_IP_MICRO=$(aws ec2 describe-instances --instance-ids "$EC2ID" \
        --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
sleep 10

# SSH to our Virginia EC2
ssh -i $KEYPATH -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP_MICRO "free -m >> memory.txt && cat memory.txt"
echo "We successfully resized the EC2!"

# Stop all EC2 across Regions
echo "We are stopping all EC2 Instances!"
aws ec2 stop-instances --instance-ids $EC2ID --output text > /dev/null
aws ec2 stop-instances --instance-ids $EC2NEW --output text > /dev/null

sleep 20

export AWS_DEFAULT_REGION="us-east-2"

aws ec2 stop-instances --instance-ids $EC2OHIO --output text > /dev/null

echo "Congratulations on completing the Assignment 3!" xoxo Chicken Tenders

