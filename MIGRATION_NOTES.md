# Migration Notes — terraform-modules v1

This document captures the design decisions, risk analysis, and trade-offs from extracting in-tree Terraform modules into the central `khan-fluent/terraform-modules` repo. Read this before making structural changes to the modules or ECS topology.

---

## What was migrated

In April 2026, the in-tree `terraform/modules/` directories from three repos were consolidated into this central repo and consumed via Git source refs (`?ref=v1`):

| Source repo | Modules removed | Replaced with |
|---|---|---|
| `devops-portfolio` | ecr, ecs, monitoring, networking, rds, ses | ecr, ecs-cluster-ec2, ecs-service-ec2, monitoring-baseline, networking-default-vpc, rds-postgres, ses-identity |
| `incident-postmortem-generator` | ecr, ecs, monitoring, networking, rds | ecr, ecs-cluster-ec2, ecs-service-ec2, monitoring-baseline, networking-default-vpc, rds-postgres |
| `terraform-generator` | cognito, dynamodb, ecr, ecs | cognito-userpool, dynamodb-sessions, ecr, ecs-service-ec2 (consumes existing devops-portfolio cluster) |

The migration used Terraform `moved` blocks to remap state addresses without destroy/create. **The local `terraform plan` showed `0 to add, 0 to change, 0 to destroy`** for all three repos before pushing to main. CI applies completed in 21–24 seconds (state metadata only, no AWS API resource changes).

---

## Why ECS was split into two modules (cluster + service)

The original in-tree `ecs` module conflated cluster provisioning (cluster, ASG, EC2 launch template, instance IAM role) with service provisioning (task definition, service, task IAM roles, log group). This meant:

- `terraform-generator` couldn't reuse the `ecs` module from devops-portfolio because TerraGen runs on the *existing* devops-portfolio cluster, not its own
- Adding a new app to a shared cluster required either copying the service-creation code or accepting redundant cluster-creation logic
- Unit-testing one half of the module always required the other

The split modules:

- **`ecs-cluster-ec2`** — provisions cluster, EC2 ASG, launch template, instance role. Runs once per cluster.
- **`ecs-service-ec2`** — provisions task definition, service, execution + task IAM roles, log group. Runs once per service. Takes `cluster_id` as input.

This enables the **shared cluster pattern**: one cluster hosts multiple services. devops-portfolio's cluster currently hosts both the portfolio app and TerraGen.

---

## Cost analysis: should we consolidate to one cluster?

**TL;DR — devops-portfolio's cluster is already a shared cluster. TerraGen runs on it. The third app (incident-postmortem) runs on its own cluster. Consolidating it would NOT save money for this specific deployment.**

### Current state

| App | Instance | EC2 cost (us-east-1, t3.micro) |
|---|---|---|
| devops-portfolio cluster (hosts portfolio + TerraGen) | 1× t3.micro | ~$7.50/mo |
| incident-postmortem cluster | 1× t3.micro | ~$7.50/mo |
| **Total** | **2× t3.micro** | **~$15/mo** |

### Why not consolidate to a single cluster?

I considered moving incident-postmortem onto the devops-portfolio cluster. The math:

| Option | Instance | Cost | Notes |
|---|---|---|---|
| **Status quo** (2 clusters) | 2× t3.micro | ~$15/mo | What we have now |
| **1 cluster, 1× t3.micro** | 1× t3.micro | ~$7.50/mo | **Doesn't fit**: portfolio + TerraGen + postmortem all use `network_mode = "host"`, and portfolio + postmortem both bind container port 3000. Port collision → only 2 of 3 services can run. |
| **1 cluster, 1× t3.small** | 1× t3.small | ~$15/mo | Same cost as today, but now a single point of failure for all 3 apps. Still doesn't fix the port collision; would require switching one app off port 3000. |
| **1 cluster, 1× t3.medium** | 1× t3.medium | ~$30/mo | **More expensive** than today. Doesn't fix port collision either. |

Switching one app off port 3000 is plausible (TerraGen already uses 3001), but doing it just to enable consolidation that doesn't save money is busywork.

### When consolidation WOULD pay off

If a 4th or 5th app is added, the per-app overhead of running its own cluster (one EC2 instance, IAM roles, ASG, log group) becomes wasteful. At that point:

1. Pick a single host port per app (3000, 3001, 3002, 3003…) — or move to `awsvpc` networking with task ENIs to eliminate the port-collision constraint entirely
2. Standardize all services on `ecs-service-ec2` against the devops-portfolio cluster
3. Right-size the EC2 instance to fit the combined CPU/memory footprint (likely t3.small or t3.medium)
4. Migrate one service at a time using `terraform state mv` + `lifecycle.create_before_destroy` to avoid downtime

**For now: keep two clusters.** The cost of consolidating exceeds the savings.

---

## RDS data safety: known risks

The user explicitly accepted RDS destruction risk in exchange for finishing this migration in one pass. The current state:

- **`skip_final_snapshot = true`** on both RDS instances (devops-portfolio, incident-postmortem). A destroy or replacement loses all data immediately.
- **`deletion_protection = false`** on both. Nothing prevents `terraform destroy` from removing the database.
- **`backup_retention_period = 0`** on devops-portfolio (no automated backups) and **`= 1`** on incident-postmortem (one day of backups).
- **No `prevent_destroy` lifecycle blocks** anywhere. A bad variable change that triggers replacement → instant data loss.

The migration was specifically designed to **not** trigger any of these scenarios: the `moved` blocks remapped state addresses without renaming any resource the AWS provider considers replacement-worthy. `terraform plan` confirmed `0 to destroy` for both RDS-bearing repos.

