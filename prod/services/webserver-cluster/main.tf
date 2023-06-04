module "webserver-cluster-prod" {
  source = "../../../modules/services/webserver-cluster"

  region = "us-east-2"
  vpc-id = "vpc-034014ad69dfba396"
  image-id = "ami-02b8534ff4b424939"
  keypair = "devops-ohio"
  cluster-name = "prod"
}