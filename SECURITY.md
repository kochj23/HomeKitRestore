# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Security Features

HomeKit Restore implements the following security measures:

### Data Protection
- **Keychain Storage**: All setup codes are stored in the macOS Keychain
- **Local-Only Storage**: No data is transmitted to external servers
- **No Cloud Sync**: All data remains on your local device
- **Hardened Runtime**: App is built with hardened runtime enabled

### Privacy
- HomeKit data access requires explicit user authorization
- No analytics or telemetry collection
- No network connections except for local device discovery
- Export files are created locally only

## Reporting a Vulnerability

If you discover a security vulnerability, please:

1. **DO NOT** open a public issue
2. Email the maintainer directly with details
3. Include steps to reproduce if possible
4. Allow reasonable time for a fix before disclosure

## Security Limitations

**By Design:**
- This app cannot retrieve setup codes from already-paired HomeKit devices
- HomeKit's security model intentionally prevents code extraction
- Setup codes are only stored if manually entered by the user

## Best Practices for Users

1. Keep your exported data (CSV, JSON, PDF) in a secure location
2. Use FileVault disk encryption on your Mac
3. Don't share setup codes in insecure channels
4. Regularly backup your code vault
