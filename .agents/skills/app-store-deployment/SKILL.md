---
name: app-store-deployment
description: >
  Deploy iOS and Android apps to App Store and Google Play. Covers signing,
  versioning, build configuration, submission process, and release management.
---

# App Store Deployment

## When to Use

- Publishing apps to App Store and Google Play
- Managing app versions and releases
- Configuring signing certificates and provisioning profiles
- Automating build and deployment processes
- Managing app updates and rollouts

## Quick Start

Minimal working example:

```bash
# Create development and distribution signing certificates
# Step 1: Generate Certificate Signing Request (CSR) in Keychain Access
# Step 2: Create App ID in Apple Developer Portal
# Step 3: Create provisioning profiles (Development, Distribution)

# Xcode configuration for signing
# Set Team ID, Bundle Identifier, and select provisioning profiles
# Build Settings:
# - Code Sign Identity: "iPhone Distribution"
# - Provisioning Profile: Select appropriate profile
# - Code Sign Style: Automatic (recommended)

# Info.plist settings
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
  </dict>
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [iOS Deployment Setup](references/ios-deployment-setup.md) | iOS Deployment Setup |
| [Android Deployment Setup](references/android-deployment-setup.md) | Android Deployment Setup |
| [Version Management](references/version-management.md) | Version Management |
| [Automated CI/CD with GitHub Actions](references/automated-cicd-with-github-actions.md) | Automated CI/CD with GitHub Actions |
| [Pre-Deployment Checklist](references/pre-deployment-checklist.md) | Pre-Deployment Checklist |