### To harden RDS for production

If/when these apps move to a production tier:

```hcl
module "rds" {
  source = "git::https://github.com/khan-fluent/terraform-modules.git//modules/rds-postgres?ref=v1"

  identifier = "myapp-prod"
  # ... other vars ...

  # Production overrides
  skip_final_snapshot     = false
  deletion_protection     = true
  backup_retention_period = 7
  storage_encrypted       = true
  multi_az                = true   # if budget allows
}
```

And in the root, add:

```hcl
moved {
  from = module.rds.aws_db_instance.this
  to   = module.rds.aws_db_instance.this
}

# Then add this to the module main.tf via PR:
# lifecycle { prevent_destroy = true }
```

---

## Module name conflicts and the `name_prefix` convention

All modules that create named AWS resources (security groups, alarms, SNS topics, IAM roles, ECR repos) take a `name_prefix` (or `name`/`identifier`) variable. **Do not change this prefix on existing infrastructure** without first running `terraform state mv` — most named resources require destroy+create on rename, and stateful resources like RDS will lose data.

Specifically:

- **RDS `identifier`** — change = destroy+create = data loss
- **ECR `name`** — change = destroy+create = all images lost
- **SNS topic `name`** — change = destroy+create = subscriptions lost
- **CloudWatch alarm `alarm_name`** — change = destroy+create = alarm history lost
- **Security group `name`** — change = destroy+create = brief connection drop, dependent resources may need updating

If you ever need to rename a module instance, do it in three steps: (1) `terraform state mv` to the new address with the old underlying resource, (2) verify with `plan` that nothing is being destroyed, (3) push.

---

## State migration tricks used

A few `moved` block patterns that came up during this migration. Document for next time:

### 1. Adding `count` to a resource that previously had no count

Old code: `resource "aws_security_group" "rds" { ... }`
New code: `resource "aws_security_group" "rds" { count = var.create_rds_sg ? 1 : 0 ... }`

State migration:
```hcl
moved {
  from = module.networking.aws_security_group.rds
  to   = module.networking.aws_security_group.rds[0]
}
```

### 2. Splitting a module into two

When `module.ecs` was split into `module.ecs_cluster` + `module.ecs_service`, every resource needed an explicit move:

```hcl
moved {
  from = module.ecs.aws_iam_role.task_execution
  to   = module.ecs_service.aws_iam_role.task_execution
}
```

You cannot use a wildcard or template — each `moved` block needs a literal source and target. Tedious but reliable.

### 3. Migrating from a discrete resource to a `for_each` map entry

The old in-tree ECS module had hard-coded inline policies on the task role (`task_sns`, `task_dynamodb`). The central module turns these into a `for_each` map keyed by policy name, so users can pass arbitrary inline policies without modifying the module.

```hcl
# Old:  module.ecs.aws_iam_role_policy.task_sns
# New:  module.ecs_service.aws_iam_role_policy.task_inline["devops-portfolio-task-sns"]

moved {
  from = module.ecs.aws_iam_role_policy.task_sns
  to   = module.ecs_service.aws_iam_role_policy.task_inline["devops-portfolio-task-sns"]
}
```

**Caveat**: `moved` block target keys must be literal strings, not interpolations. You cannot write `to = module.foo.aws_x.y["${var.name}-suffix"]`. Hard-code the key.

### 4. Module source paths cannot use variables

Terraform parses `source` at config-load time, before variables resolve. This is invalid:

```hcl
module "ecr" {
  source = "${local.modules_source_base}//modules/ecr?ref=${local.modules_ref}"  # ERROR
}
```

Use a literal:

```hcl
module "ecr" {
  source = "git::https://github.com/khan-fluent/terraform-modules.git//modules/ecr?ref=v1"
}
```

This means version bumps are a global find-and-replace per repo.

### 5. CRLF in heredocs breaks `user_data` base64 hashes

The `ecs-cluster-ec2` launch template includes a bash user_data heredoc. On Windows, Git checks the file out with CRLF, which produces a different base64 string than the LF version that AWS originally received. The fix is to strip CR explicitly:

```hcl
user_data = base64encode(replace(<<-EOF
  #!/bin/bash
  echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
EOF
, "\r", ""))
```

Without this, `terraform plan` would show a launch template update on every plan from a Windows checkout.

### 6. ECS service `task_definition` drift

The GitHub Actions deploy workflow renders new task definition revisions out-of-band on every push to main (via `aws-actions/amazon-ecs-render-task-definition`). Without `lifecycle.ignore_changes`, the next `terraform apply` would revert the service to the revision Terraform last managed, **rolling back the app**. The central module includes:

```hcl
lifecycle {
  ignore_changes = [task_definition, desired_count]
}
```

This is critical and must not be removed without a corresponding change to how deploys work.

---

## Versioning policy

- **`v1.0.x`** — patch tag for the current release
- **`v1`** — floating tag tracking the latest 1.x release. All consuming repos pin to `?ref=v1`. Update by deleting and re-pushing the tag.
- **`v2`** — reserved for breaking changes. When/if we cut v2, consumers stay on `v1` until they migrate explicitly.

To cut a new version:

```bash
# In khan-fluent/terraform-modules
git tag v1.0.5
git push origin v1.0.5

# Move the floating v1 tag
git tag -d v1
git push origin :refs/tags/v1
git tag v1
git push origin v1
```

After updating, all consuming repos automatically pick up the new modules on their next `terraform init -upgrade`. **Always test with `terraform plan` before pushing to main**, since main triggers `terraform apply -auto-approve`.

---

Maintained by [khanfluent](https://khanfluent.digital).
