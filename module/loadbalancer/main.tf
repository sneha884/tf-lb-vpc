resource "aws_lb" "alb" {
  count                      = var.load_balancer_type == "application" ? 1 : 0
  name                       = format("%s-%s-%s", var.appname, var.env, "application")
  internal                   = var.internal
  load_balancer_type         = var.load_balancer_type
  security_groups            = var.security_groups
  subnets                    = var.subnets
  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.log-bucket.id
    prefix  = var.appname
    enabled = true
  }
  tags = merge (var.tags, {Name = format("%s-%s-%s", var.appname, var.env,"ALB")}) 
  }
/*-----------------------network loadbalncer-------------------*/
resource "aws_lb" "nlb" {
  count              = var.load_balancer_type == "network" ? 1 : 0
  name               =  format("%s-%s-%s",var.appname ,var.env ,"network")
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  subnets            = var.subnets
  enable_deletion_protection = false
  tags = {
    Environment = "production"
  }
  }
/*-----------------target group------------------*/
resource "aws_lb_target_group" "tg" {
  name        = format("%s-%s",var.appname,"tg")
  port        = "80"
  protocol    = var.load_balancer_type == "application" ? "HTTP" :"TCP"
  vpc_id      = var.vpc
}
/*-----------------listner--------------*/
resource "aws_lb_listener" "http_listener" {
 count              = var.load_balancer_type == "application" ? 1 : 0
 load_balancer_arn = aws_lb.alb[0].arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type     = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code = "200"
    }
  }
}

resource "aws_lb_listener_rule" "mobile" {
  count    = var.load_balancer_type == "application" ? 1 : 0
  listener_arn = aws_lb_listener.http_listener[0].arn
  priority  = 10
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
  condition {
    path_pattern{
      values = ["/mobile/*"]
    }
  }
  }
  resource "aws_lb_listener_rule" "laptop" {
  count    = var.load_balancer_type == "application" ? 1 : 0
  listener_arn = aws_lb_listener.http_listener[0].arn
  priority  = 20
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
  condition {
    path_pattern{
      values = ["/laptop/*"]
    }
  }
  }
  resource "aws_lb_listener_rule" "tv" {
  count    = var.load_balancer_type == "application" ? 1 : 0
  listener_arn = aws_lb_listener.http_listener[0].arn
  priority  = 30
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
  condition {
    path_pattern {
      values = ["/tv/*"]
    }
  }
  }



/*------------------------s3 bucket------------------*/
resource "aws_s3_bucket" "log-bucket" {
 bucket = "logbucket-${var.appname}-${var.env}-${random_string.random.id}"
}
resource "random_string" "random" {
  length  = 5
  special = false
  upper = false
}
/*---------------bucket policy--------------*/
resource "aws_s3_bucket_policy" "bucket-policy" {
  bucket = aws_s3_bucket.log-bucket.id
  policy = data.aws_iam_policy_document.policy.json
}
data "aws_iam_policy_document" "policy" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.log-bucket.id}/${var.appname}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    actions   = ["s3:PutObject"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
  }
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.log-bucket.id}/${var.appname}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.log-bucket.id}"]
    actions   = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

