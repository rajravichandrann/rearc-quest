This folder contains IAC terraform to create the following resources to host the quest app.
ECR
ECS Cluster
Application Loadbalancer
ALB Security group
Target Group 
ECS Service security group
Task Definition

#Improvements/things I could have done.
I could have added a null resource I belive for this part, but I manually pushed the Docker image to the ECR (didnt have much time)
I could have also variable the name of resources and ports, created a VPC using terraform and hosted application within private subnet.
I dont own a domain  so skipping the tls part since I cant create a ACM cert. I have not generated certs locally previously and imported to AWS(dont have much time to look into this)

Once you have the docker image built and in the ECR repo this template will help you with implementing infrastructure.
CLI: terraform init 
     terraform plan
     terraform apply #if the plan looks ok


The rearc-quest folder conatins the Dockerfile