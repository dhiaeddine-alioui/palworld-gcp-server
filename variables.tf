variable "privatekeypath" {
  type    = string
  default = "./PalServerSSHKey"
}

variable "publickeypath" {
  type    = string
  default = "./PalServerSSHKey.pub"
}

variable "user" {
  type    = string
  default = "user"
}