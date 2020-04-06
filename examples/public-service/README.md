# Example with publicly available service

Creates a publicly available Fargate service (a httpd webserver)/

## requirements

- [Terraform 0.12+](https://www.terraform.io/)
- authentication configuration for the [aws provider](https://www.terraform.io/docs/providers/aws/)

## create

```bash
$ make ACCOUNT=YOUR_ACCOUNT_ID MODE=apply tf
```

## destroy

```bash
$ make ACCOUNT=YOUR_ACCOUNT_ID MODE=destroy tf
```
