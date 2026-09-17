# XAOCEN Account Integration

## Scope

XAOCEN Reader now uses the shared XAOCEN Account protocol at
`https://auth.xaocen.studio/v1`. The app does not implement Google, email, or
other third-party login forms.

## Identity

- `productId`: `xaocen-reader`
- Windows platform: `windows-x64`
- Android platform: `android`
- Access token: process memory only
- Refresh token and offline license: `flutter_secure_storage` (Windows
  Credential Manager / Android Keystore-backed implementation)

## Online flow

`device/start` → system browser verification URL → `device/status` polling →
`device/token`. Account profile and product entitlements are read from
`account/me` and `account/entitlements`. Logout, revoke and rotated refresh
tokens follow the protocol endpoints.

## Offline flow

The device identity is an Ed25519 key pair generated locally and retained in
secure storage. Windows can display a QR payload containing only the public
key/device identity; a `.xaocen-license` or compact license can be imported
and is verified against the built-in `primary` Account public key before it is
stored.
Android-side camera scanning is intentionally deferred; the same compact
license can be transferred as a file or string without exposing a token.
The client also exposes the protocol calls for a signed-in phone flow:
`account/offline/request`, `account/offline-license`, `auth/offline/check` and
`auth/offline/refresh`.

## Boundaries

Account state is separate from `UserProfile`, `DataRoot`, `ContentSource` and
`SyncProvider`. No provider-owned login form, password, verification code or
server key is handled by the app; Reader, Locator, database schema and content
pipeline were not changed.

## Validation

- `flutter pub get`: PASS
- `flutter analyze --no-pub`: PASS
- Account model/contract tests: PASS (3)
- Full Flutter suite: PASS (773 passed; 3 explicit live-network skips)
- Device-flow polling is single-flight; authorization URLs are restricted to
  HTTPS XAOCEN domains before being handed to the system browser.
- Full device/browser authorization and real license issuance: MANUAL REQUIRED
- Physical Windows Credential Manager and Android Keystore verification:
  MANUAL REQUIRED
- Account integration is not yet a production freeze until both manual items
  above pass.
