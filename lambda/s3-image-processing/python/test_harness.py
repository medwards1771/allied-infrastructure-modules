# A simple test harness that can be used to run and test the lambda function locally. It creates a mock event object
# for the function based on user input, decodes the base64-encoded image data returned by the lambda function, and
# writes it to disk.

import logging
import argparse
import base64
from index import handler

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def run_handler_locally(aws_region, s3_bucket, image_filename):
    event = {
        "aws_region": aws_region,
        "s3_bucket": s3_bucket,
        "image_filename": image_filename,
    }

    logger.info('Running lambda function locally with event object:', event)
    result = handler(event, None)

    image_contents = decode_base64(result['image_base64'])
    write_image_to_disk(image_filename, image_contents)

def decode_base64(image_contents_base64):
    logger.info('Decoding base64 data returned by lambda function')
    return base64.b64decode(image_contents_base64)

def write_image_to_disk(image_filename, image_contents):
    logger.info('Writing decoded image contents to file %s' % image_filename)
    with open(image_filename, "wb") as image_file:
        image_file.write(image_contents)

parser = argparse.ArgumentParser(description='Run the lambda function locally and write the image it returns to disk')

parser.add_argument('--bucket', help='The name of the S3 bucket to download from', required=True)
parser.add_argument('--filename', help='The name of the file in the S3 bucket to download', required=True)
parser.add_argument('--region', help='The AWS region where the S3 bucket lives', required=True)

args = parser.parse_args()

run_handler_locally(args.region, args.bucket, args.filename)
