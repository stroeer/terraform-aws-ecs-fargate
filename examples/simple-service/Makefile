# can be overriden during make invocation
# MODE=apply make TARGET
MODE ?= plan
SERVICE_NAME ?= test-backend

ACCOUNT := 053041861227
TF_BACKEND_CFG := -backend-config=bucket=terraform-state-${ACCOUNT}-$${TF_VAR_region} -backend-config=region=$${TF_VAR_region} -backend-config=encrypt=true -backend-config=dynamodb_table=terraform-lock

% :: export TF_VAR_region := eu-west-1
tf ::
	rm -f .terraform/terraform.tfstate || true
	terraform init $(TF_BACKEND_CFG) -backend-config=key=regional/service/$(SERVICE_NAME)/terraform.tfstate
	terraform $(MODE)