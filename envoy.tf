locals {
  // optional envoy container for AWS AppMesh
  envoy_container_defaults = {
    name                   = var.app_mesh.container_name
    image                  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ecr-public/appmesh/aws-appmesh-envoy:v1.24.0.0-prod"
    essential              = true
    mountPoints            = []
    portMappings           = []
    readonlyRootFilesystem = false
    user                   = "1337:1337"
    volumesFrom            = []

    environment = [
      {
        name  = "APPMESH_RESOURCE_ARN",
        value = "arn:aws:appmesh:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:mesh/${var.app_mesh.mesh_name}/virtualNode/${var.service_name}"
      }
    ]

    healthCheck = {
      retries = 3
      command = [
        "CMD-SHELL",
        "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"
      ]
      timeout     = 2
      interval    = 5
      startPeriod = 10
    }

    ulimits = [
      {
        name      = "nofile"
        softLimit = 1024 * 32
        hardLimit = 4096 * 32
      }
    ]
    logConfiguration = var.firelens.enabled && var.firelens.opensearch_host != "" ? {
      logDriver = "awsfirelens",
      options = {
        Aws_Auth        = "Off"
        Aws_Region      = data.aws_region.current.name
        Host            = var.firelens.opensearch_host
        Logstash_Format = "true"
        Logstash_Prefix = "${var.service_name}-envoy"
        Name            = "opensearch"
        Port            = "443"
        tls             = "On"
        Trace_Output    = "Off"
      }
      } : (var.cloudwatch_logs.enabled ? {
        logDriver = "awslogs"
        options = {
          awslogs-group : aws_cloudwatch_log_group.containers[0].name
          awslogs-region : data.aws_region.current.name
          awslogs-stream-prefix : var.app_mesh.container_name
        }
    } : null)
  }
  envoy_container = var.app_mesh.enabled ? jsonencode(module.envoy_container_definition.merged) : ""
}

module "envoy_container_definition" {
  source  = "Invicton-Labs/deepmerge/null"
  version = "0.1.5"

  maps = [
    local.envoy_container_defaults,
    var.app_mesh.container_definition
  ]
}

data "aws_iam_policy" "appmesh" {
  count = var.app_mesh.enabled && var.task_role_arn == "" ? 1 : 0

  arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
}

resource "aws_iam_role_policy_attachment" "appmesh" {
  count = var.app_mesh.enabled && var.task_role_arn == "" ? 1 : 0

  role       = aws_iam_role.ecs_task_role[count.index].name
  policy_arn = data.aws_iam_policy.appmesh[count.index].arn
}

resource "aws_iam_role_policy_attachment" "acm" {
  count = var.app_mesh.enabled && var.task_role_arn == "" ? 1 : 0

  policy_arn = aws_iam_policy.acm[count.index].arn
  role       = aws_iam_role.ecs_task_role[count.index].name
}

resource "aws_iam_policy" "acm" {
  count = var.app_mesh.enabled && var.task_role_arn == "" ? 1 : 0

  name   = "${var.service_name}-acm-${data.aws_region.current.name}"
  policy = data.aws_iam_policy_document.acm[count.index].json
}

data "aws_iam_policy_document" "acm" {
  count = var.app_mesh.enabled && var.task_role_arn == "" ? 1 : 0

  statement {
    sid       = "ACMExportCertificateAccess"
    actions   = ["acm:ExportCertificate", "acm:DescribeCertificate"]
    resources = [var.app_mesh.tls.acm_certificate_arn]
  }

  statement {
    sid       = "ACMCertificateAuthorityAccess"
    actions   = ["acm-pca:GetCertificateAuthorityCertificate"]
    resources = [var.app_mesh.tls.root_ca_arn]
  }
}
