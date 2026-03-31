---
name: cicd-pipeline-setup
description: >
  Design and implement CI/CD pipelines with GitHub Actions, GitLab CI, Jenkins,
  or CircleCI. Use for automated testing, building, and deployment workflows.
---

# CI/CD Pipeline Setup

## When to Use

- Automated code testing and quality checks
- Containerized application builds
- Multi-environment deployments
- Release management and versioning
- Automated security scanning
- Performance testing integration
- Artifact management and registry

## Quick Start

Minimal working example:

```yaml
# .github/workflows/deploy.yml
name: Build and Deploy

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18.x, 20.x]

    steps:
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [GitHub Actions Workflow](references/github-actions-workflow.md) | GitHub Actions Workflow |
| [GitLab CI Pipeline](references/gitlab-ci-pipeline.md) | GitLab CI Pipeline |
| [Jenkins Pipeline](references/jenkins-pipeline.md) | Jenkins Pipeline |
| [CI/CD Script](references/cicd-script.md) | CI/CD Script |
