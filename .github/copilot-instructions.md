# AWS ECS Fargate Terraform Module

AWS ECS Fargate Terraform Module provides comprehensive infrastructure-as-code for deploying containerized applications on AWS ECS Fargate with ALB integration, autoscaling, blue/green deployments, service discovery, App Mesh integration, and observability features.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Setup
- Install required tools:
  - `curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -`
  - `sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"`
  - `sudo apt-get update && sudo apt-get install terraform -y`
  - `wget https://github.com/terraform-linters/tflint/releases/download/v0.50.3/tflint_linux_amd64.zip && unzip tflint_linux_amd64.zip && sudo mv tflint /usr/local/bin/`
  - `curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin`
  - `curl -sSLo terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.18.0/terraform-docs-v0.18.0-linux-amd64.tar.gz && tar -xzf terraform-docs.tar.gz && sudo mv terraform-docs /usr/local/bin/`
  - `pip install pre-commit`

### Build, Validate, and Test
- Initialize Terraform (takes 11 seconds, NEVER CANCEL):
  - `terraform init -backend=false` -- Set timeout to 60+ seconds
- Format and validate code:
  - `make fmt` -- Formats all Terraform files (< 1 second)
  - `make validate` -- Validates all modules and examples (34 seconds, NEVER CANCEL). Set timeout to 60+ seconds
  - `terraform fmt -check=true -recursive` -- Quick format check (< 1 second)
  - `terraform validate` -- Validates current directory (3 seconds)
- Run security and linting:
  - `make trivy` -- Security scanning (2 seconds, NEVER CANCEL)
  - `make tflint` -- KNOWN ISSUE: May fail with GitHub API rate limits (403 errors) in CI environments. This is expected and not a code problem
- Run all quality checks:
  - `make all` -- Runs fmt, validate, tflint, trivy in sequence (40+ seconds total, NEVER CANCEL). Set timeout to 90+ seconds

### Pre-commit Hooks
- Install pre-commit hooks: `pre-commit install`
- Run pre-commit on all files: `pre-commit run --all-files` -- Takes 15 seconds, NEVER CANCEL. Set timeout to 60+ seconds
- KNOWN ISSUES in pre-commit:
  - TFLint may fail with "403" GitHub API errors - this is expected in CI environments
  - All other hooks should pass (terraform_fmt, terraform_validate, terraform_trivy, terraform_docs)

### Working with Examples
- Complete example in `examples/complete/` demonstrates full module usage
- Initialize complete example: `cd examples/complete && terraform init -backend=false` (1-2 seconds)
- Plan will fail without AWS credentials - this is expected: `terraform plan` (fails after ~9 seconds with credential errors)
- Example shows: VPC creation, ECS cluster, ALB setup, service configuration, autoscaling

## Validation

### Manual Validation Requirements
- ALWAYS run `make validate` before committing changes - this validates all modules, examples, and configurations
- ALWAYS run `make fmt` to ensure consistent formatting
- ALWAYS run `make trivy` to check for security misconfigurations
- NEVER CANCEL validation commands - they can take 30+ seconds to complete
- You cannot fully test AWS resource creation without valid AWS credentials, but validation and planning work without them

### Testing Scenarios
- Validate module syntax: Run `terraform validate` in root and all subdirectories
- Test complete example: `cd examples/complete && terraform init -backend=false && terraform validate`
- Verify formatting: `terraform fmt -check=true -recursive` should return no changes
- Security scan: `make trivy` should show no HIGH or CRITICAL findings
- Integration test: `terraform plan` in examples (will fail at AWS API calls without credentials - expected)

## Common Tasks

### Repository Structure
```
├── .github/workflows/static-analysis.yaml  # CI pipeline
├── .pre-commit-config.yaml                 # Pre-commit hook configuration
├── .tflint.hcl                            # TFLint configuration
├── Makefile                               # Build automation
├── README.md                              # Full documentation
├── examples/complete/                     # Complete usage example
├── modules/                               # Sub-modules
│   ├── deployment/                        # CodePipeline deployment module
│   └── ecr/                              # ECR repository module
├── main.tf, variables.tf, outputs.tf     # Main module files
└── *.tf                                   # Feature-specific Terraform files
```

### Key Module Features
- **ALB Integration**: Target groups, listener rules, health checks
- **Autoscaling**: Application autoscaling based on CPU/memory metrics
- **Blue/Green Deployments**: CodePipeline + CodeDeploy automation
- **Service Discovery**: AWS Cloud Map integration
- **App Mesh**: Envoy sidecar and service mesh configuration
- **Observability**: CloudWatch logs, OpenTelemetry, Fluent Bit log routing
- **Security**: IAM roles, security groups, ECR image scanning

### File Navigation
- Main module logic: `main.tf` (ECS service and task definition)
- ALB configuration: `alb.tf` (target groups and listener rules)
- IAM permissions: `iam.tf` (task and execution roles)
- Container definitions: `container_definition.tf` (main app container)
- Sidecar containers: `envoy.tf`, `fluentbit.tf`, `otel.tf`
- CloudWatch logging: `cloudwatch_logs.tf`
- Route53/Service Discovery: `route53.tf`
- Module inputs: `variables.tf` (100+ input variables)
- Module outputs: `outputs.tf` (ECR URLs, IAM roles, target groups)

### Usage Patterns
- Basic service: Set `cluster_id`, `service_name`, `vpc_id`, `container_port`
- With ALB: Configure `target_groups` and `https_listener_rules`
- With autoscaling: Set `appautoscaling_settings` map
- With blue/green deployments: Enable `create_deployment_pipeline = true`
- With service mesh: Configure `app_mesh` settings

### Troubleshooting
- **TFLint failures**: GitHub API rate limiting in CI is common, not a code issue
- **AWS credential errors**: Expected when running `terraform plan/apply` without valid credentials
- **Module not found**: Run `terraform init -backend=false` to download modules
- **Format issues**: Run `terraform fmt -recursive` to auto-fix formatting
- **Validation errors**: Check for required variables and provider version constraints

### Timing Expectations
- `terraform init`: ~11 seconds (NEVER CANCEL, set 60+ second timeout)
- `make validate`: ~34 seconds for all modules (NEVER CANCEL, set 60+ second timeout)
- `make fmt`: < 1 second
- `make trivy`: ~2 seconds
- `make all`: ~40 seconds total (NEVER CANCEL, set 90+ second timeout)
- `pre-commit run --all-files`: ~15 seconds (NEVER CANCEL, set 60+ second timeout)

### Version Requirements
- Terraform: >= 1.5.7 (tested with 1.13.1)
- AWS Provider: >= 6.0
- TFLint: 0.50.3+ (with AWS plugin)
- Trivy: 0.66.0+
- terraform-docs: 0.18.0+

### Commit and PR Conventions
This repository uses [Conventional Commits](https://www.conventionalcommits.org/) for PR titles and follows semantic versioning:

**Required PR Title Format**: `<type>: <description>`

**Allowed Types**:
- `fix:` - Bug fixes and patches
- `feat:` - New features and enhancements  
- `docs:` - Documentation changes
- `ci:` - CI/CD pipeline changes
- `chore:` - Maintenance tasks, dependency updates
- `refactor:` - Code refactoring without functional changes

**Examples**:
- `fix: resolve CloudWatch Logs IAM permissions assignment`
- `feat: add App Mesh integration support`
- `docs: update README with new usage examples`
- `chore: upgrade Terraform provider to v6.0`

**Validation**: PR titles are automatically validated by GitHub Actions. PRs with incorrect titles will fail the `pr title` check.

Always run the known-working validation steps and use the Make targets for consistency across environments.
