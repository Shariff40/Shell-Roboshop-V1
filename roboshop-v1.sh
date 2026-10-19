#!/bin/bash

aws ec2 run-instances \
    --image-id ami-0055977a6e828a4f4 \
    --instance-type t3.micro \
    --security-group-ids sg-002f8c095d7e0447d \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Roboshop-shell}]'
	--query 'Instances[0].InstanceId'\
	--output text