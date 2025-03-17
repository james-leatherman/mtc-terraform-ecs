# mtc-terraform-ecs

This project uses Terraform to manage infrastructure and deploy applications on AWS ECS. It was built as part of the [More Than Certified](https://morethancertified.com/) course series. The purpose of this project was to demonstrate how to use dynamic values to provide a configuration model for setting up AWS resources and containerized applications at scale. It uses the latest Terraform (v1.11.1) recommendations for ensuring forward compatibility with AWS provider (v5.91.0) configuration.

## Project Structure

The `aws-tf` root contains two modules: The first is for establishing AWS infrastructure, and the second is for iterating through application definitions for deployment. 

The `mgmt` root holds files pertaining to the Terraform backend, and allows for both S3 and HCP state management.

## Modules

### infra

The `infra` module is responsible for setting up the foundational infrastructure, including VPC, subnets, security groups, load balancers, internet gateway, and ECS cluster.

- **main.tf**: Defines the main infrastructure resources. Contains logic to apportion subnet CIDR ranges based on the count of subnets requested. It also dynamically checks for available AZs in the region, and distributes subnets 1:1 with AZs.

- **sg.tf**: Defines security groups and their rules. Ingress and egress rules are broken out into separate modules, rather than being defined inline.

- **variables.tf**: Defines input variables for the module. In this case, we pass in the desired CIDR block, number of subnets, and a set of allowed IPs.

- **outputs.tf**: Defines output values for the module. These are typically ARNs and IDs.

### app

The `app` module is responsible for deploying applications to ECS, including building Docker images, pushing them to ECR, and creating ECS task definitions and services.

- **main.tf**: Defines the resources for building, pushing Docker images, and deploying ECS services - in this case, of Fargate type. Also creates load balancers with associated listners and target groups.

- **variables.tf**: Defines input variables for the module, which in this case are network and path paramters for the load balancer, as well as the load balancer ARN.

## Files

### aws-tf Files

- **main.tf**
- **modules/**

  - **app/**
    - **main.tf**
    - **variables.tf**
    - **apps/**: Contains Dockerfiles for different applications.
      - **api/Dockerfile**: hello-world
      - **ui/Dockerfile**: nginx

  - **infra/**:
    - **main.tf**
    - **sg.tf**
    - **variables.tf**
    - **outputs.tf**

- **providers.tf**: Specifies the required providers and version constraints.
- **backend.tf**: Configures the backend for storing Terraform state. In this case, we pass in the selection from the `mgmt` module.
- **dev.s3.tfbackend**: S3 bucket for dev state storage.
- **prod.s3.tfbackend**: S3 bucket for prod state storage.

### mgmt Files

- **main.tf**: Here we can manage the backend for Terraform state. We can store in separate workspaces in S3, and also import the state from S3 to HCP.

## License

This project is licensed under the MIT License.