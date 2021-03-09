# Automated AWS AMI builds for Jenkins agents with Packer

젠킨스 agent로 활용하기 위해서 Packer docker image를 생성합니다. 
packer dockerfile은 packer, ansible, awscli 구성을 포함하여 아래와 같이 작성했습니다.
Pakcer에서 빌드 타입이 amazon-ebs 인경우, AMI생성시 소스 AMI에서 EC2 인스턴스를 시작하고 실행중인 머신을 프로비저닝 한 다음 해당 머신에서 AMI를 생성하여 AMI를 빌드합니다.


~~~
FROM alpine:3.7

# Set environment variable for downloading vault version.
ENV PACKER_VERSION=1.7.0

RUN apk update \
    && apk add --update \
       ca-certificates \
       unzip \
       wget \
	   bash \
    && rm -rf /var/cache/apk/* \
    && wget -P /tmp/ https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && mkdir -p /opt/packer \
    && unzip /tmp/packer_${PACKER_VERSION}_linux_amd64.zip  \
	&& mv packer /usr/local/bin/packer \
    && mkdir -p /data

RUN apk add --update --no-cache docker openrc \
    && apk add --no-cache ansible \
    && rm -rf /tmp/*  \
    && rm -rf /var/cache/apk/*  
RUN rc-update add docker boot    
RUN addgroup -S vagrant && adduser -S vagrant -G vagrant

FROM amazonlinux:2 as installer
COPY awscli-exe-linux-x86_64.zip .
RUN yum update -y \
  && yum install -y unzip \
  && unzip awscli-exe-linux-x86_64.zip \
  && ./aws/install --bin-dir /aws-cli-bin/

FROM amazonlinux:2
RUN yum update -y \
  && yum install -y less groff \
  && yum clean all
COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /aws-cli-bin/ /usr/local/bin/

VOLUME ["/data"]
WORKDIR /data

ENTRYPOINT [ "tail", "-f", "/dev/null" ]

CMD ["/bin/bash"]
~~~

이 Dockerfile을 사용하여 packer image를 생성합니다.

에제 Packer template를 준비합니다.

## Step 1: Prep Packer template

~~~
{
    "variables": {
      "aws_access_key": "{{env `AWS_ACCESS_KEY`}}",
      "aws_secret_key": "{{env `AWS_SECRET_ACCESS_KEY`}}",
      "vpc_region": "",
      "vpc_id": "vpc-f8bc3a93",
      "vpc_public_sn_id": "",
      "vpc_public_sg_id": "",
      "instance_type": "t2.micro",
      "ssh_username": "ubuntu"
    },
    "builders": [
      {
        "type": "amazon-ebs",
        "access_key": "{{ user `aws_access_key` }}",
        "secret_key": "{{ user `aws_secret_key` }}",
        "region": "ap-northeast-2",
        "vpc_id": "vpc-f8bc3a93",
        "associate_public_ip_address": true,
        "security_group_id": "",
        "source_ami_filter": {
          "filters": {
          "virtualization-type": "hvm",
          "architecture": "x86_64",
          "name": "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*",
          "block-device-mapping.volume-type": "gp2",
          "root-device-type": "ebs"
          },
          "owners": ["099720109477"],
          "most_recent": true
        },  
        "instance_type": "t2.micro",
        "ssh_username": "ubuntu",
        "ami_name": "base-ubuntu-18.04-aws-base-{{timestamp}}",
        "ami_groups": "all",
        "tags": {
          "Name": "sparkproda",
          "TEAM": "sparkproda"
        },  
        "launch_block_device_mappings": [
          {
            "device_name": "/dev/sda1",
            "volume_type": "gp2",
            "volume_size": "30",
            "delete_on_termination": true
          }
        ]
      }
    ],
    "provisioners": [     
      {
        "type": "ansible",
        "playbook_file": "ansible_common.yml",
        "extra_arguments": [ "-vvvv" ]
      }
    ],
    "post-processors": [
      {
        "type": "manifest",
        "output": "manifest.json",
        "strip_path": true
      }
    ]
  }
~~~


젠킨스를 사용하여 빌드합니다. 빌드할 때 agent는 사전에 생성한 packer docker image를 사용합니다. 

## Step 2: Prep Jenkinsfile 
~~~
pipeline {
  agent any
  environment {
    AWS_ACCESS_KEY     = credentials('jenkins-aws-secret-key-id')
    AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws-secret-access-key')
  }
  stages {
    stage ('Build')  {
      agent {
        docker {
          image 'packer_spark:v1'
          args '-u root:root -v /usr/share/zoneinfo/Asia/Seoul:/etc/localtime:ro'
        }
      }
      steps {
        sh 'packer build BaseAmi.json'        
      }
    }
  }
}
~~~







