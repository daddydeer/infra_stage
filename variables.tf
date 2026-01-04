variable "name_prefix" {
  description = "(Optional) - Name prefix for project."
  type        = string
  default     = "project"
}

variable "project_id" {
  description = "(Required) - Идентификатор окружения/проекта (dev/stage/prod). Используется для меток/имён."
  type        = string
}

variable "instance_resources" {
  description = <<EOF
  (Required) Симуляция ресурсов ВМ:
    - cores: количество vCPU
    - memory_gb: объём RAM в ГБ
  EOF

  type = object({
    cores     = number
    memory_gb = number
  })
}

variable "subnets" {
  description = "(Optional) - A map of subnet names to their CIDR block ranges (симуляция)."
  type        = map(list(string))
  default = {
    "private-subnet" = ["192.168.10.0/24"]
  }
}

