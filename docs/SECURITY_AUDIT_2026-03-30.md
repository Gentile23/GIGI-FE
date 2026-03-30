# Security & Bug Audit — 2026-03-30

## Scope
- Flutter client code under `lib/`
- Mobile platform manifests under `android/` and `ios/`
- Configuration/constants used for API and auth flows

## High severity findings

### 1) Sensitive auth data potentially leaked in logs (fixed)
**Risk**: During Google login, the full social login response map was logged. That map includes authentication token fields returned by the backend.

**Impact**: Tokens and PII could be exposed in logs, crash reports, or shared debug traces.

**Fix applied**:
- Replaced verbose log with a redacted success-only status line.
- Removed direct email logging from `_handleGoogleAuth` entry message.

Files:
- `lib/providers/auth_provider.dart`

---

## Medium severity findings

### 2) Fragile parsing of AI response can crash workout generation (fixed)
**Risk**: The AI response parser used strict casts (`as int`, `as String`) on fields that can reasonably arrive as `String`, `num`, or null.

**Impact**: Runtime exceptions when model output format drifts slightly (e.g., `"sets": "3"`, missing `rest`), causing plan generation to fail.

**Fix applied**:
- Added resilient parser `_parseIntOrDefault`.
- Made rest parsing null-safe and defaulted to 60s.
- Defaulted `durationWeeks` to `4` when not parseable.
- Removed full raw plan JSON debug dump.

Files:
- `lib/data/services/workout_service.dart`

---

### 3) Direct OpenAI client-call fails silently when key is unset (fixed)
**Risk**: The service attempts to call OpenAI from client with an empty API key by default.

**Impact**: predictable runtime failures and confusing UX; if a key is added in-app later, it becomes a secret-management risk.

**Fix applied**:
- Added explicit guard clause: fail fast with actionable error message when key is not configured.

Files:
- `lib/data/services/openai_service.dart`

---

### 4) Social login used weak/incorrect tokens (fixed)
**Risk**: Google flow sent `googleUser.id` and Apple flow sent `userIdentifier` instead of signed identity tokens.

**Impact**: Backend token validation may be bypassed or become unreliable because stable user IDs are not equivalent to verifiable auth JWTs.

**Fix applied**:
- Google login now sends `googleUser.authentication.idToken` and fails if missing.
- Apple login now sends `credential.identityToken` and fails if missing.

Files:
- `lib/providers/auth_provider.dart`

---

### 5) Auth token persistence in plaintext preferences (fixed)
**Risk**: Storing bearer tokens only in `SharedPreferences` is weaker than platform keystore/keychain-backed storage.

**Impact**: Increased risk of token extraction on compromised/debuggable devices.

**Fix applied**:
- Added `flutter_secure_storage` and moved token storage to secure storage.
- Added automatic migration path from legacy `SharedPreferences` token.
- `clearToken()` now wipes both secure and legacy stores.

Files:
- `lib/data/services/api_client.dart`
- `pubspec.yaml`

---

## Additional security concerns (not yet fixed in this patch)
### A) Excessive debug logging across providers/services
**Risk**: many debug lines include raw server payloads and potentially user-linked operational data.

**Recommendation**:
- Introduce centralized logger with redaction policy.
- Disable verbose logs in release mode via wrapper (`if (kDebugMode)`).

### B) Hardening upload/file-text entry points (implemented in this patch)
**Implemented controls**:
- Video upload (`form-analysis`):
  - allowlist estensioni (`mp4`, `mov`, `m4v`, `webm`)
  - limite dimensione file (100MB)
  - sanitizzazione campo `exercise_name` + blocco markup/script-like payload
- PDF upload (`nutrition coach`):
  - solo estensione `.pdf`
  - limite dimensione file (15MB)
  - sanitizzazione nome file upload
- Free text in nutrition endpoints:
  - sanitizzazione (`food_name`, `unit`, `user_food_name`)
  - blocco payload sospetti (script/HTML event handlers)

Files:
- `lib/data/services/form_analysis_service.dart`
- `lib/data/services/nutrition_coach_service.dart`
- `lib/core/utils/validation_utils.dart`

## Validation commands run
- Secret and unsafe pattern scan:
  - `rg -n "(api[_-]?key|secret|token|password|Bearer|sk-[A-Za-z0-9]|OPENAI|supabase|firebase|private key)" lib android ios --glob '!**/*.g.dart' --glob '!**/*.freezed.dart'`
  - `rg -n "http://|badCertificateCallback|setTrustedCertificatesBytes|verify=False|allowInvalidCertificates|X509|SecurityContext|dangerously|eval\(|exec\(|Process\.run|sql injection|rawQuery|rawInsert|rawUpdate" lib android ios`
- Environment check:
  - `flutter --version` (tooling unavailable in container)
