output "bastion_public_ip" {
  description = "public ip address of bastion host"
  value       = local.bastion_public_ip
}

output "ssh_to_server" {
  description = "convenient command to ssh to the server host"
  value       = "ssh -i ${var.ssh_private_key_path} -J opc@${local.bastion_public_ip} opc@${local.server_private_ip}"
}