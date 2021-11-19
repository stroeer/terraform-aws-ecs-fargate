# add data sources used in more than one tf file here

locals {
  root_path = split("/", abspath(path.root))
  tf_stack  = join("/", slice(local.root_path, length(local.root_path) - 1, length(local.root_path)))
  mesh_name = "apps"
}
