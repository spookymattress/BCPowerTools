# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Module Overview

BCPowerTools is a PowerShell module (by NORRIQ) for automating Microsoft Dynamics 365 Business Central development workflows — primarily dependency resolution, Azure DevOps API integration, and BC container/deployment management.

## Loading the Module

```powershell
Import-Module .\BCPowerTools.psd1 -Force
```

`BCPowerTools.psm1` is the root module; it dot-sources every `.ps1` file. There is no build step — changes take effect on the next `Import-Module`.

## First-Time Setup

The module requires a global config file at `%APPDATA%\NORRIQ\BCPowerToolsConfig.json`. Bootstrap it with:

```powershell
New-TFSConfigFile
notepad (Get-TFSConfigPath)
```

Required keys: `collectionUrl` (Azure DevOps collection URL), `user`, `password` (PAT token used as Basic auth). Optional keys: `translationKey`, `codeSigningCertThumbprint`, `businessCentralLicenceFile`, `navLicenceFile`, `translationDictionaryPath`, `dependencyBranches`.

## Architecture

### Layers

- **Config** (`Config/`) — reads/writes the global JSON config via `Get-TFSConfigKeyValue` / `Set-TFSConfigKeyValue`. All other layers call into this for credentials and settings.
- **Azure DevOps API** (`Azure DevOps API/`) — `Invoke-TFSAPI` is the single HTTP wrapper for all REST calls. It builds Basic auth headers from config, handles `Get`/`Put`, supports file download (`-OutFile`), and can silently swallow errors (`-SuppressError`). All other API functions call `Invoke-TFSAPI`.
- **AL** (`AL/`) — dependency resolution and app management. `Get-ALDependencies` is the main entry point: it reads `app.json`, consults a per-project `environment.json` for overrides, then downloads the required `.app` files from the last successful Azure DevOps build artifact via `Get-AppFromLastSuccessfulBuild`.
- **Container Handling** (`Container Handling/`) — Docker/BC container lifecycle using `BcContainerHelper` / `NavContainerHelper` cmdlets.
- **Deployment** (`Deployment/`) — deploys `.app` files to on-prem BC (via NAV management DLLs) or cloud (via BC REST API with MSAL token).
- **File Handling** (`File Handling/`) — lightweight utilities (`New-TempDirectory`, `New-EmptyDirectory`, `New-AADMapping`).

### Per-project `environment.json`

AL projects can place an `environment.json` in their source root to control dependency resolution:

```json
{
  "repo": "BC",
  "dependencyBranch": "main",
  "dependencies": [
    { "name": "MyApp", "project": "MyProject", "repo": "BC", "version": "1.2.3", "includetest": false }
  ]
}
```

`Get-EnvironmentKeyValue` reads this file; `Get-DependencyFromEnvironment` looks up individual dependency entries by name.

### Dependency resolution flow

`Get-ALDependencies` → `Get-ALDependenciesFromAppJson` (recursive) → for each non-Microsoft, non-test dependency:
1. Check `environment.json` for an explicit `project`/`repo`/`version`
2. Fall back to deriving project name from the dependency name and repo from the current git remote suffix (`-AL` or `-BC`)
3. Call `Get-AppFromLastSuccessfulBuild` → `Invoke-TFSAPI` (build artifacts API) → download zip → expand to temp dir
4. Recursively resolve transitive dependencies from the dependency's own `app.json`
5. Copy `.app` files to `.alpackages/`; optionally publish/install into a BC container

## Adding Functions

1. Create a new `.ps1` file in the appropriate subdirectory.
2. Define the function and add `Export-ModuleMember -Function FunctionName` at the bottom.
3. Add a dot-source line in `BCPowerTools.psm1`.
4. Bump `ModuleVersion` in `BCPowerTools.psd1` if publishing.

## Key Conventions

- Authentication to Azure DevOps uses HTTP Basic with `user:password` (PAT) encoded as Base64 — set in the global config file, never hardcoded.
- Temporary files go through `New-TempDirectory` (returns a new GUID-named temp folder); callers are responsible for cleanup.
- Functions that can fail gracefully accept `-SuppressError` or use try/catch with `Contains('already published')` guards for idempotent container operations.
- `Get-Content ... -Encoding UTF8` is used consistently for reading JSON files to handle Danish characters (øæå).
