#!/bin/bash

ami_id="ami-0220d79f3f480ecf5"
instance_type="t3.micro"
domain_name="shariffdevops.online"
hosted_zone_id="Z03986291U87DG3HBUGU4"

for instance in $@
do
    echo "Creating instance: $instance"

    instance_id=$(aws ec2 run-instances \
            --image-id $ami_id \
            --instance-type $instance_type \
            --security-group-ids "sg-002f8c095d7e0447d" "roboshop-$instance" \
	        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
	        --query 'Instances[0].InstanceId' \
	        --output text
    )
	
    echo "$instance ID: $instance_id"
done