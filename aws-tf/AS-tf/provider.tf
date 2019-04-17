provider "aws" {
  region                  = "${var.region}"
  profile                 = "${var.profile}"
  shared_credentials_file = "${var.credentials_file}"
}
