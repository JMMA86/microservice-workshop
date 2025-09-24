# Development Branching Strategy

This document describes the branching strategy defined for application development, based on a simplified GitFlow, with the goal of organizing collaborative work and maintaining stable branches for production.

## Main Branches

- `main`: Contains stable versions ready for production. Updates are only made from release/ or hotfix/ branches.

- `develop`: Integration branch. All features are combined here before preparing a release.

## Support Branches

- `feature/name`: Created from `develop`. Used for new features. Integrated into `develop` via pull request.

- `release/version`: Created from `develop`. Used to prepare a new stable version. When approved, they are integrated into `main` and tagged with a version tag.

- `hotfix/name`: Created from `main`. Used to fix critical bugs in production. Integrated into both `main` and `develop`.

## Branch Protection Policies

Protection rules are applied on GitHub to ensure code quality and security:

- Protected branches: `main`, `develop`.

- Rules applied:

  - Direct commits are not allowed.
  - Every change requires a Pull Request.
  - Each Pull Request must have at least one reviewer approval.
  - All CI/CD pipelines must pass before the merge.
  - Admins can not bypass this rules.
