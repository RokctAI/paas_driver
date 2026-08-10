# driver_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

## Building & Release (CI/CD)

The project uses GitHub Actions for automated builds and releases. To enable
signed builds, you must configure the following **Secrets** in your
repository settings (`Settings > Secrets and variables > Actions`).

### 🔑 Required Secrets

#### 🤖 Android Secrets

* `GOOGLE_SERVICES_JSON`: The **Base64 encoded** content of your `android/app/google-services.json`.
* `KEY_JKS`: The **Base64 encoded** content of your release keystore file (`.jks`).
* `KEY_PASSWORD`: The password for your keystore.
* `ALIAS_PASSWORD`: The password for your key alias.
* `PRODUCTION_ENV`: The **Base64 encoded** content of your
  `.env/production.env` file.

#### 🍎 iOS Secrets

* `IOS_GOOGLE_SERVICE_INFO_PLIST`: The **Base64 encoded** content of `ios/Runner/GoogleService-Info.plist`.
* `IOS_P12_BASE64`: The **Base64 encoded** `.p12` export of your Apple
  Distribution Certificate.
* `IOS_MOBILEPROVISION_BASE64`: The **Base64 encoded** `.mobileprovision`
  file for your app.
* `IOS_CERTIFICATE_PASSWORD`: The password used when exporting the `.p12` certificate.

---

### 🛠️ How to Encode Files

To provide the file contents as secrets, you must encode them to Base64
first. Use the following commands from the **root of your repository**:

**Windows (PowerShell):**

<!-- markdownlint-disable MD013 -->
```powershell
# For Android (Auto-Clip)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/google-services.json")) | clip

# For iOS (Auto-Clip)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("ios/Runner/GoogleService-Info.plist")) | clip

# For Production Environment (Auto-Clip)
[Convert]::ToBase64String([IO.File]::ReadAllBytes(".env/production.env")) | clip
```
<!-- markdownlint-enable MD013 -->

**macOS/Linux:**

```bash
# For Android
base64 -i android/app/google-services.json | pbcopy

# For iOS
base64 -i ios/Runner/GoogleService-Info.plist | pbcopy

# For Production Environment
base64 -i .env/production.env | pbcopy
```

Paste the resulting string into the corresponding GitHub Secret value.

### 🏗️ Multi-Tenant Build Support (build_* branches)

You can trigger dynamic builds for specific clients by creating a branch
following the `build_<client>-*` pattern (e.g., `build_clientname-v1.0`).

The workflow will automatically look for client-specific secrets:

* `GOOGLE_SERVICES_JSON_<CLIENT>`
* `IOS_GOOGLE_SERVICE_INFO_PLIST_<CLIENT>`
* `PRODUCTION_ENV_<CLIENT>`

If found, these will take precedence over the default secrets.

### 📦 Change App Package

Firstly, find out the existing package name from
`android/app/src/main/AndroidManifest.xml`. Then right click on project
folder from Android Studio and click on **Replace in Path**.

Put existing package name in the first box and preferred package name in the
second box, then click **Replace All**.

* [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
* [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

<!-- @generated-recompose-start -->
## Recomposing this app

`lib/` is fully installer-generated and disposable - it is safe to delete
and is gitignored. Anything app-specific lives in tracked manifests
(`app_routes`, or `host_routes` in `composer.json`), never in `lib/` itself.

To regenerate it:

```sh
python3 .rokct/initiate.py   # provisions the composer under .rokct/skills/
python3 .rokct/skills/.rok/flutter/scripts/compose.py
```

Session cleanup (`python3 .rokct/end_protocol.py`) wipes the provisioned
tools again.
<!-- @generated-recompose-end -->
