#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="shariffdevops.online"
hosted_zone_id="Z03986291U87DG3HBUGU4"

for instance in $@
do
    echo "Creating instance: $instance"

    instance_id=$(aws ec2 run-instances \
        --image-id $ami_id \
        --instance-type $instance_type \
        --security-groups-ids "sg-0f3e7c1b8e5f9a1b4" "sg-0f3e7c1b8e5f9a1b4" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text
        )

    echo "$instance ID: $instance_id"
done
