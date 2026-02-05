# use `workspaces` to add more env https://www.terraform.io/docs/commands/workspace/
# never use the same .tfstate on multiple envs

env = "prod"

codecommit_user_ssh = "ssh-rsa SOME_PUBLIC_KEY"

unique_id = "CHANGE_ME_TO_SOMETHING_UNIQUE" # eg: "329384"
