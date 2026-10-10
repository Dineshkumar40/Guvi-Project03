pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = 'YOUR_DOCKERHUB_USERNAME'
        // Image repositories
        DEV_IMAGE  = "${DOCKERHUB_USERNAME}/dev"
        MAIN_IMAGE = "${DOCKERHUB_USERNAME}/main"
        // Static placeholder used inside scripts
        IMAGE_PLACEHOLDER = 'IMAGE_PLACEHOLDER'
        DOCKER_CREDENTIALS = 'dockerhub-creds'
        EC2_CREDENTIALS = 'ec2-ssh'
        EC2_HOST = 'YOUR_EC2_PUBLIC_IP'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Docker Image') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'dev') {
                        env.DOCKER_IMAGE =
                            "${env.DEV_IMAGE}:${env.BUILD_NUMBER}"
                        echo "Branch: DEV"
                        echo "Docker Image: ${env.DOCKER_IMAGE}"
                    }

                    else if (env.BRANCH_NAME == 'main') {
                        env.DOCKER_IMAGE =
                            "${env.MAIN_IMAGE}:${env.BUILD_NUMBER}"
                        echo "Branch: MAIN"
                        echo "Docker Image: ${env.DOCKER_IMAGE}"
                    }

                    else {
                        error("Unsupported branch: ${env.BRANCH_NAME}")
                    }
                }
            }
        }

        stage('Prepare Build Script') {
            steps {
                sh """
                    sed -i 's|${IMAGE_PLACEHOLDER}|${DOCKER_IMAGE}|g' build.sh
                    chmod +x build.sh
                """
            }
        }

        stage('Build Application') {
            steps {
                sh './build.sh'
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS}",
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | \
                        docker login \
                        -u "$DOCKER_USERNAME" \
                        --password-stdin
                    '''
                }
            }
        }

        stage('Push DEV Image') {
            when {
                branch 'dev'
            }
            steps {
                sh """
                    docker push ${DEV_IMAGE}:${BUILD_NUMBER}
                """
            }
        }

        stage('Push MAIN Image') {
            when {
                branch 'main'
            }
            steps {
                sh """
                    docker push ${MAIN_IMAGE}:${BUILD_NUMBER}
                """
            }
        }

        stage('Deploy Production') {
            when {
                branch 'main'
            }
            steps {
                sshagent(credentials: ["${EC2_CREDENTIALS}"]) {
                    sh """
                        echo "Connecting to Production EC2..."

                        ssh -o StrictHostKeyChecking=no \
                        ubuntu@${EC2_HOST} \
                        'cd ~/react-app && \
                         sed -i "s|${IMAGE_PLACEHOLDER}|${DOCKER_IMAGE}|g" deploy.sh && \
                         chmod +x deploy.sh && \
                         ./deploy.sh'

                    """
                }
            }
        }
    }


    post {
        success {
            echo "======================================"
            echo "Pipeline completed successfully."
            echo "======================================"
        }

        failure {
            echo "======================================"
            echo "Pipeline failed."
            echo "======================================"
        }
        
        always {
            sh 'docker logout || true'
        }
    }
}
