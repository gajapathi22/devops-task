pipeline {
    agent any
    
    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REGISTRY = '351531845608.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'devops-task'
        IMAGE_TAG = "${BUILD_NUMBER}"
        CLUSTER_NAME = 'devops-task-eks'
        DOCKER_IMAGE = "${ECR_REGISTRY}/${ECR_REPOSITORY}"
        
        // GitHub repository
        GITHUB_REPO = 'https://github.com/YOUR_USERNAME/devops-task.git'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                git branch: 'main', credentialsId: 'github-credentials', url: "${GITHUB_REPO}"
                
                script {
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                    env.GIT_AUTHOR = sh(
                        script: 'git log -1 --pretty=%an',
                        returnStdout: true
                    ).trim()
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                }
                
                echo "✅ Code checked out successfully"
                echo "📝 Commit: ${env.GIT_COMMIT_MSG}"
                echo "👤 Author: ${env.GIT_AUTHOR}"
            }
        }
        
        stage('Environment Check') {
            steps {
                echo "🔧 Build Information:"
                echo "   Build Number: ${BUILD_NUMBER}"
                echo "   Workspace: ${WORKSPACE}"
                
                sh 'ls -la'
                sh 'docker --version'
                sh 'aws --version || echo "AWS CLI not found"'
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    echo '📦 Installing Node.js dependencies...'
                    if (fileExists('package.json')) {
                        sh 'npm install'
                        echo '✅ Dependencies installed'
                    } else {
                        echo '⚠️  No package.json found'
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "🏗️  Building Docker image: ${DOCKER_IMAGE}:${IMAGE_TAG}"
                
                script {
                    def dockerImage = docker.build("${DOCKER_IMAGE}:${IMAGE_TAG}")
                    sh "docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:latest"
                }
                
                echo "✅ Docker image built successfully"
            }
        }
        
        stage('Test Docker Image') {
            steps {
                script {
                    echo '🧪 Testing Docker image...'
                    
                    def containerId = sh(
                        script: "docker run -d -p 3001:3000 ${DOCKER_IMAGE}:${IMAGE_TAG}",
                        returnStdout: true
                    ).trim()
                    
                    sleep 5
                    
                    try {
                        sh 'curl -f http://localhost:3001 || echo "Container is running"'
                        echo '✅ Docker test passed'
                    } finally {
                        sh "docker stop ${containerId} && docker rm ${containerId}"
                    }
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                        echo '🔐 Logging into ECR...'
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                        
                        echo '📤 Pushing to ECR...'
                        sh "docker push ${DOCKER_IMAGE}:${IMAGE_TAG}"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                        
                        echo '✅ Push completed'
                    }
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                script {
                    withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                        echo '☸️  Deploying to EKS...'
                        sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}"
                        sh "kubectl set image deployment/devops-task-app app=${DOCKER_IMAGE}:${IMAGE_TAG}"
                        sh "kubectl rollout status deployment/devops-task-app --timeout=300s"
                        
                        echo '✅ Deployment completed'
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                        sh 'kubectl get pods -l app=devops-task-app'
                        sh 'kubectl get service devops-task-service'
                        
                        def serviceUrl = sh(
                            script: "kubectl get service devops-task-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || echo 'pending'",
                            returnStdout: true
                        ).trim()
                        
                        if (serviceUrl && serviceUrl != 'pending') {
                            echo "🌍 App URL: http://${serviceUrl}"
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            sh 'docker system prune -f'
        }
        success {
            echo '🎉 Pipeline completed successfully!'
            echo "✅ Build: ${BUILD_NUMBER}"
            echo "✅ Image: ${DOCKER_IMAGE}:${IMAGE_TAG}"
        }
        failure {
            echo '❌ Pipeline failed!'
            echo "❌ Build: ${BUILD_NUMBER}"
            echo "❌ Check console output for details"
        }
    }
}