
#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="shariffdevops.online"
hosted_zone_id="Z03986291U87DG3HBUGU4"

for instance in "$@"
do
    echo "Creating instance: $instance"

    # Get security group IDs (use exact group names)
    common_sg_id=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=Roboshop-Common" \
        --query 'SecurityGroups[0].GroupId' \
        --output text) || exit 1

    component_sg_name="Roboshop-${instance^}"

    component_sg_id=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=$component_sg_name" \
        --query 'SecurityGroups[0].GroupId' \
        --output text) || exit 1

    if [ "$common_sg_id" = "None" ] || [ "$component_sg_id" = "None" ]; then
        echo "ERROR: Security group not found for $instance"
        exit 1
    fi

    # Launch EC2 instance
    instance_id=$(aws ec2 run-instances \
        --image-id "$ami_id" \
        --instance-type "$instance_type" \
        --security-group-ids "$common_sg_id" "$component_sg_id" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text) || exit 1

    echo "$instance instanceID: $instance_id"

    # Wait until instance information is available
    aws ec2 wait instance-running --instance-ids "$instance_id" || exit 1

    # Select private IP for backend; public IP for frontend
    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text) || exit 1

        r53_record="$instance.$domain_name"
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text) || exit 1

        # FIX: Remove the unwanted curly braces
        r53_record="$domain_name"
    fi

    # FIX: Build valid JSON using a heredoc
    echo "Record: $r53_record -> $IP"

    cat > /tmp/route53-change.json <<EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$r53_record",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          {
            "Value": "$IP"
          }
        ]
      }
    }
  ]
}
EOF

    # Update Route 53 and check whether it succeeded
    if aws route53 change-resource-record-sets \
        --hosted-zone-id "$hosted_zone_id" \
        --change-batch file:///tmp/route53-change.json
    then
        echo "Successfully updated Route 53 for $instance"
    else
        echo "ERROR: Route 53 update failed for $instance"
        exit 1
    fi

done
