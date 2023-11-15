variable "CLUSTER_NAME" {
  description = "name of eks cluster"
  type        = string
  
}
variable "EKS_VERSION" {
  description = "name of eks cluster"
  type        = string
  default     = "1.27"
}
variable "VPC_ID" {
  description = "VPC ID"
  type        = string
}
variable "SUBNETS_IDS" {
  description = "specify subnet in list format"
  type    = list(string)
}
variable "ENV" {
  description = "dev or prod or mngt"
  type        = string
}
variable "OD_INSTANCE_TYPE" {
  type    = list(string)
}
variable "SPOT_INSTANCE_TYPE" {
  type    = list(string)
}
variable "SSH_KEY" {
  description = "key name"
  type        = string
  default     ="sp-key"
}

