pipeline {
    agent any
    environment {
        JAVA_HOME       = '/usr/lib/jvm/java-21-openjdk-amd64'
        PATH            = "${JAVA_HOME}/bin:${PATH}"
        APP_NAME        = "springboot-app"
        IMAGE_NAME      = "${APP_NAME}:${BUILD_NUMBER}"
        NEXUS_URL       = "192.168.192.132:8081"
        NEXUS_REPO      = "docker-hosted"
        NEXUS_IMAGE     = "${NEXUS_URL}/${APP_NAME}:${BUILD_NUMBER}"
        SONAR_URL       = "http://192.168.192.132:9000"
        K8S_NAMESPACE   = "default"
    }
    tools {
        maven 'Maven3'
        jdk   'JDK21'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Maven') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        stage('Tests unitaires') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
        stage('Analyse SonarQube') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh """
                        mvn sonar:sonar \
                            -Dsonar.projectKey=${APP_NAME} \
                            -Dsonar.host.url=${SONAR_URL} \
                            -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }
        stage('Scan Trivy') {
            steps {
                sh """
                    trivy image \
                        --exit-code 0 \
                        --severity HIGH,CRITICAL \
                        --format table \
                        -o trivy-report.txt \
                        ${IMAGE_NAME}
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.txt', fingerprint: true
                }
            }
        }
        stage('Push vers Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-credentials',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh """
                        echo ${NEXUS_PASS} | docker login ${NEXUS_URL} -u ${NEXUS_USER} --password-stdin
                        docker tag ${IMAGE_NAME} ${NEXUS_IMAGE}
                        docker push ${NEXUS_IMAGE}
                        docker logout ${NEXUS_URL}
                    """
                }
            }
        }
        stage('Deploy Kubernetes') {
            steps {
                withKubeConfig([credentialsId: 'kubeconfig']) {
                    sh """
                        sed -i 's|IMAGE_PLACEHOLDER|${NEXUS_IMAGE}|g' k8s/deployment.yaml
                        kubectl apply -f k8s/deployment.yaml -n ${K8S_NAMESPACE}
                        kubectl apply -f k8s/service.yaml -n ${K8S_NAMESPACE}
                        kubectl rollout status deployment/${APP_NAME} -n ${K8S_NAMESPACE}
                    """
                }
            }
        }
    }
    post {
        success {
            echo "Pipeline réussi - Image déployée : ${NEXUS_IMAGE}"
        }
        failure {
            echo "Pipeline échoué - vérifiez les logs"
        }
        always {
            sh "docker rmi ${IMAGE_NAME} || true"
            sh "docker rmi ${NEXUS_IMAGE} || true"
        }
    }
}
