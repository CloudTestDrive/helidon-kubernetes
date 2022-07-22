output "server_public_ip" {
  description = "public ip address of server API endpoint"
  value       = module.server.server_ip
}
output "subnet_ids" {
  description = "OCID's of the various networks created"
  value       = module.network.subnet_ids
}
output "lb_nsg_id" {
  description = "OCID's of the lb subnet network security group"
  value       = module.network.agent_nsg_id
}