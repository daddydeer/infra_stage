# Случайный суффикс (как в курсе) — 8 символов, только нижний регистр/цифры
resource "random_string" "bucket_name" {
  length  = 8
  special = false
  upper   = false
}

# Local values — все имена/часто используемые значения в одном месте
locals {
  linux_vm_name = "${var.name_prefix}-linux-vm"

  subnet_name = keys(var.subnets)[0]
  subnet_cidr = var.subnets[local.subnet_name][0]

  bucket_name = "${var.name_prefix}-terraform-bucket-${random_string.bucket_name.result}"
  bucket_path = "${path.module}/${local.bucket_name}"

  vm_resources_file = "${path.module}/vm_resources.json"
}

# --- "VM" (симуляция ресурсов) ---
# terraform_data удобно тем, что при изменениях будет показывать "~ update in-place"
resource "terraform_data" "vm" {
  input = {
    name        = local.linux_vm_name
    cores       = var.instance_resources.cores
    memory_gb   = var.instance_resources.memory_gb
    subnet      = local.subnet_name
    subnet_cidr = local.subnet_cidr
    project_id  = var.project_id
  }
}

# (опционально) Запишем эти "ресурсы VM" в файл для наглядности
resource "local_file" "vm_resources" {
  filename = local.vm_resources_file
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

