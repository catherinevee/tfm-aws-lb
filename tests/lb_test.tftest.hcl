variables {
  name = "test-lb"
  environment = "test"
  vpc_id = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
  load_balancer_type = "application"
}

run "verify_basic_configuration" {
  command = plan

  assert {
    condition = aws_lb.this[0].name == var.name
    error_message = "Load balancer name does not match input"
  }

  assert {
    condition = aws_lb.this[0].load_balancer_type == var.load_balancer_type
    error_message = "Load balancer type does not match input"
  }

  assert {
    condition = length(aws_lb.this[0].subnets) >= 2
    error_message = "Load balancer must be deployed across at least 2 subnets"
  }
}

run "verify_security_group_creation" {
  command = plan

  assert {
    condition = length(aws_security_group.lb) > 0
    error_message = "Security group was not created when no existing security groups were provided"
  }
}

run "verify_ipv6_configuration" {
  command = plan

  variables {
    enable_ipv6 = true
    allowed_ipv6_cidr_blocks = ["::/0"]
  }

  assert {
    condition = contains(keys(aws_lb.this[0]), "enable_ipv6")
    error_message = "IPv6 was not enabled on the load balancer"
  }
}

run "verify_waf_integration" {
  command = plan

  variables {
    enable_wafv2 = true
    wafv2_web_acl_arn = "arn:aws:wafv2:us-west-2:123456789012:regional/webacl/test-waf/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition = aws_wafv2_web_acl_association.this[0].web_acl_arn == var.wafv2_web_acl_arn
    error_message = "WAFv2 integration failed"
  }
}
