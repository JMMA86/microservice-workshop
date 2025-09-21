# Infrastructure Branching Strategy

This document describes the branching strategy defined for managing infrastructure as code (IaC), with a parallel approach independent of the application development flow, to ensure control and stability in production environments.

## Main Branches

- `infra/main`: Contains the stable infrastructure in production. It only receives approved changes from `infra/develop`.

- `infra/develop`: Integration branch for testing infrastructure changes. All changes must be validated here before reaching `infra/main`.

## Support Branches

- `infra/feature/name`: Created from `infra/develop`. Used to deploy or modify infrastructure components. Integrated into `infra/develop` via Pull Request.

## Branch Protection Policies

Protection rules are applied on GitHub to ensure code quality and security:

- Protected branches: `infra/main`, `infra/develop`.

- Rules applied:

  - Direct commits are not allowed.
  - Every change requires a Pull Request.
  - Each Pull Request must have at least one reviewer approval.
  - All CI/CD pipelines must be completed before the merge.
  - Admins can not bypass this rules.
