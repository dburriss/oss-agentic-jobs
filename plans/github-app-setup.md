# Plan: GitHub App Setup for OrcAI

## Overview

This covers the manual steps to create a GitHub App, install it on your organisation, and configure the repo secrets needed by the CI workflows.

The `orcai auth create-app` command automates the App creation via browser. After that, a few manual steps in the GitHub UI are required to collect the installation ID and store the secrets.

---

## Prerequisites

- `orcai` installed locally: `dotnet tool install --global OrcAI.Tool`
- `gh` CLI installed and authenticated: `gh auth login`
- .NET 10 runtime available

---

## Step 1: Create the GitHub App via orcai

Run the following from your terminal. Replace `<org>` with your GitHub organisation slug (or omit `--org` to register under your personal account).

```sh
orcai auth create-app --app-name orca-bot --org <org>
```

What this does:
- Starts a local HTTP server on port `9876`
- Opens your browser to a form that auto-submits a GitHub App manifest
- Waits for GitHub to redirect back with credentials
- Downloads and saves the PEM private key to `~/.config/orca/app.pem`
- Saves partial config to `~/.config/orca/auth.json` (without installation ID yet)
- Prints step-by-step instructions for finding the installation ID

**App permissions created automatically:**
- Issues — write
- Pull requests — read
- Metadata — read
- Organisation projects — write
- Projects — write

**Note:** `Contents: Read` is also needed for some `gh` operations that orcai delegates to.
After creation, go to the App's settings page and add `Contents: Read` under Repository permissions, then re-install the App for the permission change to take effect.

---

## Step 2: Install the App on your organisation

1. Go to: `https://github.com/organizations/<org>/settings/apps`
2. Find **orca-bot** and click **Edit**
3. In the left sidebar, click **Install App**
4. Click **Install** next to your organisation
5. Choose **All repositories** (or select specific repos orcai will manage)
6. Click **Install**

---

## Step 3: Find the Installation ID

After installing, the URL will be:

```
https://github.com/organizations/<org>/settings/installations/<INSTALLATION_ID>
```

Note down the numeric ID at the end of the URL — that is your `ORCAI_APP_INSTALLATION_ID`.

Alternatively, retrieve it via the CLI (requires a JWT, so easier to just read it from the URL).

---

## Step 4: Find the App ID

1. Go to: `https://github.com/organizations/<org>/settings/apps/orca-bot`
2. The **App ID** is shown near the top of the General tab — it is a plain integer, e.g. `123456`

---

## Step 5: Complete local orcai auth

Provide orcai with the installation ID to finish local authentication:

```sh
orcai auth app \
  --app-id <APP_ID> \
  --key ~/.config/orca/app.pem \
  --installation-id <INSTALLATION_ID>
```

Orca will validate the token against `gh auth status`. On success:

```
GitHub App config saved and validated.
```

You can now run `orcai validate` and `orcai run` locally.

---

## Step 6: Add repo secrets for CI

Go to: `https://github.com/dburriss/oss-agentic-jobs/settings/secrets/actions`

Add the following three repository secrets:

### `ORCAI_APP_ID`

Value: the integer App ID from Step 4

### `ORCAI_APP_INSTALLATION_ID`

Value: the integer installation ID from Step 3

### `ORCAI_APP_PRIVATE_KEY`

Value: the full PEM content from `~/.config/orca/app.pem`

```sh
# Print the PEM content to copy-paste into the secret value field
cat ~/.config/orca/app.pem
```

Copy the entire output including the `-----BEGIN RSA PRIVATE KEY-----` header and footer lines.

---

## Step 7: Enable workflow write permissions

Go to: `https://github.com/dburriss/oss-agentic-jobs/settings/actions`

Under **Workflow permissions**, select:
- **Read and write permissions**

Click **Save**.

This allows `GITHUB_TOKEN` to push the automated lock-file commit back to the repo.

---

## Step 8: Verify CI auth

After the workflows are committed and the secrets are in place, you can trigger a dry-run by creating a PR that adds or modifies a file under `jobs/`. The `orcai-verify` workflow should run `orcai validate` successfully.

If the validate step fails with a 401 or 403, check:
- The App is installed on the org (`Step 2`)
- `Contents: Read` permission was added and the App was re-installed (`Step 1 note`)
- The PEM secret was pasted in full with no trailing whitespace

---

## Summary: values to collect

| Item                       | Where to find it                                                      |
|----------------------------|-----------------------------------------------------------------------|
| `ORCAI_APP_ID`              | App settings page → General tab (integer near the top)               |
| `ORCAI_APP_INSTALLATION_ID` | URL after installing: `.../installations/<ID>`                        |
| `ORCAI_APP_PRIVATE_KEY`     | `cat ~/.config/orca/app.pem` (created by `orcai auth create-app`)    |
