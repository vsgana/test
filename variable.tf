variable "region" {
  type = string
  description = "this is the region"
}

variable "ami_id" {
  type = string
  description = "ami is required"
}

variable "instance_type" {
  type=string
  description = "instance type is reqired"
}

variable "stage" {
  description = "Deployment stage"
  type        = string
}

