variable "name_prefix" {
  description = "(Optional) - Name prefix for project."
  type        = string
  default     = "project"
}

variable "project_id" {
  description = "(Required) - Environment/project id (dev/stage/prod)."
  type        = string
}

variable "instance_resources" {
  description = <<EOF
(Required) Simulated VM resources:
  - cores: vCPU count
  - memory_gb: RAM in GiB
EOF

  type = object({
    cores     = number
    memory_gb = number
  })
}

variable "subnets" {
  description = "(Optional) - A map of subnet names to CIDR ranges (simulation)."
  type        = map(list(string))
  default = {
    "private-subnet" = ["192.168.10.0/24"]
  }
}

