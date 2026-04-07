# khan-fluent/terraform-modules

> Shared Terraform modules used across all khan-fluent infrastructure repos.

## Modules

| Module | Purpose |
|---|---|
| [`ecr`](modules/ecr) | ECR repository with lifecycle policy |
| [`networking-default-vpc`](modules/networking-default-vpc) | Web + RDS security groups in the default VPC |
| [`rds-postgres`](modules/rds-postgres) | PostgreSQL RDS instance with Secrets Manager-managed master password |
| [`ecs-cluster-ec2`](modules/ecs-cluster-ec2) | ECS cluster + EC2 ASG + IAM instance role |
| [`ecs-service-ec2`](modules/ecs-service-ec2) | ECS task definition + service + execution/task IAM roles + log group |
| [`monitoring-baseline`](modules/monitoring-baseline) | SNS alerts topic + EC2/RDS/ECS CloudWatch alarms |
| [`cognito-userpool`](modules/cognito-userpool) | Cognito user pool, client, and hosted UI domain |
| [`dynamodb-sessions`](modules/dynamodb-sessions) | DynamoDB session table with `byUpdatedAt` GSI and TTL |
| [`ses-identity`](modules/ses-identity) | SES email identity |

## Versioning

Pin by Git ref tag, not branch:

```hcl
module "ecr" {
  source = "git::https://github.com/khan-fluent/terraform-modules.git//modules/ecr?ref=v1.0.0"

  name = "my-app"
}
```

`v1` tracks the latest non-breaking 1.x release. Use `v1.0.0` for full reproducibility.

## Design notes

### Why two ECS modules?

`ecs-cluster-ec2` and `ecs-service-ec2` are deliberately separate so multiple services can share a single cluster. The devops-portfolio cluster currently hosts both the portfolio app and TerraGen — both consume `ecs-service-ec2` against the same `cluster_id`.

### Security groups in the default VPC

`networking-default-vpc` creates security groups inside AWS's default VPC. This is intentional for cost reasons — running everything in the default VPC avoids NAT gateway charges. When/if we move to a private VPC with public/private subnets, we'll add a `networking-vpc` module alongside this one.

### RDS safety

The `rds-postgres` module defaults to `skip_final_snapshot = true` and `deletion_protection = false` to match existing dev-tier RDS instances. **For production, override these:**

```hcl
module "rds" {
  source = "git::https://github.com/khan-fluent/terraform-modules.git//modules/rds-postgres?ref=v1"

  identifier = "myapp-prod"
  # ...

  skip_final_snapshot     = false
  deletion_protection     = true
  backup_retention_period = 7
  storage_encrypted       = true
}
```

### `name_prefix` everywhere

All modules that create named AWS resources (security groups, alarms, SNS topics, IAM roles) take a `name_prefix` variable. **Do not rename this prefix on existing infrastructure** without first running `terraform state mv` — most named resources require destroy+create on rename, and stateful resources like RDS will lose data.

---

Maintained by [khanfluent](https://khanfluent.digital).
