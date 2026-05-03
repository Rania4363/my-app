pipeline {
    agent any

    environment {
        IMAGE_NAME = "my-app"
        NEXUS_REGISTRY = "192.168.56.20:8082"
        BUILD_TAG = "my-app:${BUILD_NUMBER}"
        FULL_IMAGE = "${NEXUS_REGISTRY}/${BUILD_TAG}"
        K8S_HOST = "192.168.56.30"
        K8S_USER = "kubernetes"
        NAMESPACE = "default"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git credentialsId: 'git-cred',
                    url: 'https://github.com/Rania4363/my-app.git',
                    branch: 'main'
            }
        }

        stage('Maven Build & Test') {
            steps {
                sh 'mvn clean package -B'
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-cred',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh """
                        echo \$NEXUS_PASS | docker login ${NEXUS_REGISTRY} -u \$NEXUS_USER --password-stdin
                        docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${FULL_IMAGE}
                        docker push ${FULL_IMAGE}
                    """
                }
            }
        }

        stage('Deploy on Kubernetes Node') {
            steps {
                sshagent(['k8s-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${K8S_USER}@${K8S_HOST} "
                            echo '=== Pull de l'image depuis Nexus ==='
                            sudo ctr --address /run/containerd/containerd.sock \\
                              --namespace k8s.io images pull \\
                              --plain-http \\
                              --user admin:Raniaensa@2024 \\
                              ${FULL_IMAGE}
                            
                            echo '=== Redémarrage du deployment ==='
                            kubectl set image deployment/${IMAGE_NAME} \\
                              ${IMAGE_NAME}=${FULL_IMAGE} \\
                              -n ${NAMESPACE}
                            
                            kubectl rollout restart deployment/${IMAGE_NAME} -n ${NAMESPACE}
                            
                            echo '=== Attente du déploiement ==='
                            kubectl rollout status deployment/${IMAGE_NAME} -n ${NAMESPACE} --timeout=120s
                            
                            echo '=== Status des pods ==='
                            kubectl get pods -n ${NAMESPACE} -l app=${IMAGE_NAME}
                        "
                    """
                }
            }
        }
    }

    post {
        success {
            echo "========================================="
            echo "✅ Pipeline terminé avec succès - Build #${BUILD_NUMBER}"
            echo "========================================="
            echo "Image: ${FULL_IMAGE}"
            echo "Déployé sur: ${K8S_HOST}"
            echo "========================================="
        }
        failure {
            echo "========================================="
            echo "❌ Pipeline échoué - Build #${BUILD_NUMBER}"
            echo "========================================="
            echo "Vérifiez les logs ci-dessus"
            echo "========================================="
        }
        always {
            archiveArtifacts allowEmptyArchive: true,
                             artifacts: '**/target/surefire-reports/*.xml'
            cleanWs()
        }
    }
}
