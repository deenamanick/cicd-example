
## Type Jenkins Password

You will get the jenkins password from the below location. 

/var/lib/jenkins/secrets/initialAdminPassword

![image](https://github.com/user-attachments/assets/3b387037-48e9-432e-9775-24abe58ada21)


## Install default plugins.

![image](https://github.com/user-attachments/assets/89a2e95f-ff77-4a2f-956f-0ec072bb4ee8)

## Create first Admin User

![image](https://github.com/user-attachments/assets/23730b47-6e09-4edf-9740-8073fdac9506)

## Jenkins is ready

![image](https://github.com/user-attachments/assets/d22c98ba-3079-49ce-b53c-11b61bc1fe66)


## Install ssh agent and restart Jenkins

![image](https://github.com/user-attachments/assets/54407077-d13f-4664-901e-7bc1ccc433e9)

## Create a pipeline

![image](https://github.com/user-attachments/assets/17bfe8ac-9f62-441f-9056-35ebec525dda)

## Git checkout Checking

![image](https://github.com/user-attachments/assets/9af05228-2030-482c-9dd2-c6fd719a0536)

## Build now


![image](https://github.com/user-attachments/assets/ec4af5c3-b379-4bb8-8999-aad6ee3ffb54)

## Jenkins console output

![image](https://github.com/user-attachments/assets/baca0203-d6ad-4d70-a23c-4fecf71e8081)

## click on pipeline script

![image](https://github.com/user-attachments/assets/f58e5d80-bce7-4ad4-b69d-7e3359e0fb54)

## withCredentials: Both Credentails to variables

![image](https://github.com/user-attachments/assets/9e7d31c5-b5f8-4b99-9cfc-8d429616e93f)


## Adding docker hub password

![image](https://github.com/user-attachments/assets/678b5a3e-20df-4a88-b90a-cf676f71d3fd)

## Github webhook

![image](https://github.com/user-attachments/assets/45dca027-9530-4698-adff-0e83e11c67c0)

Generate Secret for webhook integration with jenkins

![image](https://github.com/user-attachments/assets/449c12c9-3c5e-4445-b13e-9ae589209097)

![image](https://github.com/user-attachments/assets/14207fcf-70cc-41e7-9fca-5dbf1a2da1f7)

Successfully intergrated with jenkins

![image](https://github.com/user-attachments/assets/4a1d1eea-7a4c-4c2d-a2fc-3b2c6e92c189)

Do empty push to run the pipeline

![image](https://github.com/user-attachments/assets/2fdb9fb2-474a-455a-908f-64cc3e8833a1)

When you see different between local repo and remote repo, use the following command to fix the issue

![image](https://github.com/user-attachments/assets/65a7e77a-b977-428a-a52a-f359520aee17)

Add ssh agent for kubernetes server login

![image](https://github.com/user-attachments/assets/dd6c4eda-4d21-462a-ae2b-182bb0f16620)



```


node {
    stage('Git Checkout') {
        git branch: 'main', url: 'https://github.com/deenamanick/cicd-example.git'
    }
    stage('Docker Build Image') {
        // Copy Dockerfile to home if needed — adjust as per Docker context
       sh 'sudo -u azureuser /bin/cp /var/lib/jenkins/workspace/pipeline_demo/Dockerfile /home/azureuser/'
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
     stage ('Copy the files jenkins server to kubernetes server') {
          sshagent(['kubernetes-server']) {
          sh 'scp -o StrictHostKeyChecking=no /var/lib/jenkins/workspace/pipeline_demo/front-webiste.yaml azureuser@node1:/home/azureuser/'
          sh 'scp -o StrictHostKeyChecking=no /var/lib/jenkins/workspace/pipeline_demo/ansiblefile.yaml azureuser@node1:/home/azureuser/'
        }
     }
     stage ('Deploy application into Kubernetes') {
          sshagent(['kubernetes-server']) {
          sh 'ssh -o StrictHostKeyChecking=no azureuser@node1 cd /home/azureuser/plays'
          sh 'ssh -o StrictHostKeyChecking=no azureuser@node1 ansible-playbook -i /home/azureuser/plays/inventory.ini /home/azureuser/ansiblefile.yaml'
          sh 'ssh -o StrictHostKeyChecking=no azureuser@node1 kubectl get pod'
        }
     }
     }
}

```
