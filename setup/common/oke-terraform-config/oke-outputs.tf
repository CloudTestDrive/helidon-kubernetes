output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = module.oke.cluster_id
}
output "vcn_id" {
  description = "id of vcn where oke is created. use this vcn id to add additional resources"
  value       = module.oke.vcn_id
}
output "subnet_ids" {
  description = "map of subnet ids (worker, int_lb, pub_lb) used by OKE."
  value       = module.oke.subnet_ids
}
output "int_lb_nsg" {
  description = "id of default NSG that can be associated with the internal load balancer"
  value       = module.oke.int_lb
}
output "pub_lb_nsg" {
  description = "id of default NSG that can be associated with the internal load balancer"
  value       = module.oke.pub_lb
}
output "kubeconfig" {
  description = "convenient command to set KUBECONFIG environment variable before running kubectl locally"
  value       = "export KUBECONFIG=generated/kubeconfig"
}