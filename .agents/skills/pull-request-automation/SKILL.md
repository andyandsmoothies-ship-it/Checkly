---
name: pull-request-automation
description: >
  Automate pull request workflows with templates, checklists, auto-merge rules,
  and review assignments. Reduce manual overhead and improve consistency.
---

# Pull Request Automation

## When to Use

- Code review standardization
- Quality gate enforcement
- Contributor guidance
- Review assignment automation
- Merge automation
- PR labeling and organization

## Quick Start

Minimal working example:

```markdown
# .github/pull_request_template.md

## Description

Briefly describe the changes made in this PR.

## Type of Change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update

## Related Issues

Closes #(issue number)

## Changes Made

- Change 1
- Change 2

## Testing

- [ ] Unit tests added/updated
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [GitHub Actions: Auto Review Assignment](references/github-actions-auto-review-assignment.md) | GitHub Actions: Auto Review Assignment |
| [GitHub Actions: Auto Merge on Approval](references/github-actions-auto-merge-on-approval.md) | GitHub Actions: Auto Merge on Approval |
| [GitLab Merge Request Automation](references/gitlab-merge-request-automation.md) | GitLab Merge Request Automation |
| [Bors: Merge Automation Configuration](references/bors-merge-automation-configuration.md) | Bors: Merge Automation Configuration, Conventional Commit Validation |
| [PR Title Validation Workflow](references/pr-title-validation-workflow.md) | PR Title Validation Workflow |
| [Code Coverage Requirement](references/code-coverage-requirement.md) | Code Coverage Requirement |
