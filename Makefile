DESCRIBE           := $(shell git fetch --all > /dev/null && git describe --match "v*" --always --tags)
DESCRIBE_PARTS     := $(subst -, ,$(DESCRIBE))
# 'v0.2.0'
VERSION_TAG        := $(word 1,$(DESCRIBE_PARTS))
# '0.2.0'
VERSION            := $(subst v,,$(VERSION_TAG))
# '0 2 0'
VERSION_PARTS      := $(subst ., ,$(VERSION))

MAJOR              := $(word 1,$(VERSION_PARTS))
MINOR              := $(word 2,$(VERSION_PARTS))
PATCH              := $(word 3,$(VERSION_PARTS))

ifeq ($(BUMP), major)
NEXT_VERSION		:= $(shell echo $$(($(MAJOR)+1)).0.0)
else ifeq ($(BUMP), minor)
NEXT_VERSION		:= $(shell echo $(MAJOR).$$(($(MINOR)+1)).0)
else
NEXT_VERSION		:= $(shell echo $(MAJOR).$(MINOR).$$(($(PATCH)+1)))
endif
NEXT_TAG 			:= v$(NEXT_VERSION)

STACKS = $(shell find . -not -path "*/\.*" -iname "*.tf" | sed -E "s|/[^/]+$$||" | sort --unique)
ROOT_DIR := $(shell pwd)

all: fmt validate tflint trivy

init: ## Initialize a Terraform working directory
	@echo "+ $@"
	@terraform init -backend=false > /dev/null

.PHONY: fmt
fmt: ## Checks config files against canonical format
	@echo "+ $@"
	@terraform fmt -check=true -recursive

.PHONY: validate
validate: ## Validates the Terraform files
	@echo "+ $@"
	@for s in $(STACKS); do \
		echo "validating $$s"; \
		terraform -chdir=$$s init -backend=false > /dev/null; \
		terraform -chdir=$$s validate || exit 1 ;\
    done;

.PHONY: tflint
tflint: ## Runs tflint on all Terraform files
	@echo "+ $@"
	@tflint --init
	@for s in $(STACKS); do \
		echo "tflint $$s"; \
		terraform -chdir=$$s init -backend=false -lockfile=readonly > /dev/null; \
		tflint --chdir=$$s --format=compact --config=$(ROOT_DIR)/.tflint.hcl || exit 1;\
	done;

trivy: ## Runs trivy on all Terraform files
	@echo "+ $@"
	@trivy config  --exit-code 1 --severity HIGH --tf-exclude-downloaded-modules .

bump ::
	@echo bumping version from $(VERSION_TAG) to $(NEXT_TAG)
	@sed -i '' s/$(VERSION)/$(NEXT_VERSION)/g README.md

.PHONY: check-git-clean
check-git-clean:
	@git diff-index --quiet HEAD || (echo "There are uncomitted changes"; exit 1)

.PHONY: check-git-branch
check-git-branch: check-git-clean
	git fetch --all --tags --prune
	git checkout main

.PHONY: check-bump
check-bump:
	@if [ -z "$(BUMP)" ]; then \
		echo "Error: BUMP variable must be specified for release."; \
		echo "Usage: make release BUMP=major|minor|patch"; \
		exit 1; \
	fi
	@if [ "$(BUMP)" != "major" ] && [ "$(BUMP)" != "minor" ] && [ "$(BUMP)" != "patch" ]; then \
		echo "Error: BUMP must be one of: major, minor, patch"; \
		echo "Usage: make release BUMP=major|minor|patch"; \
		exit 1; \
	fi

release: check-bump check-git-branch bump
	git add README.md
	git commit -vsam "Bump version to $(NEXT_TAG)"
	git tag -a $(NEXT_TAG) -m "$(NEXT_TAG)"
	git push origin $(NEXT_TAG)
	git push
	# create GH release if `gh cli` is installed and authenticated
	@if ! command -v gh >/dev/null 2>&1 ; then 											\
		echo "gh CLI is not installed. Please create the release manually on GitHub." ; \
		exit 0 ; 																		\
	fi;
	@if ! gh auth status >/dev/null 2>&1 ; then 											\
		echo "gh CLI is not authenticated. Please run 'gh auth login' or create the release manually on GitHub." ; \
		exit 0 ; 																		\
	fi;
	@gh release create $(NEXT_TAG) --generate-notes
	@echo "GitHub release created successfully for tag $(NEXT_TAG) at: https://github.com/stroeer/terraform-aws-ecs-fargate/releases/tag/$(NEXT_TAG)"

.PHONY: update
update: ## Upgrades Terraform core and providers constraints recursively using https://github.com/minamijoyo/tfupdate
	@echo "+ $@"
	@command -v tfupdate >/dev/null 2>&1 || { echo >&2 "Please install tfupdate: 'brew install minamijoyo/tfupdate/tfupdate'"; exit 1; }
	@tfupdate terraform -v ">= 1.5.7" -r .
	@tfupdate provider aws -v ">= 6.0" -r .
	@tfupdate provider archive -v ">= 2.2" -r .
	@tfupdate provider null -v ">= 3.2" -r .

help: ## Display this help screen
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
