resource "aws_s3_bucket" "lb-log-bucket" {
  bucket        = "${var.s3_bucket}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "lb-bucket-policy" {
  bucket = "${aws_s3_bucket.lb-log-bucket.id}"

  policy = <<POLICY
{
  "Id": "Policy1555390933586",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1555390931899",
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::lb-logs-tf-test/ELB-logs/AWSLogs/IAM_ID/*",
      "Principal": {
        "AWS": [
          "127311923021"
        ]
      }
    }
  ]
}
		POLICY
}
