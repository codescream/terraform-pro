module "webserver-cluster-stage" {
  source = "github.com/codescream/terraform-module//services/webserver-cluster?ref=v.0.0.1"

  cluster-name = "staging"
  keypair = "devops"
}