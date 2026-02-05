variable "user_ssh_public_key" {
  type = string
}

##########################
##########################
##########################
##########################
### CODECOMMIT IAM USER
##########################
resource "aws_iam_user" "codecommit_user" {
  name = "codecommit-user"
}

resource "aws_iam_user_ssh_key" "codecommit_user" {
  username   = aws_iam_user.codecommit_user.name
  encoding   = "SSH"
  public_key = var.user_ssh_public_key
}

data "aws_iam_policy" "IAMUserSSHKeys" {
  arn = "arn:aws:iam::aws:policy/IAMUserSSHKeys"
}

resource "aws_iam_user_policy_attachment" "IAMUserSSHKeys" {
  user       = aws_iam_user.codecommit_user.name
  policy_arn = data.aws_iam_policy.IAMUserSSHKeys.arn
}

data "aws_iam_policy" "IAMReadOnlyAccess" {
  arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

resource "aws_iam_user_policy_attachment" "IAMReadOnlyAccess" {
  user       = aws_iam_user.codecommit_user.name
  policy_arn = data.aws_iam_policy.IAMReadOnlyAccess.arn
}

data "aws_iam_policy" "AWSCodeCommitPowerUser" {
  arn = "arn:aws:iam::aws:policy/AWSCodeCommitPowerUser"
}

resource "aws_iam_user_policy_attachment" "AWSCodeCommitPowerUser" {
  user       = aws_iam_user.codecommit_user.name
  policy_arn = data.aws_iam_policy.AWSCodeCommitPowerUser.arn
}

output "git_ssh_user" {
  value = aws_iam_user_ssh_key.codecommit_user.ssh_public_key_id
}
