output "bastion_public_ip" {
  description = "public ip address of bastion host"
  value       = modules.terraform-oci-k3s.bastion_public_ip
}