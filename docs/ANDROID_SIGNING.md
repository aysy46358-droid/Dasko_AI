# Android APK signing for Dasko AI

## Why this is required

A release APK can update an installed Android app only when its application ID matches and its signing certificate is compatible with the installed APK. Builds made on ephemeral GitHub runners can end up signed with different debug keys, which causes Android to reject an in-place update.

The current workflow deliberately refuses to publish an installable APK until a persistent signing key is configured. Do not commit a keystore, passwords, or private signing material to the repository.

## One-time setup in a trusted local environment

Create a dedicated Android upload/release keystore and keep a secure backup. For example, with JDK `keytool` installed:

```bash
keytool -genkeypair -v \
  -keystore dasko-upload-keystore.jks \
  -alias dasko-upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Use a strong password and store it in a password manager. Do not reuse a password from another service. Keep the keystore file and passwords private.

Encode the keystore as one base64 line (macOS/Linux):

```bash
base64 < dasko-upload-keystore.jks | tr -d '\n'
```

In GitHub, open **Settings → Secrets and variables → Actions → New repository secret** and create all four secrets:

- `DASKO_ANDROID_KEYSTORE_BASE64`: the one-line base64 output of the keystore
- `DASKO_ANDROID_KEYSTORE_PASSWORD`: the keystore password
- `DASKO_ANDROID_KEY_ALIAS`: the alias used when creating the key (example: `dasko-upload`)
- `DASKO_ANDROID_KEY_PASSWORD`: the key password

Never paste these values into a commit, issue, chat, workflow log, or public file. Limit who can administer repository Actions secrets.

## First install and future updates

The existing build #55 and #70 were confirmed to have different signing certificate fingerprints. Unless the original private key used for #55 can be recovered, Android will not accept the new key as an in-place update of #55. For the transition only, uninstall build #55 and install the first APK produced after these secrets are configured. This can delete app-local data, so back up anything important first.

After that first install, keep the four secrets and the same keystore permanently. Every later APK built by this workflow will use the same signing key. Keep the Android application ID stable and increase the Flutter build number in `pubspec.yaml` for every distributed build.

## Safety behavior

The workflow fails early when any signing secret is missing. It must not silently fall back to an ephemeral/debug signing key, because that would reintroduce the update problem.
