variable "region" {
  type = "string"
  default = "us-west-2"
  description = "AWS region for this infrastructure"
}

variable "instance_size" {
  type = "string"
  default = "t2.nano"
  description = "AWS EC2 instance size for the OpenVPN Server"
}

variable "cert_key_country" {
  type = "string"
  description = "The 'KEY_COUNTRY' Certificate Authority parameter"
}

variable "cert_key_province" {
  type = "string"
  description = "The 'KEY_PROVINCE' Certificate Authority parameter"
}

variable "cert_key_city" {
  type = "string"
  description = "The 'KEY_CITY' Certificate Authority parameter"
}

variable "cert_key_org" {
  type = "string"
  description = "The 'KEY_ORG' Certificate Authority parameter"
}

variable "cert_key_email" {
  type = "string"
  description = "The 'KEY_EMAIL' Certificate Authority parameter"
}

variable "cert_key_ou" {
  type = "string"
  description = "The 'KEY_OU' Certificate Authority parameter"
}
