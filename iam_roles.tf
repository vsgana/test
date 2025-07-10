resource "aws_iam_role" "ec2_role_writer" {
  name = "ec2-role-writer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "ec2_role_reader" {
  name = "ec2-role-reader"

  assume_role_policy = aws_iam_role.ec2_role_writer.assume_role_policy
}

# IAM Policy - Write Access
resource "aws_iam_policy" "s3_write_policy" {
  name = "s3-write-logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.log_bucket.arn}/*"
      }
    ]
  })
}

# IAM Policy - Read Access
resource "aws_iam_policy" "s3_read_policy" {
  name = "s3-read-logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.log_bucket.arn,
          "${aws_s3_bucket.log_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach Policies to Roles
resource "aws_iam_role_policy_attachment" "writer_attach" {
  role       = aws_iam_role.ec2_role_writer.name
  policy_arn = aws_iam_policy.s3_write_policy.arn
}

resource "aws_iam_role_policy_attachment" "reader_attach" {
  role       = aws_iam_role.ec2_role_reader.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

# IAM Instance Profiles
resource "aws_iam_instance_profile" "writer_profile" {
  name = "writer-profile"
  role = aws_iam_role.ec2_role_writer.name
}

resource "aws_iam_instance_profile" "reader_profile" {
  name = "reader-profile"
  role = aws_iam_role.ec2_role_reader.name
}
