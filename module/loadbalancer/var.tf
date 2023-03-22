variable "env" {
    type = string #required
}
variable "appname" {
    type = string #required
}
variable "tags" {
    type = map(string)
    default = {}
}
variable "internal" {
  type = string
}
variable "load_balancer_type" {
  type = string
}
variable "vpc" {
  type = string
}
variable "subnets"{
  type = list(string)
}
variable "security_groups" {
    type = set(string)
}