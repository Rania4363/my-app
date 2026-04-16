pipeline {
    agent any

    environment {
        // 🔥 PATH corrigé pour Trivy et outils système
        PATH = "/usr/bin:/usr/local/bin:${env.PATH}"

        // 🔥 Nom image Docker
        IMAGE_NAME = "my-app"

        // 🔥 Registry (modifie si Nexus ou DockerHub)
        REGISTRY = "localhost:5000"
    }

    stages {

        /* =========================
           1. GIT CLONE
        ========================= */
        stage('Git Checkout') {
            steps {
                git credentialsId: 'git-cred',
                    url: 'https://github.com/Rania4363/my-app.git',
                    branch: 'main'
            }
        }

        /* =========================
           2. MAVEN BUILD
        ========================= */
        stage('Maven Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        /* =========================
           3. SONARQUBE ANALYSIS
        ========================= */
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        /* =========================
           4. TRIVY FILE SCAN
        ========================= */
        stage('Trivy FS Scan') {
            steps {
                sh '''
                    echo "🔍 Scanning filesystem with Trivy..."
                    trivy fs --exit-code 0 --severity HIGH,CRITICAL .
                '''
            }
        }

        /* =========================
           5. BUILD DOCKER IMAGE
        ========================= */
        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "🐳 Building Docker image..."
                    docker build -t $IMAGE_NAME:latest .
                '''
            }
        }

        /* =========================
           6. TRIVY IMAGE SCAN
        ========================= */
        stage('Trivy Docker Image Scan') {
            steps {
                sh '''
                    echo "🔍 Scanning Docker image..."
                    trivy image --exit-code 0 --severity HIGH,CRITICAL $IMAGE_NAME:latest
                '''
            }
        }

        /* =========================
           7. PUSH IMAGE (REGISTRY)
        ========================= */
        stage('Push Docker Image') {
            steps {
                sh '''
                    echo "📦 Tagging image..."
                    docker tag $IMAGE_NAME:latest $REGISTRY/$IMAGE_NAME:latest

                    echo "📤 Pushing image..."
                    docker push $REGISTRY/$IMAGE_NAME:latest
                '''
            }
        }

        /* =========================
           8. DEPLOY KUBERNETES
        ========================= */
        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    echo "🚀 Deploying to Kubernetes..."

                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml

                    kubectl rollout status deployment/my-app
                '''
            }
        }
    }

    /* =========================
       POST ACTIONS
    ========================= */
    post {
        success {
            echo "✅ Pipeline SUCCESS"
        }

        failure {
            echo "❌ Pipeline FAILED"
        }

        always {
            echo "📊 Cleaning workspace..."
            cleanWs()
        }
    }
}
