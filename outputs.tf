output "vm_name" {
  description = "Simulated VM name."
  value       = local.linux_vm_name
}

output "vm_resources" {
  description = "Simulated VM resources (cores/memory/subnet)."
  value       = terraform_data.vm.input
}

output "subnet_name" {
  description = "Subnet name (simulated)."
  value       = local.subnet_name
}

output "subnet_cidr" {
  description = "Subnet CIDR (simulated)."
  value       = local.subnet_cidr
}

output "bucket_name" {
  description = "Simulated bucket name (directory name)."
  value       = local.bucket_name
}

output "bucket_path" {
  description = "Simulated bucket path on VPS filesystem."
  value       = local.bucket_path
}

output "vm_resources_file" {
  description = "Path to generated vm_resources.json file."
  value       = local_file.vm_resources.filename
}
