# GitHub Setup

This repo ships two working GitHub Actions workflows
(`.github/workflows/`), not just documentation — they run for real once
the setup below is done.

## 1. Push this repo to GitHub

```bash
cd sales_pipeline_demo
git init
git add .
git commit -m "Initial commit: SQL Server -> ADF -> Snowflake -> dbt pipeline"
git branch -M main
git remote add origin https://github.com/<your-org>/<your-repo>.git
git push -u origin main
```

`.gitignore` already excludes `dbt_project/target/`, `dbt_packages/`,
`logs/`, and any local `profiles.yml` — none of that should ever be
committed.

## 2. Branching model

- **`main`** — protected. Represents what's currently deployed to prod.
  Nobody pushes to it directly.
- **Feature branches** (`feature/add-customer-ltv-segment`, etc.) — where
  all work happens. Opened as a pull request into `main` when ready.

## 3. Required repository secrets

Settings → **Secrets and variables** → **Actions** → **New repository
secret**. These back the `test` target used by `dbt_ci.yml`:

| Secret | Used by |
|---|---|
| `DBT_SNOWFLAKE_ACCOUNT` | both workflows |
| `DBT_SNOWFLAKE_CI_USER` | `dbt_ci.yml` (PR checks) |
| `DBT_SNOWFLAKE_CI_PASSWORD` | `dbt_ci.yml` (PR checks) |

## 4. A GitHub Environment for prod secrets

Settings → **Environments** → **New environment** → name it `production`.
This is what `dbt_prod_deploy.yml`'s `environment: production` line ties
into. Two things worth setting here specifically because it's prod:

- **Environment secrets** (separate from the repo-level ones above, and
  only readable by jobs that declare this environment):

  | Secret | Used by |
  |---|---|
  | `DBT_SNOWFLAKE_PROD_USER` | `dbt_prod_deploy.yml` |
  | `DBT_SNOWFLAKE_PROD_PASSWORD` | `dbt_prod_deploy.yml` |

- **Required reviewers** (optional but recommended) — makes every prod
  deploy pause for a manual approval click before it runs, even though
  it's triggered automatically by a merge or the nightly schedule.

## 5. Branch protection on `main`

Settings → **Branches** → **Add branch protection rule** → pattern `main`:

- ✅ Require a pull request before merging
- ✅ Require status checks to pass before merging → select
  **`dbt CI (pull request) / build-and-test`** (appears in the list once
  `dbt_ci.yml` has run at least once)
- ✅ Require branches to be up to date before merging

This is the actual enforcement mechanism — nothing in the YAML files
themselves blocks a bad merge; the branch protection rule is what does.

## 6. What runs when

| Trigger | Workflow | Target | Effect |
|---|---|---|---|
| PR opened/updated against `main` | `dbt_ci.yml` | `test` | `dbt build` + `dbt source freshness`; gates the merge |
| Merge to `main` | `dbt_prod_deploy.yml` | `prod` | `dbt build` + `dbt docs generate` |
| Nightly, 02:00 UTC | `dbt_prod_deploy.yml` | `prod` | Same, so prod refreshes with new data even without a code change |
| Manual (Actions tab → Run workflow) | `dbt_prod_deploy.yml` | `prod` | One-off refresh on demand |

## 7. Local development stays local

`dbt run --target dev` (see the main README) never touches GitHub at
all — it's a developer's own sandbox schema in Snowflake, using their
own local `~/.dbt/profiles.yml`. GitHub only enters the picture once a
branch is pushed and a PR is opened.
