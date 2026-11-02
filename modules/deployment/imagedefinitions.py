# Converts the ECR source action output (imageDetail.json) into the ECS deploy action input (imagedefinitions.json).
# Inlined into the buildspec via `python -c '...'`, so this file must not contain single quotes.
import json
import os

with open("imageDetail.json", "r") as json_file:
    image_uri = json.load(json_file).get("ImageURI")
    container_name = os.environ.get("CONTAINER_NAME")

    # dynamic sidecars, CodeBuild resolves the SSM parameters (type PARAMETER_STORE) into SIDE_CAR_<container name>=<image uri>
    sidecars = [
        {"name": key[len("SIDE_CAR_"):], "imageUri": value}
        for key, value in os.environ.items()
        if key.startswith("SIDE_CAR_")
    ]

    # output file format: https://docs.aws.amazon.com/codepipeline/latest/userguide/file-reference.html
    with open("imagedefinitions.json", "w") as outfile:
        json.dump([{"name": container_name, "imageUri": image_uri}] + sidecars, outfile)
