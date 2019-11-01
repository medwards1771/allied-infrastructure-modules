import logging
import boto3
import os
import json

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

"""The entrypoint for the Lambda function. It runs the ECS Task in the ECS cluster, as specified in the event object. 
   If those values are not specified in the event object, they are read from environment variables. This serves
   as an example of the following:
   
   1. How to write and deploy Lambda functions.
   2. How to run an ECS Task for any work that takes longer than allowed by Lambda (time limit: 5 minutes).
   3. How to build a deployment package with dependencies. This code uses the boto3 library, so it'll only work if all 
      dependencies were installed correctly. See the README for instructions.
"""
def handler(event, context):
    logger.info('Received event %s', event)

    ecs_cluster = get_required_property(event, 'ecs_cluster')
    ecs_task = get_required_property(event, 'ecs_task')
    aws_region = get_required_property(event, 'aws_region')

    session = boto3.session.Session(region_name=aws_region)
    ecs_client = session.client('ecs')

    logger.info('Running ECS Task %s in ECS Cluster %s in %s' % (ecs_task, ecs_cluster, aws_region))

    response = ecs_client.run_task(cluster=ecs_cluster, taskDefinition=ecs_task, count=1)

    failures = response.get('failures')
    if failures:
        raise Exception('Got failures after calling run_task: %s' % json.dumps(failures))

    tasks = response.get('tasks')
    if not tasks:
        raise Exception('Response did not contain any tasks, so ECS Task %s might not have been started' % ecs_task)

    task = tasks[0]
    return {'taskArn': task.get('taskArn')}

def get_required_property(event, property_name):
    value = event.get(property_name)
    if not value:
        value = os.environ.get(property_name)
    if not value:
        raise Exception("Could not find value for property '%s' in event object or as an environment variable." % property_name)
    return value
