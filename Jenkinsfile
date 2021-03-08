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
        sh 'packer validate BaseAmi.json'     
        sh 'packer build BaseAmi.json'  
      }
    }
  }
}