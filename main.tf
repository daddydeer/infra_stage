# Генерируем случайный суффикс для имени "бакета" (папки):
# 8 символов, без спецсимволов и без заглавных букв
resource "random_string" "bucket_name" {
  length  = 8
  special = false
  upper   = false
}

# Получаем публичный IP этой VPS (Terraform запускается на самой VPS)
data "http" "public_ip" {
  url = "https://api.ipify.org"
}

# Локальные значения — всё, что часто используется или нужно вычислить один раз
locals {
  # Публичный IP (убираем перевод строки)
  public_ip = chomp(data.http.public_ip.response_body)

  # "Имя виртуальной машины" (симуляция)
  linux_vm_name = "${var.name_prefix}-linux-vm"

  # "Подсеть" (симуляция): берём первый ключ из map subnets
  subnet_name = keys(var.subnets)[0]
  subnet_cidr = var.subnets[local.subnet_name][0]

  # "Бакет" (симуляция): имя папки с префиксом и случайным суффиксом
  bucket_name = "${var.name_prefix}-terraform-bucket-${random_string.bucket_name.result}"

  # Путь к папке "бакета" на диске VPS
  bucket_path = "${path.module}/${local.bucket_name}"

  # Файл, куда пишем "ресурсы ВМ" для наглядности
  vm_resources_file = "${path.module}/vm_resources.json"

  # Локально сгенерированный файл стартовой страницы nginx
  nginx_index_file = "${path.module}/index.nginx-debian.html"
}

# "Виртуальная машина" (симуляция ресурсов).
# terraform_data удобен тем, что изменения будут показываться как "~ update in-place"
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

# Для удобства — записываем параметры "ВМ" в JSON-файл рядом с проектом
resource "local_file" "vm_resources" {
  filename = local.vm_resources_file
  content  = jsonencode(terraform_data.vm.input)
}

# "Бакет" (симуляция): создаём папку на диске VPS
resource "null_resource" "bucket_dir" {
  triggers = {
    dir = local.bucket_path
  }

  provisioner "local-exec" {
    command = "mkdir -p '${local.bucket_path}'"
  }
}

# "Бакет" (симуляция): создаём файл-маркер внутри папки
resource "local_file" "bucket_keep" {
  depends_on = [null_resource.bucket_dir]

  filename = "${local.bucket_path}/.keep"
  content  = "Simulated object storage bucket for ${var.project_id}\n"
}

# Генерируем HTML-страницу nginx из шаблона (templatefile)
resource "local_file" "nginx_index" {
  filename = local.nginx_index_file

  content = templatefile("${path.module}/nginx-index.html.tftpl", {
    public_ip         = local.public_ip
    bucket_name       = local.bucket_name
    bucket_path       = local.bucket_path
    vm_name           = local.linux_vm_name
    subnet_name       = local.subnet_name
    subnet_cidr       = local.subnet_cidr
    vm_resources_json = jsonencode(terraform_data.vm.input)
  })
}

# Устанавливаем nginx и подменяем стандартную стартовую страницу
resource "null_resource" "nginx" {
  # ВАЖНО: нельзя использовать filesha1() по файлу, которого ещё нет на этапе plan.
  # Поэтому считаем хэш от содержимого страницы (оно известно до apply).
  triggers = {
    page_sha1 = sha1(local_file.nginx_index.content)
  }

  # Гарантируем, что сначала будет сгенерирован файл страницы
  depends_on = [local_file.nginx_index]

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      # Обновляем список пакетов и ставим nginx
      apt-get update -y
      apt-get install -y nginx

      # Кладём нашу страницу на место стандартной
      cp '${local_file.nginx_index.filename}' /var/www/html/index.nginx-debian.html

      # Включаем nginx в автозапуск и перезапускаем сервис
      systemctl enable nginx
      systemctl restart nginx

      # Если используется UFW — откроем порт 80 (HTTP)
      if command -v ufw >/dev/null 2>&1; then
        ufw allow 80/tcp || true
      fi
    EOT
  }
}

