pipeline {
    agent any
 
    environment {
        IMAGE_NAME      = "my-app"
        REGISTRY        = "rouched"                        // Docker Hub username
        NEXUS_URL       = "192.168.56.20:8082"             // Nexus Docker registry
        NEXUS_MAVEN_URL = "http://192.168.56.20:8081"      // Nexus Maven URL
        SONAR_HOST_URL  = "http://192.168.56.20:9000"
        NAMESPACE       = "default"
    }
 
    tools {
        maven 'Maven-3.9'    // Nom configuré dans Jenkins > Global Tool Configuration
        jdk   'JDK-17'
    }
 
    stages {
 
        // ─────────────────────────────────────────────
        // ÉTAPE 1 : Récupération du code source
        // ─────────────────────────────────────────────
        stage('Git Checkout') {
            steps {
                git credentialsId: 'git-cred',
                    url:            'https://github.com/Rania4363/my-app.git',
                    branch:         'main'
            }
        }
 
        // ─────────────────────────────────────────────
        // ÉTAPE 2 : Build Maven + Tests unitaires
        // ─────────────────────────────────────────────
        stage('Build & Test') {
            steps {
                sh 'mvn clean package -B'
                // -B = batch mode (pas de progress bars, logs propres)
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: '**/target/surefire-reports/*.xml'
                    // Publier la couverture JaCoCo si plugin configuré dans pom.xml
                    // jacoco execPattern: '**/target/jacoco.exec'
                }
            }
        }
 
        // ─────────────────────────────────────────────
        // ÉTAPE 3 : Analyse qualité SonarQube
        // ─────────────────────────────────────────────
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    withCredentials([string(credentialsId: 'sonar-token',
                                           variable: 'SONAR_TOKEN')]) {
                        sh """
                        mvn sonar:sonar -B \
                          -Dsonar.projectKey=my-app \
                          -Dsonar.projectName='My App' \
                          -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                }
            }
        }
 
        // ─────────────────────────────────────────────
        // ÉTAPE 4 : Vérification Quality Gate
        //   → Bloque le pipeline si le code ne passe
        //     pas les seuils définis dans SonarQube
        // ─────────────────────────────────────────────
        stage('Quality Gate') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }
 
        // ─────────────────────────────────────────────
        // ÉTAPE 5 : Publication de l'artefact sur Nexus
        //   → mvn deploy pousse le .jar dans
        //     Nexus maven-releases ou snapshots
        // ─────────────────────────────────────────────
        stage('Nexus Artifact Upload') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-cred',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                    mvn deploy -B -DskipTests \
                      -Daltdeploymentrepository=nexus::default::${NEXUS_MAVEN_URL}/repository/maven-releases/ \
                      -Drepository.username=${NEXUS_USER} \
                      -Drepository.password=${NEXUS_PASS}
                    """
                }
            }
        }
 
        // ─────────────────────────────────────────────
        // ÉTAPE 6 : Scan Trivy sur le filesystem
        //   → Vérifie les dépendances Maven avant
        //     de construire l'image Docker
        //   CORRECTION : suppression du || true
        //   qui neutralisait le exit-code
        // ─────────────────────────────────────────────
        stage('Trivy FS Scan') {
            steps {
                sh '''
                trivy fs \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  --format table \
                  --output trivy-fs-report.txt \
                  .
                echo "=== Trivy FS Report ==="
                cat trivy-fs-report.txt
                '''
            }
        }
 
        // ─────────────────────────────────────────────
        // ÉTAPE 7 : Build de l'image Docker
        //   → Multi-stage Dockerfile recommandé
        //     pour minimiser la surface d'attaque
        // ─────────────────────────────────────────────
        stage('Docker Build') {
            steps {
                sh """
                docker build \
                  --no-cache \
                  --build-arg BUILD_NUMBER=${BUILD_NUMBER} \
                  -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                  -t ${IMAGE_NAME}:latest \
                  .
                """
            }
        }
 
        // ─────────────────────────────────────────────
        // ÉTAPE 8 : Scan Trivy sur l'image Docker
        //   CORRECTION : --exit-code 0 → 1
        //   pour bloquer sur CRITICAL
        // ─────────────────────────────────────────────
        stage('Trivy Image Scan') {
            steps {
                sh """
                trivy image \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  --format table \
                  --output trivy-image-report.txt \
                  ${IMAGE_NAME}:${BUILD_NUMBER}
                echo "=== Trivy Image Report ==="
                cat trivy-image-report.txt
                """
            }
        }
 
        // ─────────────────────────────────────────────
        // ÉTAPE 9 : Tag & Push vers Docker Hub + Nexus
        // ─────────────────────────────────────────────
        stage('Docker Tag & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-cred',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                    echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
 
                    # Push vers Docker Hub
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${REGISTRY}/${IMAGE_NAME}:latest
                    docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${REGISTRY}/${IMAGE_NAME}:latest
                    """
                }
 
                // Push vers Nexus Docker Registry (optionnel, décommenter si besoin)
                // withCredentials([usernamePassword(
                //     credentialsId: 'nexus-cred',
                //     usernameVariable: 'NEXUS_USER',
                //     passwordVariable: 'NEXUS_PASS')]) {
                //     sh """
                //     echo \$NEXUS_PASS | docker login ${NEXUS_URL} -u \$NEXUS_USER --password-stdin
                //     docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${NEXUS_URL}/${IMAGE_NAME}:${BUILD_NUMBER}
                //     docker push ${NEXUS_URL}/${IMAGE_NAME}:${BUILD_NUMBER}
                //     """
                // }
            }
        }
 
        // ─────────────────────────────────────────────
        // ÉTAPE 10 : Déploiement Kubernetes
        //   CORRECTION : envsubst remplace les vars
        //   dans une COPIE du manifest (pas le fichier
        //   source), évitant la corruption du dépôt
        // ─────────────────────────────────────────────
        stage('Deploy Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'k8s-token',
                                      variable: 'KUBECONFIG')]) {
                    sh """
                    export KUBECONFIG=\$KUBECONFIG
 
                    # Créer une copie temporaire des manifests
                    cp -r k8s/ k8s-deploy/
 
                    # Substituer le tag image dans la copie
                    export BUILD_NUMBER=${BUILD_NUMBER}
                    export REGISTRY=${REGISTRY}
                    export IMAGE_NAME=${IMAGE_NAME}
                    envsubst < k8s/deployment.yaml > k8s-deploy/deployment.yaml
 
                    # Appliquer les manifests
                    kubectl apply -f k8s-deploy/ -n ${NAMESPACE}
 
                    # Attendre la fin du rollout
                    kubectl rollout status deployment/my-app \
                      -n ${NAMESPACE} \
                      --timeout=120s
 
                    # Vérifier l'état final des pods
                    kubectl get pods -n ${NAMESPACE} -l app=my-app
 
                    # Nettoyage de la copie temporaire
                    rm -rf k8s-deploy/
                    """
                }
            }
        }
    }
 
    // ─────────────────────────────────────────────────
    // POST-PIPELINE : Notifications + Nettoyage
    //   Remplacer emailext par slackSend si Slack
    //   est préféré (plugin Jenkins Slack requis)
    // ─────────────────────────────────────────────────
    post {
        success {
            echo "✅ Pipeline SUCCESS — Build #${BUILD_NUMBER}"
            // Notification par email (plugin Email Extension requis)
            // emailext(
            //     subject: "✅ [Jenkins] my-app #${BUILD_NUMBER} — SUCCESS",
            //     body: "Le pipeline s'est terminé avec succès.\nBuild: ${BUILD_URL}",
            //     to: 'team@example.com'
            // )
            // Notification Slack
            // slackSend(
            //     color: 'good',
            //     message: "✅ *my-app* build #${BUILD_NUMBER} déployé avec succès — ${BUILD_URL}"
            // )
        }
        failure {
            echo "❌ Pipeline FAILED — Build #${BUILD_NUMBER}"
            // emailext(
            //     subject: "❌ [Jenkins] my-app #${BUILD_NUMBER} — FAILURE",
            //     body: "Le pipeline a échoué. Consultez les logs : ${BUILD_URL}",
            //     to: 'team@example.com'
            // )
            // slackSend(
            //     color: 'danger',
            //     message: "❌ *my-app* build #${BUILD_NUMBER} FAILED — ${BUILD_URL}"
            // )
        }
        always {
            // Archiver les rapports Trivy
            archiveArtifacts allowEmptyArchive: true,
                             artifacts: 'trivy-*.txt'
 
            // Nettoyer le workspace Jenkins
            cleanWs()
        }
    }
}
