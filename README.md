# A Greater Codespace with JIT Ubuntu and Terraform

![ubuntu-desktop](https://github.com/terry-richards/jit-developer/assets/141377286/66715d74-1669-404b-998b-7c71881927fb "A JIT developer environment — ready to rumble")

One area of dissonance in today’s increasingly distributed organization relates to the elevated security requirements typically associated with a developer’s machine. The rapidly depreciating cost of these assets tug on ROI while the typical configured security footprint opens up additional vectors for compromise.

With productivity suites now progressive web apps (PWAs) and most if not all required day-to-day activities available from a simple browser, the era of bring-your-own-device (BYOD) or even providing simple Chromebooks appears upon us. We believe this is a great step forward organizationally and for IT.

As this transition ferments, developers are presented with a rapidly evolving landscape of streaming development platforms like Github Codespaces and Amazon Cloud9. Like many infrastructure as service (IaS) solutions, there is an obvious tradeoff between cost and convenience.  As well, we find these solutions limiting in ability to simulate a fully functional development environment. 

The approach outlined here creates a just-in-time (JIT) developer environment in AWS using EC2 and the latest LTS version of Ubuntu Linux Server. We’ll leverage the power of Terraform to automate the whole process. 

As a developer, the ability to spin up a fully-functional development environment at a moment’s notice is an invaluable asset. This environment can be scaled to the needs of the specific project and recycled when no longer required.

For the administrator, having the tools to orchestrate the life-cycle of these resources in a secure environment that you can limit footprint, easily audit and fully control is also invaluable.

All code developed for this article can be found in the [companion repository](https://github.com/terry-richards/jit-developer).

## Why Terraform and JIT?

Terraform is an open-source Infrastructure as Code (IaC) tool, which means you can use it to define and provide data center infrastructure using a declarative configuration language. With Terraform, you can manage and provision your infrastructure across multiple cloud service providers consistently.

The JIT approach, on the other hand, reduces cost and increases productivity by ensuring that resources are provisioned only when required and de-provisioned when no longer needed. Combining this approach with Terraform's idempotent and declarative nature, we can swiftly create, modify, and tear down environments without unnecessary resource utilization or cost.

## Prerequisites

This article was prepared on an Ubuntu Linux machine using a bash terminal. You will need to adjust for your OS of choice.   

Before we begin, you'll need to have the following:

- An AWS account
- AWS CLI [installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) on your machine
- Terraform [installed](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) on your machine
- A VNC client (we recommend [TigerVNC](https://tigervnc.org/))

Performing these actions as the root AWS user carries unreasonable security risks. Hence, it is always recommended to create a specific AWS profile. In this tutorial, we'll use a profile named "terraform". 

You can create this profile by logging into the [AWS CloudShell](https://aws.amazon.com/cloudshell/) and executing this convenient one-liner:

```bash
USER_TO_CREATE='terraform' && \
aws iam create-group --group-name $USER_TO_CREATE && \
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name $USER_TO_CREATE && \
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name $USER_TO_CREATE && \
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name $USER_TO_CREATE && \
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess  --group-name $USER_TO_CREATE && \
aws iam create-user --user-name $USER_TO_CREATE && \
aws iam add-user-to-group --user-name $USER_TO_CREATE --group-name $USER_TO_CREATE && \
aws iam create-access-key --user-name $USER_TO_CREATE
```

This will return an Access Key ID and a Secret Access Key. To add these to your local AWS profiles, use the AWS CLI command:

```bash
aws configure --profile terraform
```

and enter the returned values.

![aws-profile.png](https://github.com/terry-richards/jit-developer/assets/141377286/ad96c982-6a01-4efc-9f2f-cfcb56c3e30b "Creating the Terraform profile from the cli")

## Setting Up the Infrastructure

Let's start by setting up our AWS infrastructure. We'll use Terraform for this, along with some environment variables to keep our code dynamic and reusable.

**Step 1: Configure your environment**

Start by [cloning the repository](https://github.com/terry-richards/jit-developer) and navigating to the root folder. 

First, we'll set up our environment using the [setenv](https://github.com/terry-richards/jit-developer/blob/main/setenv) file, which contains all the necessary environment variables. Source the file using:
```bash
source setenv
```

These values must be sourced prior to running any terraform command.

Note the TF_VAR convention.  If you prefer tfvar files have at it. This approach works well when translating to CI/CD. Adjust these values to your particular needs.

**Step 2: Create the state bucket and state lock**

Now, let's set up our Terraform backend. We will use S3 to hold state and DynamoDB to control concurrency which is a pretty typical configuration.

IMPORTANT: Amazon requires a unique bucket name by region regardless of visibility, so at minimum, you will need to change the ORG variable in the [setenv](https://github.com/terry-richards/jit-developer/blob/main/setenv) file which composes the bucket name (see file for note).

Use the files in `prerequisites/01-aws-terraform-state` to create the state bucket and state lock.

You can run by navigating to that directory and executing the following two lines:
```bash
source ../../setenv && terraform init
terraform apply
```

![state.png](https://github.com/terry-richards/jit-developer/assets/141377286/57f396b6-1ab1-4b8e-80da-7cc15a5bcece "S3 bucket and DynamoDB table successfully created.")

**Step 3: Create the VPC and subnet**

Next, we'll create a VPC and subnet for our developer environment. This is an extremely simple example and should not be considered production-grade. Use the files in `prerequisites/02-developer-vpc` to create them.

As before, navigate to the directory and execute the following two lines, this time passing the newly configured state values to the terraform init process:

```bash
source ../../setenv && terraform init \
  -backend-config="bucket=${TF_VAR_terraform_state_bucket_prefix}" \
  -backend-config="dynamodb_table=${TF_VAR_terraform_state_lock_table}" 
terraform apply
```

![network.png](https://github.com/terry-richards/jit-developer/assets/141377286/9c5fec99-68a5-4d14-a357-322644a836e2 "VPC and subnet creation")

**Step 4: Update environment file and run the main Terraform file**

With our vpc and subnet in place, we'll update the [setenv](https://github.com/terry-richards/jit-developer/blob/main/setenv) file with their IDs. This is a good time to review the other variables and set as appropriate. 

![setenv.png](https://github.com/terry-richards/jit-developer/assets/141377286/7f079662-3a97-4a62-8421-3e80d2904768 "Update your configuration")

Finally, it's time to bring everything together. We can now run our main Terraform file, which is responsible for creating our EC2 instance.

Navigate to the root directory of the project and execute:
```bash
source setenv && terraform init \
  -backend-config="bucket=${TF_VAR_terraform_state_bucket_prefix}" \
  -backend-config="dynamodb_table=${TF_VAR_terraform_state_lock_table}"
terraform apply
```

![instance-created.png](https://github.com/terry-richards/jit-developer/assets/141377286/b25fb3b7-b557-46e9-818d-5d9c2b307e91 "EC2 instance created!")

Terraform will automatically fetch the latest LTS version of Ubuntu Server and install it on our EC2 instance.

Once Terraform completes the setup, it will create a configured output directory. This directory will contain the private key file for accessing the instance and a markdown file with detailed instructions on how to connect to the instance via SSH and VNC.

![instance-details.png](https://github.com/terry-richards/jit-developer/assets/141377286/5d8ce195-104b-468d-aca6-6f5d4f263b98 "Markdown file containing instance details and connection instructions")

## Bootstrapping the Developer Environment

Our bootstrapping process is split into three areas for readability: os-level, desktop, and developer tools. [Cloud-init](https://cloud-init.io/) uses the provided bootstrap files and runs them with the `runcmd` to install the developer environment.

The scripts are part of our Terraform code and can be found in the `bootstrap-files` [directory of our GitHub repository](https://github.com/terry-richards/jit-developer/tree/main/bootstrap-files).

Our Terraform setup also creates a shutdown cron job that stops the instance nightly at 10:00 PM. This helps in managing costs by ensuring the instance is stopped when not in use.  This can be overridden by the developer if logged in but should be used as a guide to seek balance. 😉

Once the bootstrapping process has completed and the system reboots, you will be presented with a ready-to-use development environment:


![ubuntu-desktop](https://github.com/terry-richards/jit-developer/assets/141377286/66715d74-1669-404b-998b-7c71881927fb "Ubuntu 22.04 minimal desktop with developer tools installed.")

## Cleanup

Run the following to clean up all terraform-managed resources created in this tutorial:

```bash
source setenv && terraform destroy --auto-approve \
  && cd prerequisites/02-developer-vpc/ && terraform destroy --auto-approve \
  && cd ../../prerequisites/01-aws-terraform-state/ && terraform destroy --auto-approve \
  && cd ../..
```

And then finish by logging into the [AWS CloudShell](https://aws.amazon.com/cloudshell/) and executing this one-liner:

```bash
USER_TO_DELETE='terraform' && \
for key in $(aws iam list-access-keys --user-name $USER_TO_DELETE --query 'AccessKeyMetadata[*].AccessKeyId' --output text); \
do aws iam delete-access-key --user-name $USER_TO_DELETE --access-key-id $key; done && \
aws iam remove-user-from-group --user-name $USER_TO_DELETE --group-name $USER_TO_DELETE && \
aws iam delete-user --user-name $USER_TO_DELETE && \
for policy in $(aws iam list-attached-group-policies --group-name $USER_TO_DELETE --query 'AttachedPolicies[*].PolicyArn' --output text); \
do aws iam detach-group-policy --group-name $USER_TO_DELETE --policy-arn $policy; done && \
aws iam delete-group --group-name $USER_TO_DELETE
```

## Enhancements

While this setup offers a lot of benefits, there's always room for improvement. Here are a few enhancements you might consider:

- **Self Service**: Provide a simple script or service that the developer can access to start their instance in the morning.  Add the capability to request an entirely new instance or destroy the current one.
- **Portability**: By integrating this setup with an existing developer drive (EBS GP3 volume perhaps), you could make the developer's home directory portable, while the rest of the environment remains immutable.
- **Cost-efficiency**: Using spot instances and a scaling group could provide cost benefits, depending on the criticality of workloads.  While you might get preempted, the sg could be configured to spin up a new instance by the time you got kicked.  Tea break!
- **Scalability**: Using Terraform's `for_each` construct, you could maintain a kiosk of developer instances.
- **CI/CD Integration**: Integrate the setup with CI/CD tools like GitHub Actions, Azure DevOps, or AWS CodePipeline.
- **Cross-cloud Compatibility**: Refactor the setup to work with other cloud platforms, like Azure or Google Cloud.

## Conclusion

Hopefully, this article has provided some architectural inspiration and practical steps to create a just-in-time developer environment in AWS using Terraform and Ubuntu Server.

Be sure to subscribe for upcoming articles where we will tackle some of the enhancements discussed above and more generally, delve into the rapidly evolving enterprise architecture landscape. Until then, happy coding!

You can find the complete code and detailed explanation on our [GitHub repository](https://github.com/terry-richards/jit-developer).
