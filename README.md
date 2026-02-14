# Training Log App

Beginner-first workspace for building your Flutter training app.

## What this folder contains
- `docs/01_environment_setup.md`: complete setup walkthrough for your machine.
- `scripts/windows/install_prerequisites.ps1`: installs Flutter + Android Studio + base tools.
- `scripts/windows/verify_environment.ps1`: checks if your setup is ready.
- `scripts/windows/create_flutter_app.ps1`: creates and bootstraps the app project with planned dependencies and folders.
- `scripts/windows/init_git_repo.ps1`: initializes git and writes a root `.gitignore`.

## Recommended order
1. Follow `docs/01_environment_setup.md`.
2. Run installer script in PowerShell.
3. Restart terminal/PC if requested.
4. Run verification script.
5. Run bootstrap script to create the app.
6. Run git init script.
7. Return here and we implement Milestone 1 together.

## Why this approach
You are starting from zero. Splitting setup from implementation prevents hidden toolchain issues from blocking actual feature work and keeps learning structured.
