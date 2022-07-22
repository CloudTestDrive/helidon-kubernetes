output "bastion_public_ip" {
  description = "public ip address of bastion host"
  value       = modules.bastion_public_ip
}