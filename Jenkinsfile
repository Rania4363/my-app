pipeline {
    agent any

    tools {
        maven 'Maven3'
    }

    environment {
        DOCKER_IMAGE = "192.168.56.11:8082/my-app"
    }

    stages {

        stage('Checkout') {
            steps {
                git 'https://github.com/YOUR_REPO.git'
            }
        }

        stage('Build Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('SonarQube') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE .'
            }
        }

        stage('Push Nexus') {
            steps {
                sh '''
                docker login 192.168.56.11:8082 -u admin -p admin
                docker push $DOCKER_IMAGE
                '''
            }
        }
    }
}
