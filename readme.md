# Building custom AMI using Packer and Jenkins

젠킨스 agent로 활용하기 위해서 Packer docker image를 생성합니다. 
packer dockerfile은 packer, ansible, awscli 구성을 포함하여 아래와 같이 작성했습니다.

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







