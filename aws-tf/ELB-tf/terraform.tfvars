region = "us-east-1"

profile = "default"

subnet-id = "id-of-your-subnet"

credentials_file = "/home/rnair/.aws/rakesh_credentials"

cidr_vpc = "10.0.0.0/16"

cidr_subnet-01 = "10.0.1.0/24"

cidr_subnet-02 = "10.0.2.0/24"

instance_ami = "ami-0de53d8956e8dcf80"

instance_type = "t2.micro"

environment_tags = "Production"

availability_zone-01 = "us-east-1a"

availability_zone-02 = "us-east-1d"

s3_bucket = "lb-logs-tf-test"
