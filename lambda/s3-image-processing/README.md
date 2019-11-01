# S3 Image Processing Lambda Module

This Terraform Module can be used to deploy an [AWS Lambda](https://aws.amazon.com/lambda/) function that downloads an
image from S3, processes it, and returns the results encoded in base64.

Note that to keep the example as simple as possible, we've put the code for this function directly in the 
infrastructure-modules repo. In real-world usage, you'd probably define your lambda functions in a
separate repo.





## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules in this repo.
* See [variables.tf](./variables.tf) for all the variables you can set on this module.





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
can also run it locally by calling that entrypoint. [test_harness.py](python/test_harness.py) is an example of a simple 
script you can run locally that will execute the handler, decode the base64-encoded image in the return value, and 
write it to disk:

```bash
python python/test_harness.py --region us-east-1 --bucket lambda-s3-example-images-test --filename gruntwork-logo.png
```

See also the [lambda-build example](/examples/lambda-build) to see how you can execute build and packaging steps for
your code before uploading it using Terraform.


### Test in AWS

If you deploy this function to AWS, to test it, open up the [AWS Console UI](https://console.aws.amazon.com/lambda/home), 
find the function, click the "Test" button, and enter test data that looks something like this:
   
```json
{
  "aws_region": "us-east-1",
  "s3_bucket": "lambda-s3-example-images-test",
  "image_filename": "gruntwork-logo.png"
}
```
    
Click "Save and test" and AWS will show you the log output and returned value in the browser.




## Core concepts

For more info on AWS Lambda, check out [package-lambda](https://github.com/gruntwork-io/package-lambda).
