output "asg_name" {
  value       = aws_autoscaling_group.pro-asg.name
  description = "The name of the Auto Scaling Group"
}

output "alb_dns_name" {
  value       = aws_lb.pro-lb.dns_name
  description = "The domain name of the load balancer"
}