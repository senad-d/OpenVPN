variable "project" {
  type        = string
  description = "Project name"
}

variable "project_id" {
  type        = string
  description = "Project id"
}

variable "resources_name" {
  type        = string
  description = "Resource name"
}

variable "env" {
  type        = string
  description = "Environment"
}

variable "company" {
  type        = string
  description = "Company name"
}

variable "organization" {
  type        = string
  description = "Organizational unit"
}

variable "email" {
  type        = string
  description = "SES Email address"
}

variable "admin" {
  type        = string
  description = "Administrator Email address"
}

variable "ssh_key" {
  type        = string
  description = "SSH key for OpenVPN instance"
}

variable "certificate_duration_days" {
  type        = string
  description = "VPN certificat duration defined in days"
}
