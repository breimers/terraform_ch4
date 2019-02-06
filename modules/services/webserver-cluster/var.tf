#configure serverport
variable "serverport"{
  description = "Sets the default port for contacting server"
  default = 8080
}

#configure elbport
variable "elbport"{
  description = "Sets the default routing port for ELB"
  default = 80
}

