# Long-running, Scheduled Lambda Module

This Terraform Module can be used to deploy an [AWS Lambda](https://aws.amazon.com/lambda/) function. This function
will run on a scheduled basis, similar to a cron job, and it will deploy a Docker container that runs as a Task in an
ECS Cluster. This demonstrates how to:

1. Write a Lambda function.
1. Create a deployment package for the function that has 3rd party dependencies (see `src/requirements.txt`).
1. Run an ECS Task for any work that takes longer than allowed by Lambda's 5 minute time limit.
1. Run and test the code locally using Docker.

Note that to keep the example as simple as possible, we've put the code for this function directly in the
infrastructure-modules repo into the `src` folder. In real-world usage, you'd probably define your
lambda functions in a separate repo.





## How do you use this module?

* [Build the deployment package using Docker](#build-the-deployment-package-using-docker)
* [Deploy the deployment package using Terraform](#deploy-the-deployment-package-using-terraform)


### Build the deployment package using Docker

The code for this Lambda function is in the `src` folder and is packaged using Docker. To build a deployment package
from the code:

1. Install [Docker](https://www.docker.com/).
1. Run `./src/build.sh`

When the script is done, it'll output the path to the deployment package. Copy this path, as you'll need it for the
next step!


### Deploy the deployment package using Terraform

* See the [root README](/README.md) for instructions on using Terraform modules in this repo.
* See [variables.tf](./variables.tf) for all the variables you can set on this module. You'll need to set the `source_path`
  parameter to the deployment package path outputted by the `build.sh` script.





## What is AWS Lambda?

AWS Lambda lets you run code without provisioning or managing servers. You simply write your code in one of the
supported languages (Python, JavaScript, Java, etc), use this module to upload that code to AWS Lambda, and AWS will
execute that lambda function whenever you trigger it (there are many ways to trigger a lambda function, including
manually in the UI, or on a scheduled basis, or via API calls through API Gateway, or via events such as an SNS
message), without you having to run any servers.




## How do you test the Lambda function?

There are two ways to test the Lambda function:

1. [Test locally](#test-locally)
1. [Test in AWS](#test-in-aws)


### Test locally

The code you write for a Lambda function is just regular code with a well-defined entrypoint (the "handler"), so you
can also run it locally by calling that entrypoint yourself. The example Python app includes a `test_harness.py` file
that is configured to allow you to run your code locally. This test harness script is configured as the `ENTRYPOINT`
for the Docker container, so you can test locally as follows:

```bash
docker-compose run lambda <ECS_CLUSTER_NAME> <ECS_TASK_NAME> <AWS_REGION>
```

For example, to deploy revision 3 of an ECS Task called `my-task` into an ECS cluster called `my-cluster` in
`us-east-1`, you'd run:

```bash
docker-compose run lambda my-cluster my-task:3 us-east-1
```

Note, if your lambda functions call other lambda functions (e.g. by calling `InvokeTask` in the AWS APIs), then to test
all of those locally, you may want to:

1. Extract the `InvokeTask` call into a separate function.
1. Provide a way to override what that function does so that in the dev environment, rather than calling AWS, it
   directly triggers the other function locally.


### Test in AWS

To test in AWS:

1. Use `build.sh` to create the deployment package.
1. Use [package-lambda](https://github.com/gruntwork-io/package-lambda) to upload the deployment package to AWS Lamda.
1. Open up the [AWS Console UI](https://console.aws.amazon.com/lambda/home), find the function, click the "Test" button,
   and enter test data that looks something like this:

```json
{
  "ecs_cluster": "my-cluster",
  "ecs_task": "my-task:3",
  "aws_region": "us-east-1"
}
```

Click "Save and test" and AWS will show you the log output and returned value in the browser.





## How does the build process work?

With AWS Lambda, your [deployment package](http://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html)
(zip file) must contain ALL of the dependencies for your app already bundled within it. Moreover, since Lambda
functions run on Amazon Linux, all of those dependencies must be compiled specifically for Amazon Linux. This example
creates the deployment package as follows:

1. Build the code using [Docker](https://www.docker.com/), using an [Amazon Linux
   image](http://docs.aws.amazon.com/AmazonECR/latest/userguide/amazon_linux_container_image.html) as the base image,
   as shown in the example [Dockerfile](python/Dockerfile). This Docker image installs all of your dependencies and
   source code into the `/usr/src/lambda` folder.

1. When developing and testing locally, you can run your Lambda code directly in the Docker image. You can
   [mount](https://docs.docker.com/engine/tutorials/dockervolumes/#mount-a-host-directory-as-a-data-volume) the
   `src` directory from your host OS into `/usr/src/lambda/src` so that your local changes are visible
   immediately in the container.

1. To deploy to AWS, you use `docker cp` to copy the `/usr/src/lambda` folder to a local path (all of this is done
   by the [build.sh script](python/build.sh)) and then run `terraform apply` to zip up that local path and deploy it to
   AWS.





## Core concepts

For more info on AWS Lambda, check out [package-lambda](https://github.com/gruntwork-io/package-lambda).
