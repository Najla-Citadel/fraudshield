# Foreground Service Type Declaration for Google Play Store

**App:** FraudShield
**Package:** com.citadel.fraudshield.v2
**Service Type:** `phoneCall`
**Date:** 2026-03-10

---

## Service Type: phoneCall

### Purpose

FraudShield uses a foreground service with type `phoneCall` to provide real-time scam call detection and protection for users in Malaysia. The service powers the Caller ID Protection feature, which screens incoming calls against a community-reported scam database and displays risk warnings before users answer suspicious calls.

### Core Functionality

1. **Call Screening**: Uses Android's `CallScreeningService` API (Android 10+) to detect incoming calls without requiring the restricted `READ_CALL_LOG` permission
2. **Risk Overlay Display**: Shows real-time risk assessment overlays over the native phone dialer during incoming calls
3. **Community Intelligence**: Cross-references incoming numbers against a database of 10,000+ community-verified scam reports
4. **STIR/SHAKEN Verification**: Integrates with carrier-level caller identity verification (Android 11+)
5. **Post-Call Protection**: Monitors call lifecycle to trigger safety interventions when users answer high-risk calls

### User Benefit

- **Immediate scam warning**: Users see risk scores before answering suspicious calls
- **Protection from financial fraud**: Covers investment scams, bank impersonation, government agency fraud, and Macau scam patterns common in Malaysia
- **Community-powered intelligence**: Risk scores improve as more users report scam numbers
- **Offline protection**: Local database enables scam detection even without internet connectivity

### Why a Foreground Service is Required

- `CallScreeningService` alone cannot display system overlays over the native phone dialer
- A foreground service is required to maintain the overlay window during active calls
- The service must persist across screen transitions (dialer app to home screen and back)
- Background call lifecycle monitoring (OFFHOOK/DISCONNECTED states) requires continuous service

### Permissions Used

| Permission | Purpose | Android Version |
|-----------|---------|-----------------|
| `READ_PHONE_STATE` | Detect call lifecycle (ringing, answered, ended) | All |
| `READ_CALL_LOG` | Get caller number (fallback for Android 9 only) | API 28 and below |
| `SYSTEM_ALERT_WINDOW` | Display risk overlay over phone dialer | All |
| `READ_PHONE_NUMBERS` | Detect neighbor spoofing (compare to user's number) | All |
| `BIND_SCREENING_SERVICE` | CallScreeningService for incoming call detection | API 29+ |

### Data Privacy

- Phone numbers are **encrypted** (AES-256 deterministic encryption) before transmission to backend
- **No call audio** is recorded or transmitted during call screening
- Only call metadata (caller ID, duration) is analyzed for risk assessment
- Users can opt out of Caller ID Protection at any time via app settings
- Offline scam database is stored locally and auto-deleted after 90 days
- Compliant with Malaysia's Personal Data Protection Act 2010 (PDPA)

### Alternatives Considered

| Alternative | Why Not Sufficient |
|------------|-------------------|
| `CallScreeningService` only | Cannot display system overlays or persist UI across app transitions |
| `NotificationListenerService` | Cannot provide real-time overlay during active calls |
| Background service without foreground type | Android 12+ requires foreground service type declaration |
| `specialUse` service type | `phoneCall` is the standard type for caller ID apps per Google Play policy |

### Google Play Policy Compliance

This service meets the requirements of:
- [Foreground Services Policy](https://support.google.com/googleplay/android-developer/answer/13392821) - `phoneCall` type for caller ID functionality
- [User Data Policy](https://support.google.com/googleplay/android-developer/answer/10144311) - Minimal data collection, encrypted transmission
- [Permissions Policy](https://support.google.com/googleplay/android-developer/answer/9888170) - No restricted permissions on Android 10+

### Contact

For questions about this declaration:
- **Developer:** FraudShield Development Team
- **Email:** dev@fraudshieldprotect.com
- **Website:** https://fraudshieldprotect.com
