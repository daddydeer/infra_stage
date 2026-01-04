# Случайный суффикс (как в курсе) — 8 символов, только нижний регистр/цифры
resource "random_string" "bucket_name" {
  length  = 8
  special = false
  upper   = false
}

locals {
  # "Имя бакета" (папки) как в курсе: prefix + terraform-bucket + random
  bucket_dir_name = "${var.name_prefix}-terraform-bucket-${random_string.bucket_name.result}"
  bucket_path     = "${path.module}/${local.bucket_dir_name}"

  # "Сеть/подсеть" — берём первый ключ из map (как в примере курса)
  subnet_name = keys(var.subnets)[0]
  subnet_cidr = var.subnets[local.subnet_name][0]
}

# --- "VM" (симуляция ресурсов) ---
# Лучше использовать terraform_data, чтобы изменение выглядело как "~ update in-place"
resource "terraform_data" "vm" {
  input = {
    name       = "${var.name_prefix}-linux-vm"
    cores      = var.instance_resources.cores
    memory_gb  = var.instance_resources.memory_gb
    subnet     = local.subnet_name
    subnet_cidr = local.subnet_cidr
    project_id = var.project_id
  }
}

# (опционально) Запишем эти "ресурсы VM" в файл для наглядности
resource "local_file" "vm_resources" {
  filename = "${path.module}/vm_resources.json"
  content  = jsonencode(terraform_data.vm.input)
}

# --- "Bucket" (папка на диске) ---
resource "null_resource" "bucket_dir" {
  triggers = {
    dir = local.bucket_path
  }

  provisioner "local-exec" {
    command = "mkdir -p '${local.bucket_path}'"
  }
}

resource "local_file" "bucket_keep" {
  depends_on = [null_resource.bucket_dir]

  filename = "${local.bucket_path}/.keep"
  content  = "Simulated object storage bucket for ${var.project_id}\n"
}

