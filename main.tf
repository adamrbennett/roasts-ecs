variable "profile" {}
variable "region" {}
variable "resource_prefix" {}

variable "version" {}
variable "domain" {}

terraform {
  backend "s3" {
    bucket = "sfi-api-state"
    region = "us-east-1"
    profile = "sfi"
  }
}

data "terraform_remote_state" "ecs" {
  backend = "s3"
  config {
    bucket = "sfi-api-state"
    region = "us-east-1"
    profile = "sfi"
    key = "dev/ecs.tfstate"
  }
}

provider "aws" {
  profile = "${var.profile}"
  region = "${var.region}"
}

resource "aws_cloudwatch_log_group" "service" {
  name = "/${var.resource_prefix}/roasts-${var.version}"
}

resource "aws_ecs_task_definition" "service" {
  family = "roasts"
  container_definitions = <<EOF
[
  {
    "name": "roasts",
    "essential": true,
    "image": "517077376125.dkr.ecr.us-east-1.amazonaws.com/api/roasts:3",
    "memory": 128,
    "memoryReservation": 64,
    "cpu": 128,
    "environment": [
      {
        "name": "APP_PORT",
        "value": "80"
      }
    ],
    "portMappings": [
      {
        "hostPort": 0,
        "containerPort": 80,
        "protocol": "http"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/${var.resource_prefix}/roasts-${var.version}",
        "awslogs-region": "us-east-1"
      }
    }
  }
]
EOF
}

resource "aws_alb_target_group" "service" {
  name     = "${var.resource_prefix}-roasts-${var.version}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.ecs.vpc_id}"
  deregistration_delay = 60
}

resource "aws_ecs_service" "service" {
  name            = "roasts-${var.version}"
  cluster         = "${data.terraform_remote_state.ecs.ecs_cluster_arn}"
  task_definition = "${aws_ecs_task_definition.service.arn}"
  desired_count   = 1
  iam_role        = "${data.terraform_remote_state.ecs.ecs_service_role_arn}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.service.arn}"
    container_name = "roasts"
    container_port = 80
  }
}

resource "aws_alb_listener_rule" "private" {
  listener_arn = "${data.terraform_remote_state.ecs.private_alb_listener_arn}"
  priority = 102

  action {
    type = "forward"
    target_group_arn = "${aws_alb_target_group.service.arn}"
  }

  condition {
    field  = "host-header"
    values = ["roasts-${var.version}.${var.domain}"]
  }
}
