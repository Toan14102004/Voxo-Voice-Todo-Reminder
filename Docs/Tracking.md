# Tracking

Chuẩn: skill `ios-tracking-integration` (Firebase + Adjust + Meta + TikTok). Mọi thứ đi qua `TrackingKit`
(`VoiceTodo/Sources/Data/Services/Analytics/TrackingKit.swift`). Product analytics (screen, custom event) đi qua
`FirebaseAnalyticsService`.

## Luồng
`AppDelegate`: Firebase -> Meta `ApplicationDelegate` -> `TrackingKit.start()` (mọi launch, không gate)
-> Splash: UMP (`GoogleMobileAdsConsentManager.gatherConsent`, ATT do UMP hiện) -> `releaseFirstSessionDelay()`
-> `startMobileAdsIfAllowed()` (chỉ ads SDK bị gate bởi consent).

## Hai hàm duy nhất bắn tiền
| Hàm | Gọi từ | Ghi chú |
|---|---|---|
| `TrackingKit.logVerifiedPurchase` | `SubscriptionManager.trackVerifiedPurchase` | dedupe theo `transactionId`, trial = k% x giá |
| `TrackingKit.handleAdPaidEvent` | `AdsEventLogger.logPaidAdImpression` (mọi format, gồm rewarded) | `AdValue.value` đã là đơn vị tiền |

CẤM gọi trực tiếp `AppEvents.logPurchase`, `Adjust.trackEvent` có revenue, `TikTokBusiness.track*`, `SKAdNetwork.*` ở nơi khác.

## Cấu hình mỗi app mới (xcconfig `Dev`/`Release`)
`ADJUST_TOKEN`, `ADJUST_PURCHASE_TOKEN`, `FACEBOOK_APP_ID`, `FACEBOOK_CLIENT_TOKEN`, `TIKTOK_APP_ID`,
`TIKTOK_ACCESS_TOKEN`, `APP_ID` (App Store ID, chỉ số). Còn `REPLACE_WITH*` thì SDK/event tương ứng tự bỏ qua.
Chốt 3 cờ profile trong `TrackingConfig` với team UA trước khi build: `metaDirectHybrid`, `tiktokAdRevenueViaSDK`, `googleSeesAdRevenue`.
Thay `GoogleService-Info.plist` bằng file thật; token Adjust event: cấm để rỗng.

## Nghiệm thu
```bash
python3 ~/.claude/skills/ios-tracking-integration/sdk_gate/sdk_gate_t1.py <app_config>.json   # 0 FAIL
```
Sau đó: log smoke trên máy sạch (thấy hộp thoại ATT từ UMP) + test purchase sandbox.
Firebase DebugView: Scheme -> Arguments Passed On Launch: `-FIRDebugEnabled`.
