project_id  = "dev"
name_prefix = "project-dev"

subnets = {
  "project-dev-subnet" = ["192.168.11.0/24"]
}

instance_resources = {
  cores     = 4
  memory_gb = 8
}

