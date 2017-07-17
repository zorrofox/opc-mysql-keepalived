
variable user {
  default = "<OPC_USER>"
}
variable password {
  default = "<OPC_PASS>"
}
variable domain {
  default = "<OPC_DOMAIN>"
}
variable endpoint {
  default = "https://api-z50.compute.us6.oraclecloud.com/"
}

variable ssh_user {
  description = "User account for ssh access to the image"
  default     = "opc"
}

variable ssh_private_key {
  description = "File location of the ssh private key"
  default     = "~/keys/orcl.pem"
}

variable ssh_public_key {
  description = "File location of the ssh public key"
  default     = "~/keys/orcl_pub.pem"
}
