node {
    stage('Git Checkout') {
        git branch: 'main', url: 'https://github.com/deenamanick/cicd-example.git'
    }

    stage('Docker Build Image') {
        // Copy Dockerfile to home if needed — adjust as per Docker context
        sh 'sudo cp /var/lib/jenkins/workspace/pipeline-demo/Dockerfile /home/azureuser/'
        
        // Build Docker image using the copied Dockerfile
        sh 'docker image build -t $JOB_NAME:v1.$BUILD_ID -f Dockerfile .'
    }

    stage('Docker Image Tagging') {
        sh 'docker image tag $JOB_NAME:v1.$BUILD_ID deenamanick/$JOB_NAME:v1.$BUILD_ID'
        sh 'docker image tag $JOB_NAME:v1.$BUILD_ID deenamanick/$JOB_NAME:latest'
    }

    stage('Push Docker Image to Docker Hub') {
        withCredentials([string(credentialsId: 'dockerhub_pipeline_passwd', variable: 'dockerhub_pipeline_passwd')]) {
            sh 'docker login -u deenamanick -p $dockerhub_pipeline_passwd'
            sh 'docker image push deenamanick/$JOB_NAME:v1.$BUILD_ID'
            sh 'docker image push deenamanick/$JOB_NAME:latest'
        }
    }
}
