module "webserver-cluster-prod" {
  source = "../../../modules/services/webserver-cluster"

  region = "us-east-2"
  vpc-id = "vpc-034014ad69dfba396"
  image-id = "ami-02b8534ff4b424939"
  keypair = "devops-ohio"
  cluster-name = "prod"
}

resource "aws_autoscaling_schedule" "scale_out_in_morning" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 10
  recurrence            = "0 9 * * *"
  autoscaling_group_name = module.webserver-cluster-prod.asg_name
}
resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 17 * * *"
  autoscaling_group_name = module.webserver-cluster-prod.asg_name
}