#!/bin/bash

ami_id="ami-0220d79f3f480ecf5"
instance_type="t3.micro"
domain_name="shariffdevops.online"
hosted_zone_id="Z03986291U87DG3HBUGU4"

for instance in $@
do
    echo "Creating instance: $instance"
done