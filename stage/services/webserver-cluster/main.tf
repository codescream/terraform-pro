module "webserver-cluster-stage" {
  source = "../../../modules/services/webserver-cluster"

  keypair = "devops"
}