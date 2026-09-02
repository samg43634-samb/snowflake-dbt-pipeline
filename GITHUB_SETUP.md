# GitHub Setup — dev / test / main Branches

This project uses **branch-per-environment**: three long-lived branches,
each mapped to a Snowflake environment. Code is physically promoted by
merging `dev` → `test` → `main`, and each merge (or direct push) triggers
that environment's deploy automatically.

```
feature/*  --PR-->  dev   --PR-->  test   --PR-->  main
                     |              |               |
                dbt --target    dbt --target    dbt --target
                     dev            test            prod
```

## 1. Push this repo to GitHub (if you haven't already)

```bash
cd sales_pipeline_demo
git init
git add snowflake dbt_project README.md .gitignore .github
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<your-org>/<your-repo>.git
git push -u origin main
```

## 2. Create the `dev` and `test` branches from `main`

```bash
git checkout -b dev
git push -u origin dev

git checkout main
git checkout -b test
git push -u origin test

git checkout main
```

All three branches now exist on GitHub, all identical to start.

## 3. Repository secrets

Settings → **Secrets and variables** → **Actions** → **New repository
secret**:

| Secret | Used for |
|---|---|
| `DBT_SNOWFLAKE_ACCOUNT` | all three environments (same Snowflake account) |
| `DBT_SNOWFLAKE_DEV_USER` / `DBT_SNOWFLAKE_DEV_PASSWORD` | automated deploys when `dev` branch changes |
| `DBT_SNOWFLAKE_CI_USER` / `DBT_SNOWFLAKE_CI_PASSWORD` | automated deploys when `test` branch changes |
| `DBT_SNOWFLAKE_PROD_USER` / `DBT_SNOWFLAKE_PROD_PASSWORD` | automated deploys when `main` branch changes |

Use **service account** credentials for these, not your own personal
Snowflake login — GitHub Actions can't complete an MFA prompt, and a
service account can be scoped/rotated/revoked independently of any one
person's access. This is separate from the `dev` target in
`profiles.yml`, which still uses *your own* credentials for local
`dbt run --target dev` work from your laptop.

## 4. GitHub Environments (one per Snowflake environment)

Settings → **Environments** → **New environment**, create three, named
exactly `dev`, `test`, `production` (matching what
`.github/workflows/dbt_deploy.yml` and `dbt_pr_check.yml` reference).
Environment secrets take priority over repository secrets with the same
name, so you can either put the credentials at the repo level (above)
or scope them per-environment here — either works, but per-environment
is tidier once you have more than a couple of secrets.

**On `production` specifically**, turn on **Required reviewers** — this
pauses every prod deploy for a manual approval click, even though it's
triggered automatically by a merge to `main` or the nightly schedule.

## 5. Branch protection — repeat for `dev`, `test`, and `main`

Settings → **Branches** → **Add branch protection rule**, once per
branch:

| Setting | `dev` | `test` | `main` |
|---|---|---|---|
| Require a pull request before merging | ✅ | ✅ | ✅ |
| Require status checks to pass | `check-into-dev` | `check-into-test` | `check-into-main` |
| Require approvals | optional | recommended | ✅ recommended |

The status check names only appear in the dropdown after
`dbt_pr_check.yml` has run at least once against that branch — open one
throwaway PR into each branch first if the list is empty.

## 6. What runs when

| Event | Workflow / job | Target | Effect |
|---|---|---|---|
| PR opened into `dev` | `dbt_pr_check.yml` → `check-into-dev` | `dev` | Gates the merge |
| PR opened into `test` | `dbt_pr_check.yml` → `check-into-test` | `test` | Gates the merge |
| PR opened into `main` | `dbt_pr_check.yml` → `check-into-main` | `test` (final smoke test, not prod) | Gates the merge |
| Push/merge to `dev` | `dbt_deploy.yml` → `deploy-dev` | `dev` | Deploys to `ANALYTICS_DB_DEV` |
| Push/merge to `test` | `dbt_deploy.yml` → `deploy-test` | `test` | Deploys to `ANALYTICS_DB_TEST` |
| Push/merge to `main` | `dbt_deploy.yml` → `deploy-prod` | `prod` | Deploys to `ANALYTICS_DB_PROD` |
| Nightly, 02:00 UTC | `dbt_deploy.yml` → `deploy-prod` | `prod` | Refreshes prod even with no code change |
| Manual (Actions tab) | `dbt_deploy.yml`, any job | your choice | One-off deploy to any environment on demand |

## 7. The everyday loop, with three branches

```bash
git checkout dev
git pull
git checkout -b feature/add-customer-ltv-segment

# ...make changes...

git add dbt_project/
git commit -m "Add customer LTV segment"
git push -u origin feature/add-customer-ltv-segment
```

Open a PR **into `dev`**. `check-into-dev` runs. Merge → `dev` branch
auto-deploys.

When you're ready to promote what's on `dev` into `test`:

```bash
git checkout dev
git pull
git checkout -b promote/dev-to-test
git push -u origin promote/dev-to-test
```

Open a PR from `promote/dev-to-test` **into `test`**. `check-into-test`
runs. Merge → `test` branch auto-deploys.

Same pattern, `test` → `main`, when you're ready for prod.

## 8. Why this is more work than the single-`main` model

Every promotion is a real PR with a real review, at every stage — that's
the point, but it does mean three review gates instead of one, and three
sets of environment secrets to manage instead of two. If a project turns
out not to need that much ceremony, the single-branch + `--target` flag
model (one branch, one PR, deploy target chosen by the CI job rather
than by which branch it is) is the lower-overhead alternative — the two
approaches aren't compatible to run side by side, so pick one
deliberately rather than drifting into a mix of both.
