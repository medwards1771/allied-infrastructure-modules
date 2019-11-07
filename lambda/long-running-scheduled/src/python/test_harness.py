# A simple test harness that can be used to run and test the lambda function locally. It reads parameters from the
# command-line and passes them to the lambda function handler.

import logging
import argparse
from index import handler

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def run_handler_locally(ecs_cluster, ecs_task, aws_region):
    event = {
        "ecs_cluster": ecs_cluster,
        "ecs_task": ecs_task,
        "aws_region": aws_region
    }

    logger.info('Running lambda function locally with event object:', event)
    result = handler(event, None)

    logger.info('Response from lambda function: %s' % result)

parser = argparse.ArgumentParser(description='Run the lambda function locally')
parser.add_argument('ecs_cluster', help='The short name or full ARN of an ECS cluster')
parser.add_argument('ecs_task', help='The family:revision or full ARN of an ECS Task to run in the ECS cluster')
parser.add_argument('aws_region', help='The AWS region the cluster is running in')
args = parser.parse_args()

run_handler_locally(args.ecs_cluster, args.ecs_task, args.aws_region)
