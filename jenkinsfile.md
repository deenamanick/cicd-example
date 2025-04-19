
## Type Jenkins Password

/var/lib/jenkins/secrets/initialAdminPassword

## Install default plugins.

![image](https://github.com/user-attachments/assets/89a2e95f-ff77-4a2f-956f-0ec072bb4ee8)

## Create first Admin User

![image](https://github.com/user-attachments/assets/23730b47-6e09-4edf-9740-8073fdac9506)

## Jenkins is ready

![image](https://github.com/user-attachments/assets/d22c98ba-3079-49ce-b53c-11b61bc1fe66)





```

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

```
