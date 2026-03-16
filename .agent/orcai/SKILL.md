---
name: orcai
description: Use this skill when working with OrcAI jobs in this repository. It covers running mise tasks, authenticating via GitHub App credentials, reproducing CI failures locally, and generating new job YAML and issue template pairs.
---

# OrcAI Skill

This skill teaches you how to use the `orcai` CLI and `mise` task runner to manage bulk GitHub issue and project jobs in this repository.

## Overview

OrcAI automates the creation of GitHub Projects, issues, and Copilot assignments across many repositories from a single YAML job definition. Jobs live under `jobs/<name>/` and are executed by the GitHub Actions workflows or locally via `mise` tasks.

- CLI reference: <https://github.com/dburriss/orcai/blob/main/docs/cli-reference.md>
- Example repo: <https://github.com/dburriss/orcai/tree/main/example>

---

## Running mise tasks

All common operations are exposed as `mise` tasks defined in `mise.toml`.

### Restore tools

```bash
mise run install
# Runs: dotnet tool restore
```

Run this once after cloning, or after any change to `dotnet-tools.json`.

### Validate job configs

```bash
mise run validate
# Runs: dotnet orcai validate "jobs/**/*.yml" --continue-on-error
```

Validates YAML schema and confirms every listed repository is accessible. Reports all failures rather than stopping at the first. Exit code `1` means at least one config is invalid.

### Run all jobs

```bash
mise run run-jobs
# Runs: dotnet orcai run "jobs/**/*.yml" --continue-on-error
```

Creates or updates GitHub Projects and issues across all repos defined in every job YAML. Writes `<name>.lock.json` files on success.

---

## Authentication

### CI (GitHub Actions)

In CI, orcai reads credentials directly from environment variables — no `orcai auth` command is needed:

| Variable | Description |
|----------|-------------|
| `ORCAI_APP_ID` | GitHub App numeric ID |
| `ORCAI_APP_INSTALLATION_ID` | Installation ID for the target org |
| `ORCAI_APP_PRIVATE_KEY` | Full PEM content of the App private key |

These are injected from repository secrets in both workflow files.

### Local development

Authenticate locally using one of:

**GitHub App (recommended for CI parity):**

```bash
orcai auth app \
  --app-id <APP_ID> \
  --key /path/to/private-key.pem \
  --installation-id <INSTALLATION_ID>
```

**Personal Access Token:**

```bash
orcai auth pat --token ghp_xxxxxxxxxxxxxxxxxxxx
```

**Refresh / switch profiles when secrets change:**

```bash
# Re-run auth app with updated key or installation ID
orcai auth app --app-id <ID> --key /path/to/new-key.pem --installation-id <ID>

# Or switch between stored profiles
orcai auth switch <profile>
```

---

## Reproducing CI failures locally

When a CI run fails, reproduce it locally with the same commands the workflow uses:

```bash
# 1. Restore tools
mise run install

# 2. Set GitHub App env vars (or use orcai auth app)
export ORCAI_APP_ID=<id>
export ORCAI_APP_INSTALLATION_ID=<installation_id>
export ORCAI_APP_PRIVATE_KEY="$(cat /path/to/private-key.pem)"

# 3. Validate (mirrors orcai-verify.yml and the pre-flight in orcai-run.yml)
mise run validate

# 4. Run jobs (mirrors orcai-run.yml)
mise run run-jobs
```

You can also run `orcai validate` and `orcai run` directly for more control:

```bash
# Validate a single file
dotnet orcai validate jobs/my-job/my-job.yml

# Run a single file, skipping the lock cache
dotnet orcai run jobs/my-job/my-job.yml --skip-lock --verbose

# Inspect current state from lock file or live
dotnet orcai info jobs/my-job/my-job.yml
```

---

## Generating new jobs

Use `orcai generate` to scaffold a new YAML job definition and stub issue template:

```bash
# Interactive mode — prompts for name, org, and lets you pick repos
dotnet orcai generate --interactive

# Non-interactive — specify everything upfront
dotnet orcai generate \
  --name "Upgrade to .NET 10" \
  --org my-github-org \
  --repo repo-one \
  --repo repo-two \
  --output jobs/upgrade-dotnet10/upgrade-dotnet10.yml
```

After generation, move (or place) both files under `jobs/<name>/`:

```text
jobs/
  upgrade-dotnet10/
    upgrade-dotnet10.yml   # job config
    upgrade-dotnet10.md    # issue template (referenced by the YAML)
```

Edit the issue template (`<name>.md`) to describe the work to be done, then validate before committing:

```bash
dotnet orcai validate jobs/upgrade-dotnet10/upgrade-dotnet10.yml
```

Commit and open a PR — the `orcai-verify.yml` workflow will validate automatically.

---

## Lock files

- Lock files (`<name>.lock.json`) are written by `orcai run` next to each YAML.
- They record the project number, issue numbers, and PR links from the last successful run.
- Subsequent runs skip network calls when the YAML hash matches the lock.
- Delete the lock file or pass `--skip-lock` to force a full re-sync.
- In CI, lock files are committed back to the repo automatically by `orcai-run.yml`.

---

## Cleanup

To tear down all resources created by a job:

```bash
dotnet orcai cleanup jobs/my-job/my-job.yml

# Preview without making changes
dotnet orcai cleanup jobs/my-job/my-job.yml --dryrun
```
