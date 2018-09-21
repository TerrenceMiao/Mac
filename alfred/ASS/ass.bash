#!/bin/bash

# aws ssh simple a.k.a. ass is a script let you login AWS ec2 instance node as fast as possible
#
# Usage:
# 	ass.bash AWS_EC2_STACK_NAME [ sudoer | [ 2nd | 3rd | 4th ec2 instance node ] ]
#
# "sudoer" and "ec2 instancde node" can be in any order
#
# Example:
#       ass.bash userpreferences-pdev-01-app (login as default user "ec2-user" on 1st ec2 instance node)
#       ass.bash pccaccessone-ptest-02-app 2 (login as default user "ec2-user" on 2nd ec2 instance node)
#       ass.bash draftorders-vtest-01-app tomcat 4 (login as user "tomcat" on 4th ec2 instance node)
#       ass.bash draftorders-vtest-01-app 3 tomcat (login as user "tomcat" on 3rd ec2 instance node)
#       ass.bash pccaccessone-prod-02-app tomcat (login as user "tomcat" on default 1st ec2 instance node)
# --------------------------------------------------------------------------------------------------------


isParamInstanceNode() {

    if [ \( $1 = "2" \) -o \( $1 = "3" \) -o \( $1 = "4" \) ]
    then
        return 0
    else
        return 1
    fi
}

calculateLineNumber() {

    echo "$((1 + ($1-1)*3))p"
}


if [ \( "$#" -eq 1 \) -o \( "$#" -eq 2 \) -o \( "$#" -eq 3 \) ]; then

    ## detect AWS profile
    profile=''

    if [[ $1 = *-pdev-* ]]; then
        profile='ap-dev'
    elif [[ $1 = *-ptest-* ]]; then
        profile='ap-test'
    elif [[ $1 = *-stest-* ]]; then
        profile='ap-test'
    elif [[ $1 = *-vtest-* ]]; then
        profile='ap-test'
    elif [[ $1 = *-prod-* ]]; then
        profile='ap-prod'
    else
        echo Cant determine which AWS environment to logon
        exit 1
    fi

    ## detect which ec2 instance node and calculate line number in AWS ec2 instance description
    lineNo='1p'
    user=''

    if [ "$#" -eq 2 ]; then
        if isParamInstanceNode $2; then
            lineNo=$( calculateLineNumber $2 )
        else
            user=$2
        fi
    fi

    if [ "$#" -eq 3 ]; then
        if isParamInstanceNode $2; then
            lineNo=$( calculateLineNumber $2 )
            user=$3
        elif isParamInstanceNode $3; then
            lineNo=$( calculateLineNumber $3 )
            user=$2
        else
            echo Invalid ec2 instance node
            exit 1
        fi
    fi

    echo Logon ec2 instance [$1] on node [$lineNo] in [$profile] environment as user [$user]

    if [ -z "$user" ]; then
        ssh -o "StrictHostKeyChecking no" -l ec2-user $(aws ec2 describe-instances --profile "$profile" --filters "Name=tag:Name,Values=$1" | grep 'PrivateDnsName": "ip-' | sed -n $lineNo | cut -d'"' -f4)
    else
    	ssh -o "StrictHostKeyChecking no" -l ec2-user $(aws ec2 describe-instances --profile "$profile" --filters "Name=tag:Name,Values=$1" | grep 'PrivateDnsName": "ip-' | sed -n $lineNo | cut -d'"' -f4) -t sudo su - $user
    fi
else
    echo "Usage:"
    echo "      ass.bash AWS_EC2_STACK_NAME [ sudoer | [ 2nd | 3rd | 4th ec2 instance node ] ]"
fi
