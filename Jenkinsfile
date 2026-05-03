pipeline {
    agent any

    environment {
        IMAGE_NAME = "my-app"
        REGISTRY   = "rouched"
        NEXUS_URL  = "192.168.56.20:8082"
        NAMESPACE  = "default"
    }

    tools {
        maven 'Maven-3.9'
        jdk   'JDK-17'
    }

    stages {

        stage('Git Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'git-cred',
                    url: 'https://github.com/Rania4363/my-app.git'
            }
        }

        stage('Build & Test') {
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
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh '''
                trivy fs \
                  --severity HIGH,CRITICAL \
                  --exit-code 0 \
                  --timeout 10m \
                  --format table \
                  --output trivy-fs-report.txt \
                  .
                cat trivy-fs-report.txt
                '''
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

        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-cred',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
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

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    file(credentialsId: 'k8s-token', variable: 'KUBECONFIG'),
                    usernamePassword(
                        credentialsId: 'nexus-cred',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )
                ]) {
                    sh """
                    export KUBECONFIG=\$KUBECONFIG

                    echo "=== Pull image on Kubernetes node ==="

                    ssh -i /home/jenkins/.ssh/id_rsa \
                      -o StrictHostKeyChecking=no \
                      -o UserKnownHostsFile=/dev/null \
                      kubernetes@192.168.56.30 \
                      "sudo ctr --address /run/containerd/containerd.sock \
                       --namespace k8s.io images pull \
                       --plain-http \
                       --user \$NEXUS_USER:\$NEXUS_PASS \
                       ${NEXUS_URL}/${IMAGE_NAME}:${BUILD_NUMBER}"

                    echo "=== Update Kubernetes deployment ==="

                    kubectl set image deployment/${IMAGE_NAME} \
                      ${IMAGE_NAME}=${NEXUS_URL}/${IMAGE_NAME}:${BUILD_NUMBER} \
                      -n ${NAMESPACE}

                    kubectl rollout status deployment/${IMAGE_NAME} --timeout=120s

                    kubectl get pods -n ${NAMESPACE}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline SUCCESS — Build #${BUILD_NUMBER}"
        }
        failure {
            echo "❌ Pipeline FAILED — Build #${BUILD_NUMBER}"
        }
        always {
            archiveArtifacts allowEmptyArchive: true,
                             artifacts: 'trivy-*.txt'
            cleanWs()
        }
    }
}
