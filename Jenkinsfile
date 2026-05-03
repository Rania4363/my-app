pipeline {
    agent any

    environment {
        IMAGE_NAME = "192.168.56.20:8082/my-app:92"
        K8S_HOST = "192.168.56.30"
        K8S_USER = "kubernetes"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git credentialsId: 'git-cred',
                    url: 'https://github.com/Rania436/ton-repo.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t my-app .
                '''
            }
        }

        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-cred', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                        echo $PASS | docker login 192.168.56.20:8082 -u $USER --password-stdin
                        docker tag my-app $IMAGE_NAME
                        docker push $IMAGE_NAME
                    '''
                }
            }
        }

        stage('Deploy on Kubernetes Node') {
            steps {
                sshagent(['k8s-token']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${K8S_USER}@${K8S_HOST} "
                            sudo ctr --address /run/containerd/containerd.sock \
                            --namespace k8s.io images pull \
                            --plain-http \
                            ${IMAGE_NAME}
                        "
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline terminé avec succès'
        }
        failure {
            echo '❌ Pipeline échoué'
        }
    }
}
