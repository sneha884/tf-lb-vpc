provider "aws" {
  profile = "sneha"
  region  = "us-east-1"
}

module "vpc" {
  source             = "../../modules/vpc"
  env                = "prod"
  appname            = "apps"
  vpc                = "10.0.0.0/16"
  public_cidr_block  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_cidr_block = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  tags = {
    Owner = "prod-team"
  }
}

module "lb" {
  source             = "../../modules/lb"
  env                = "dev"
  appname            = "demo"
  internal           =  "false"
  load_balancer_type =  "application"
  subnets         = module.vpc.public_subnet_ids
  security_groups  = [module.vpc.security_group]
  vpc        = module.vpc.vpc
  tags = {
    Owner = "team-lb"
  }
}
/*module "autoscaling" {
  source        = " ../../modules/autoscaling"
   env                = "dev"
  appname            = "infra"

}
*/