variable "env" {
    type =  string  #required
}
variable "appname" {
       type = string
}
variable "vpc" {
    type = string
}
variable "public_cidr_block" {
    type = list(any)
}
variable "private_cidr_block" {
     type = list(any)
}
variable "availability_zones" {
  type = list(string) #required
}
variable "tags" {
    type = map(string)
    default = {}
}