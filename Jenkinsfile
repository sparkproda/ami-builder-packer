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
          args '--dns 8.8.8.8'
        }
      }
      steps {
        sh 'whoami'
        sh 'packer validate BaseAmi.json' 
        
      }
    }
  }
}