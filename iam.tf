resource "aws_iam_role" "ec2_s3_role" {
  name = "EC2S3AccessRole"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "s3_limited_access" {
  name        = "S3LimitedAccessPolicy"
  description = "Allows EC2 to list and upload objects only in words-submission-bucket"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "s3:ListBucket",
        "Resource": "arn:aws:s3:::words-submission-bucket"
      },
      {
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::words-submission-bucket/*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_limited_access.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2S3InstanceProfile"
  role = aws_iam_role.ec2_s3_role.name
}
