pipeline {
    agent any

    environment {
        IMAGE_NAME = "my-app"
        REGISTRY   = "rouched"
        NEXUS_URL  = "192.168.56.20:8082"
        NAMESPACE  = "default"
    }

    stages {

        stage('Git Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'git-cred',
                    url: 'https://github.com/Rania4363/my-app.git'
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

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar -B'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh """
                trivy fs \
                  --severity HIGH,CRITICAL \
                  --exit-code 0 \
                  --timeout 10m \
                  --format table \
                  --output trivy-fs-report.txt \
                  .
                cat trivy-fs-report.txt
                """
            }
        }

        stage('Docker Build') {
            steps {
                sh """
                docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh """
                trivy image \
                  --severity HIGH,CRITICAL \
                  --exit-code 0 \
                  --timeout 10m \
                  --format table \
                  --output trivy-image-report.txt \
                  ${IMAGE_NAME}:${BUILD_NUMBER}
                cat trivy-image-report.txt
                """
            }
        }

        stage('Docker Push — Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-cred',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                    echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${REGISTRY}/${IMAGE_NAME}:latest
                    docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${REGISTRY}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Docker Push — Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-cred',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                    echo \$NEXUS_PASS | docker login http://${NEXUS_URL} -u \$NEXUS_USER --password-stdin
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${NEXUS_URL}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${NEXUS_URL}/${IMAGE_NAME}:latest
                    docker push ${NEXUS_URL}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${NEXUS_URL}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                kubectl config set-cluster kubernetes \
                  --server=https://192.168.56.30:6443 \
                  --insecure-skip-tls-verify=true

                kubectl config set-credentials jenkins \
                  --token=\$(cat /var/jenkins_home/k8s-token.txt)

                kubectl config set-context jenkins-context \
                  --cluster=kubernetes \
                  --user=jenkins

                kubectl config use-context jenkins-context

                kubectl set image deployment/my-app \
                  my-app=${NEXUS_URL}/${IMAGE_NAME}:${BUILD_NUMBER} \
                  -n ${NAMESPACE}

                kubectl rollout status deployment/my-app -n ${NAMESPACE}
                kubectl get pods -n ${NAMESPACE}
                """
            }
        }

    } 

    post {
        success {
            echo "✅ Pipeline CI/CD réussi — Build #${BUILD_NUMBER} 🚀"
        }
        failure {
            echo "❌ Pipeline échoué — Build #${BUILD_NUMBER}"
        }
        always {
            archiveArtifacts allowEmptyArchive: true,
                             artifacts: 'trivy-*.txt'
            cleanWs()
        }
    }

}
