pipeline{
  agent any

  parameters {
    string(name: 'IMAGE_NAME_PROD', defaultValue: 'joelrobinson791/capstone-app', description: 'Docker image name for production')
    string(name: 'IMAGE_NAME_DEV', defaultValue: 'joelrobinson791/capstone-app-dev', description: 'Docker image name for development')
    string(name: 'VERSION', defaultValue: 'latest', description: 'Docker image version')
  }

  stages {
    stage ('check branch'){
      steps {
        echo "Triggered by branch: ${env.GIT_BRANCH}"
      }
    }

    stage ('pre-build'){
      steps {
        script {
          env.COMMIT_HASH = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        }
      }
    }

    stage ('image build and docker push'){
      steps {
        script {
          if (env.GIT_BRANCH == 'origin/main'){
            env.IMAGE_URI_REDABLE = "${params.IMAGE_NAME_PROD}:${params.VERSION}"
            env.IMAGE_URI_UNIQUE = "${params.IMAGE_NAME_PROD}:${params.VERSION}-${env.COMMIT_HASH}"
          }
          else {
            env.IMAGE_URI_REDABLE = "${params.IMAGE_NAME_DEV}:${params.VERSION}"
            env.IMAGE_URI_UNIQUE = "${params.IMAGE_NAME_DEV}:${params.VERSION}-${env.COMMIT_HASH}"
          }
            sh "docker build -t ${env.IMAGE_URI_UNIQUE} ."
            echo "login to docker hub"
            withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
              sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
            }
            sh "docker push ${env.IMAGE_URI_UNIQUE}"
            sh "docker tag ${env.IMAGE_URI_UNIQUE} ${env.IMAGE_URI_REDABLE}"
            sh "docker push ${env.IMAGE_URI_REDABLE}"
        }
      }
    }

    stage ('deploy to server (instance)'){
      steps{
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-credentials', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
          sh '''
            ssh -o StrictHostKeyChecking=no -i $SSH_KEY $SSH_USER@34.192.210.74 << EOF
              docker pull $IMAGE_URI_UNIQUE
              docker stop capstone-app || true
              docker rm capstone-app || true
              docker run -d --name capstone-app -p 80:80 $IMAGE_URI_UNIQUE
            EOF
          '''
        }
      }
    }
  }
}
