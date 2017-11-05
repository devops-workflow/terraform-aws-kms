/**
 * AWS KMS Terraform Module
 * =====================
 *
 * Create AWS KMS Key and set policy
 *
 * Usage:
 * ------
 *
 *     module "kms" {
 *       source      = "../tf_kms"
 *
 *       add variables
 *     }
**/

module "kms_secrets_s3" {
  source        = "../tf_s3"
  environment   = "${var.environment}"
  name          = "${var.name}"
  principal     = "${var.principal}"
}

# TMP: this should be else where outside of Env setup.  Variables to pass in
# IAM user: root
# IAM role: ecsInstanceRole
resource "aws_iam_user" "root" {
  name = "root"
  path = "/"
}
/*
resource "aws_iam_role" "ecsInstanceRole" {
    name               = "${var.environment}-ecsInstanceRole"
    path               = "/"
    assume_role_policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
*/
data "aws_caller_identity" "current" { }

data "template_file" "policy_kms" {
  template = "${file("${path.module}/files/policy_kms.json")}"
  vars = {
    principal = "${var.principal}"
    aws_account_id = "${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_kms_key" "kms_key" {
  description = "KMS key for s3 bucket encryption"
  policy = "${data.template_file.policy_kms.rendered}"
}

resource "aws_kms_alias" "kms_alias" {
  name = "alias/${var.environment}-${var.name}"
  target_key_id = "${aws_kms_key.kms_key.id}"
}
