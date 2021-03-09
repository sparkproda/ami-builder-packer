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
          args '-u root:docker -v /usr/share/zoneinfo/Asia/Seoul:/etc/localtime:ro --dns 8.8.8.8'
        }
      }
      steps {
        sh 'whoami'
        sh 'packer validate BaseAmi.json'     
        
      }
    }
  }
}