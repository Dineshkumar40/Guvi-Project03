pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = 'dineshkumar40'
        // Image repositories
        DEV_IMAGE  = "${DOCKERHUB_USERNAME}/dev"
        MAIN_IMAGE = "${DOCKERHUB_USERNAME}/main"
        // Static placeholder used inside scripts
        IMAGE_PLACEHOLDER = 'IMAGE_PLACEHOLDER'
        DOCKER_CREDENTIALS = 'docker-creds'
        EC2_CREDENTIALS = 'deploy-server'
        EC2_HOST = '13.204.85.50'
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
                    sh '''
                        set -eu
                        echo "Creating deployment directory on EC2..."

                        ssh -o StrictHostKeyChecking=no \
                            ubuntu@"$EC2_HOST" \
                            'mkdir -p ~/react-app'

                        echo "Copying deployment files..."

                        scp -o StrictHostKeyChecking=no \
                            docker-compose.yml \
                            ubuntu@"$EC2_HOST":~/react-app/docker-compose.yml

                        scp -o StrictHostKeyChecking=no \
                            deploy.sh \
                            ubuntu@"$EC2_HOST":~/react-app/deploy.sh

                        echo "Replacing image placeholders on EC2..."

                        ssh -o StrictHostKeyChecking=no \
                            ubuntu@"$EC2_HOST" \
                            "cd ~/react-app && \
                            sed -i 's|IMAGE_PLACEHOLDER|${DOCKER_IMAGE}|g' docker-compose.yml && \
                            sed -i 's|IMAGE_PLACEHOLDER|${DOCKER_IMAGE}|g' deploy.sh && \
                            chmod +x deploy.sh && \
                            echo 'Compose image:' && \
                            grep 'image:' docker-compose.yml && \
                            echo 'Deploy script image:' && \
                            grep 'DOCKER_IMAGE=' deploy.sh && \
                            ./deploy.sh"
                    '''
                }
            }
        }

        
        stage('Deploy Uptime Kuma') {
            when {
                branch 'main'
            }

            steps {
                sshagent(credentials: ["${EC2_CREDENTIALS}"]) {
                    sh '''
                        set -eu

                        echo "Creating monitoring directory..."

                        ssh -o StrictHostKeyChecking=no \
                            ubuntu@"$EC2_HOST" \
                            'mkdir -p ~/uptime-kuma'

                        echo "Copying monitoring Compose file..."

                        scp -o StrictHostKeyChecking=no \
                            monitoring/docker-compose.yml \
                            ubuntu@"$EC2_HOST":~/uptime-kuma/docker-compose.yml

                        echo "Starting Uptime Kuma..."

                        ssh -o StrictHostKeyChecking=no \
                            ubuntu@"$EC2_HOST" \
                            'cd ~/uptime-kuma && \
                            sudo docker compose pull && \
                            sudo docker compose up -d && \
                            sudo docker compose ps'

                        echo "Uptime Kuma deployment completed."
                    '''
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
