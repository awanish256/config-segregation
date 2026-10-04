# Uploading versioned config packages to JFrog Artifactory

Every TeamCity build now produces versioned packages and uploads them:

```
config-generic-local/
  INI/1.0.42/INI-1.0.42.tar.gz
  XSL/1.0.42/XSL-1.0.42.tar.gz
  XSD/1.0.42/XSD-1.0.42.tar.gz
  PROPS/1.0.42/PROPS-1.0.42.tar.gz
```

A Helm deploy can later pick any version of any folder by URL, e.g.
`https://<server>.jfrog.io/artifactory/config-generic-local/INI/1.0.42/INI-1.0.42.tar.gz`.

## 1. Activate your JFrog platform (GCP Marketplace trial)

1. In the GCP console, open Marketplace and find your JFrog subscription.
   Click **Manage on provider** (or **Sign up with JFrog**) to finish
   registration on the JFrog side.
2. JFrog emails you an activation link. Follow it, set the admin password,
   and note your platform URL, which looks like `https://<server>.jfrog.io`.
3. Sign in at that URL.

## 2. Create a Generic repository

1. Go to **Administration** (gear icon) > **Repositories** > **Create a Repository** > **Local**.
2. Package type: **Generic**.
3. Repository key: `config-generic-local`, then **Create Local Repository**.

## 3. Create an access token for TeamCity

1. **Administration** > **User Management** > **Access Tokens** > **Generate Token**.
2. Scoped token for your user (or a dedicated `teamcity` user with deploy
   permission on `config-generic-local`). Pick an expiry that suits you.
3. Copy the token now; JFrog shows it only once.

Alternative: click your avatar > **Edit Profile** > **Generate an Identity Token**.

## 4. Test the upload from your machine

From the repo root in PowerShell:

```powershell
$env:ARTIFACTORY_URL   = 'https://<server>.jfrog.io/artifactory'
$env:ARTIFACTORY_TOKEN = '<token>'
.\build\package.ps1 -Version 0.0.1
.\build\upload-to-artifactory.ps1 -Version 0.0.1
```

In JFrog, open **Artifactory** > **Artifacts** > `config-generic-local` and
you should see `INI/0.0.1/INI-0.0.1.tar.gz` and the other three.

## 5. Update TeamCity

In your build configuration:

1. **General Settings** > Build number format: `1.0.%build.counter%`.
   This becomes the version on every package.
2. **Parameters** > Add new parameter:
   - `env.ARTIFACTORY_URL` = `https://<server>.jfrog.io/artifactory` (kind: Environment variable)
   - `env.ARTIFACTORY_TOKEN` = your token, with **Spec** > Display: **Password**
     so it is masked in logs and the UI.
3. **Build Steps**: add a PowerShell step, Script file
   `build/upload-to-artifactory.ps1`, and drag it between "Package" and
   "Copy to D:\ConfigDrops". The order becomes:
   1. Package config folders (`build/package.ps1`)
   2. Upload to Artifactory (`build/upload-to-artifactory.ps1`)
   3. Copy to D:\ConfigDrops (`build/copy-to-drop.ps1`)

All three scripts read the version from TeamCity's `BUILD_NUMBER`
automatically, so no script arguments are needed.

The copy step now writes to a folder per version, e.g. `D:\ConfigDrops\1.0.42\`.
You can delete that step if Artifactory is enough.

## Troubleshooting

- **401 Unauthorized:** the token is wrong or expired, or `ARTIFACTORY_TOKEN` isn't set.
- **403 Forbidden:** the token's user lacks deploy permission on the repo.
- **404 Not Found:** the repo key or URL is wrong. The URL must end in `/artifactory`.
- **Could not create SSL/TLS secure channel:** use the script as shipped;
  it forces TLS 1.2 for Windows PowerShell 5.1.
