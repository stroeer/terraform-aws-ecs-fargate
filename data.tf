# add data sources used in more than one tf file here


data "aws_vpc" "selected" {
  tags = {
    Name = "main"
  }
}
