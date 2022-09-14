
output "k3s_servers_ips" {
  description = "vcn id"
  value       = module.k3s.k3s_servers_ips
} 
output "k3s_workers_ips" {
  description = "vcn id"
  value       = module.k3s.k3s_workers_ips
} 
output "vcn_id" {
  description = "vcn id"
  value       = module.k3s.default_oci_core_vcn_id
} 
output "control_plane_subnet_id" {
  description = "vcn id"
  value       = module.k3s.default_oci_core_subnet10_id
} 
output "workers_subnet_id" {
  description = "vcn id"
  value       = module.k3s.oci_core_subnet11_id
} 
output "k3s_primary_server_ip" {
  description = "vcn id"
  value       = module.k3s.k3s_primary_server_ip
} 
output "public_lb_nsg_id" {
  description = "vcn id"
  value       = module.k3s.public_lb_nsg_id
} 
output "lb_to_workers_nsg_id" {
  description = "vcn id"
  value       = module.k3s.lb_to_instances_http_id
} 
output "lb_to_control_plane_id" {
  description = "vcn id"
  value       = module.k3s.lb_to_instances_kubeapi_id
}