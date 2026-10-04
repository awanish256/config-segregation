# ConfigRepo

Config files for the application, split by type. On every push to GitHub,
TeamCity packages each folder into its own `.tar.gz` and copies the results
to `D:\ConfigDrops`.

```
config/
  INI/     -> INI.tar.gz
  XSL/     -> XSL.tar.gz
  XSD/     -> XSD.tar.gz
  PROPS/   -> PROPS.tar.gz
build/
  package.ps1                # step 1: tar each folder into out\<FOLDER>-<VERSION>.tar.gz
  upload-to-artifactory.ps1  # step 2: upload to JFrog Artifactory (see ARTIFACTORY.md)
  copy-to-drop.ps1           # step 3: copy to D:\ConfigDrops\<VERSION>\
```

The version comes from TeamCity's build number. For JFrog setup and the extra
TeamCity step, see [ARTIFACTORY.md](ARTIFACTORY.md).

Replace the sample files in each folder with your real config files.

## 1. Try it locally

From the repo root in PowerShell:

```powershell
.\build\package.ps1
.\build\copy-to-drop.ps1
dir D:\ConfigDrops
```

If PowerShell blocks the script, run it with
`powershell -ExecutionPolicy Bypass -File .\build\package.ps1`.

Requires Windows 10 (1803+) or Windows Server 2019+, which include `tar.exe`.

## 2. Push to GitHub

Create an empty repo on GitHub (no README), then:

```powershell
git init
git add .
git commit -m "Initial config repo with packaging scripts"
git branch -M main
git remote add origin https://github.com/<you>/ConfigRepo.git
git push -u origin main
```

## 3. Set up TeamCity

1. **Create the project.** Administration > Projects > Create project >
   From a repository URL. Paste the GitHub URL. For a private repo, use your
   GitHub username and a personal access token as the password. TeamCity
   detects the `main` branch and creates a build configuration.
2. **Remove any auto-detected steps.** On the "Auto-detected build steps"
   page, skip them and choose "configure build steps manually".
3. **Add step 1: Package.**
   - Runner type: PowerShell
   - Step name: `Package config folders`
   - Script: File, Script file: `build/package.ps1`
4. **Add step 2: Copy to drop folder.**
   - Runner type: PowerShell
   - Step name: `Copy to D:\ConfigDrops`
   - Script: File, Script file: `build/copy-to-drop.ps1`
5. **Publish artifacts (optional, keeps a copy per build).**
   General Settings > Artifact paths: `out/*.tar.gz`
6. **Trigger on push.** Triggers > Add new trigger > VCS Trigger, then Save.
   Because TeamCity runs on your machine, GitHub cannot notify it of pushes.
   TeamCity instead checks the repo on an interval (60 seconds by default)
   and starts a build when it sees a new commit.

## 4. Test end to end

Change any file under `config\`, commit and push. Within about a minute a
build should start in TeamCity, and the four `.tar.gz` files in
`D:\ConfigDrops` should show the new timestamp.

## Troubleshooting

- **Access denied writing to D:\ConfigDrops.** The TeamCity agent runs as a
  Windows service account (often Local System). Give that account write
  access to `D:\ConfigDrops`, or change the agent service's "Log On" account.
- **`tar.exe` not recognized.** The machine is older than Windows 10 1803.
  Update Windows, or install a tar tool and put it on the agent's PATH.
- **Build fails with "Config folder not found".** One of the four folders is
  missing from `config\`. Git does not keep empty folders, so each folder
  needs at least one file.
