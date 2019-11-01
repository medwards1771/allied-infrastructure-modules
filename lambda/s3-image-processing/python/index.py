import logging
import boto3
import base64

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

"""Main entrypoint for the Lambda function. It does the following:

   1. Download an image from S3
   2. Return the image contents, base64 encoded
"""
def handler(event, context):
    logger.info('Received event %s', event)

    aws_region = read_required_param(event, 'aws_region')
    s3_bucket = read_required_param(event, 's3_bucket')
    image_filename = read_required_param(event, 'image_filename')

    image_download_path = download_file_from_s3(s3_bucket, image_filename, aws_region)
    process_image(image_download_path)
    image_base64_encoded = base64_encode_file(image_download_path)

    return {'image_base64': image_base64_encoded}

def read_required_param(event, param_name):
    value = event.get(param_name)
    if not value:
        raise Exception("Required parameter '%s' not found in event object" % param_name)
    return value

def process_image(file_path):
    logger.info('TODO: Fill in your image processing code here for %s!' % file_path)

def download_file_from_s3(s3_bucket, filename, aws_region):
    session = boto3.session.Session(region_name=aws_region)
    s3_client = session.client('s3')

    image_download_path = "/tmp/%s" % filename
    logger.info('Download file %s from S3 bucket %s in %s into %s' % (filename, s3_bucket, aws_region, image_download_path))

    s3_client.download_file(s3_bucket, filename, image_download_path)
    return image_download_path

def base64_encode_file(file_path):
    logger.info('Base64 encoding file %s' % file_path)

    with open(file_path, "rb") as image_file:
        return base64.b64encode(image_file.read())