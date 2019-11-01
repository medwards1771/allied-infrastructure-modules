#!/bin/bash
# This script can be used to create a deployment package from the Python code in this repo. It builds a Docker image
# with the Python code and all of its dependencies and extracts those contents into a build directory on the host OS.
# This build directory can be uploaded as a Lambda function.

set -e

readonly image_name="gruntwork/sample-lambda-function"
readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Building Docker image in $script_dir and tagging it with name $image_name"
docker build -t "$image_name" "$script_dir"

echo "Creating Docker container from image $image_name"
container_id=$(docker create "$image_name")

# Note that we put a /. (slash, dot) at the end of the container build dir to ensure its contents are always copied
# into the host build folder. Without the /., the behavior would differ based on whether the host build folder already
# existed. See the docker cp documentation for details: https://docs.docker.com/engine/reference/commandline/cp/#extended-description
readonly build_dir_host="$script_dir/build"
readonly build_dir_container="/usr/src/lambda/."

echo "Copying $build_dir_container from Docker container $container_id to $build_dir_host on host"
docker cp "$container_id:$build_dir_container" "$build_dir_host"

echo "Removing container $container_id"
# Due to a CircleCI limitation, docker rm operations will fail. This doesn't matter during a CI job, so for now, just
# add the || true at the end to make sure the whole build doesn't fail as a result. For more info, see:
# https://discuss.circleci.com/t/docker-error-removing-intermediate-container/70
docker rm "$container_id" || true

echo
echo "When using the long-running-scheduled Terraform module, set the source_dir parameter as follows:"
echo
echo "export TF_VAR_source_path=$build_dir_host"
echo