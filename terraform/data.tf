data "aws_canonical_user_id" "current" {}

data "aws_availability_zones" "available" {}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}
