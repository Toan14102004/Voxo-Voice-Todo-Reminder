# Voxo: Voice Todo Reminder: Kế hoạch triển khai

> Tài liệu này là nguồn sự thật cho việc phát triển. Khi có mâu thuẫn giữa code và tài liệu, hỏi người dùng trước khi đổi.

## Trạng thái — cập nhật 06/11/2026

**Việc tiếp theo: chạy 3 phép đo trên máy thật, rồi ghi kết quả vào mục này.**
Mọi thứ khác đều đang chờ ba con số đó.

| Phép đo | Cách chạy | Kết quả |
|---|---|---|
| Nhắc việc có nổ đúng giờ không | Mở Voxo trên iPhone, cho phép thông báo, thêm 2–3 việc, để qua đêm. Sáng xem **Cài đặt → Chẩn đoán nhắc việc** | _chưa chạy_ |
| Đồng bộ Watch ↔ iPhone | Để iPhone xa, thêm 3 việc trên đồng hồ, mở iPhone lên kiểm tra | _chưa chạy_ |
| Dictation tiếng Việt | Trên đồng hồ, trang 2, đọc 10 câu mẫu | _chưa chạy_ |

Đừng bật Focus và tắt "Tóm tắt theo lịch trình" trước khi đo, nếu không kết quả sai.
Đừng xoá thông báo Voxo khi chưa thu kết quả.

### Đã xong

- **Giai đoạn 1, 3** — Core Data model, `TodoRepository`, `MergeService`, outbox. 37 test, chạy bằng `cd Shared && swift test`
- **Giai đoạn 2** — `ReminderScheduler` (hàm thuần, có test) + `ReminderService` (đặt lịch thật)
- **Giai đoạn 4, 6** — giao diện Watch và iPhone, bộ design token dùng chung
- **Giai đoạn 5** — đồng bộ WCSession hai chiều, chưa chạy thử trên máy thật

### Chưa làm

- **Giai đoạn 7** — hai nút **Xong** và **Nhắc lại sau 15 phút** ngay trên thông báo
- **Giai đoạn 8** — checklist mục 10
- Chưa quyết: có gỡ ads / mua hàng trong app / Firebase khỏi template không (xem §1 và CLAUDE.md)
- Tên hiển thị vẫn là "VoiceTodo", chưa đổi thành "Voxo"

### Chạy thế nào

```bash
pod install                      # sau khi pull lần đầu
open VoiceTodo.xcworkspace
cd Shared && swift test          # 37 test, không cần simulator
```

Scheme `VoiceTodo-Dev` là app thật. `VoiceTodo-SampleData` có dữ liệu mẫu.
`VoiceTodo-Phase0` là bộ đo notification, sẽ xoá sau khi xong giai đoạn 0.

Ký app bằng tài khoản Apple miễn phí nên **profile hết hạn sau 7 ngày**, hết hạn thì cắm máy build lại.

## 0. Thông tin dự án

| Mục | Giá trị |
|---|---|
| Tên app | Voxo: Voice Todo Reminder |
| Phụ đề | Speak tasks, get reminders |
| Nền tảng | iOS 13+, watchOS 6+ |
| Ngôn ngữ / UI | Swift, SwiftUI |
| Lưu trữ | Core Data, mỗi thiết bị một store |
| Đồng bộ | WatchConnectivity (`transferUserInfo`, `updateApplicationContext`) |
| Giao diện | Tiếng Anh; nhập liệu hỗ trợ tiếng Việt qua dictation |
| Phạm vi | Dùng cá nhân trước, chuẩn bị cho App Store sau |

## 1. Quyết định kỹ thuật (đã chốt, không đổi nếu không được yêu cầu)

1. **Nhắc việc tự quản lý bằng local notification**, không dùng EventKit/Reminders. Lý do: chu kỳ nhắc riêng cho từng todo không làm được với Reminders.
2. **iPhone là nguồn chính cho lịch nhắc.** Watch không tự lên lịch khi không có iPhone (để v2).
3. **Chu kỳ nhắc tối thiểu 60 phút** ở v1, để không chạm giới hạn 64 notification nhanh.
4. **Nhắc đến khi todo được đánh dấu xong hoặc bị xóa.**
7. **Nhắc gộp, kiểu lai** (chốt 06/11/2026, thay cách nhắc riêng từng todo ở bản đầu):
   - Các todo dùng chu kỳ chung chia nhau **một notification lặp duy nhất** (`repeats: true`), nội dung
     nêu tên todo cũ nhất chưa xong kèm số việc còn lại: *"Gọi điện cho mẹ — và 4 việc khác"*.
   - Todo có `intervalOverride > 0` vẫn được nhắc riêng theo chu kỳ của nó.
   - Nút **Xong** trên notification gộp đánh dấu đúng todo được nêu tên.

   **Lý do:** nhắc riêng từng todo tiêu tốn `số todo × (24h / chu kỳ)` slot, nên 10 todo chỉ phủ được
   ~6 giờ trong trần 64 và bắt buộc mở app mỗi ngày. Kiểu lai dùng `1 + số todo có chu kỳ riêng` slot,
   phủ vô hạn, và bỏ được yêu cầu mở app hằng ngày.

   **Cái mất, chấp nhận:** nội dung notification cố định từ lúc đặt lịch, nên số đếm có thể cũ. App đặt
   lại lịch mỗi khi mở, mỗi khi todo đổi, và mỗi khi `WCSession.transferUserInfo` đánh thức app chạy nền.
   Trường hợp xấu nhất: xong hết việc trên Watch mà iPhone chưa nhận tin thì nó vẫn nhắc một lần sai số.
5. **Xung đột đồng bộ:** last-writer-wins theo `updatedAt`, xóa dùng tombstone (`deletedAt`), giữ 30 ngày.
6. **Không dùng iCloud sync, widget, Siri Shortcut, Live Activity ở v1.**

**Điều kiện mở:** nếu giai đoạn 0 (prototype) cho thấy không thể giữ notification lặp lại đáng tin cậy, dừng lại và báo người dùng để xem xét chuyển sang EventKit. Không tự đổi hướng.

## 2. Kiến trúc

```
Apple Watch                              iPhone
┌────────────────────┐   WCSession   ┌────────────────────┐
│ SwiftUI views      │◄─────────────►│ SwiftUI views      │
│ Core Data store    │               │ Core Data store    │
│ Outbox (SyncOp)    │               │ Scheduler          │
│ Dictation input    │               │ UNUserNotification │
└────────────────────┘               │ Center             │
                                     └────────────────────┘
Shared (cả hai target): Core Data model, DTO, merge logic, Scheduler (hàm thuần), Repository protocol
App Group: UserDefaults cho cài đặt chu kỳ chung
```

**Nguyên tắc:**
- Logic nghiệp vụ (scheduler, merge, outbox) nằm trong module Shared, không phụ thuộc UIKit hay WatchKit, để test được bằng unit test.
- Mọi truy cập Core Data đi qua protocol `TodoRepository`. View không gọi `NSManagedObjectContext` trực tiếp.
- Mỗi thiết bị có store riêng. **Không chia sẻ file `.sqlite` giữa Watch và iPhone.**

## 3. Cấu trúc thư mục

```
VoiceTodo/
├── Shared/
│   ├── Model/            Core Data model (.xcdatamodeld), NSManagedObject subclass, DTO
│   ├── Repository/       TodoRepository (protocol), CoreDataTodoRepository
│   ├── Sync/             SyncOp, SyncMessage, MergeService
│   └── Scheduling/       ReminderScheduler (pure), ReminderPlan
├── VoiceTodo-iOS/        App, Views, Notifications, PhoneSessionManager
├── VoiceTodo-watchOS/    App, Views, Outbox, WatchSessionManager
└── Tests/
    ├── SchedulerTests
    ├── MergeTests
    ├── OutboxTests
    └── RepositoryTests
```

## 4. Data model

### Entity `Todo`

| Thuộc tính | Kiểu | Bắt buộc | Ghi chú |
|---|---|---|---|
| `id` | UUID | Có | Khóa đồng bộ, sinh ở thiết bị tạo |
| `title` | String | Có | Không rỗng sau khi trim, tối đa 200 ký tự |
| `isDone` | Bool | Có | Mặc định false |
| `createdAt` | Date | Có | |
| `updatedAt` | Date | Có | Cập nhật mỗi lần sửa, dùng cho merge |
| `completedAt` | Date | Không | Đặt khi `isDone = true` |
| `deletedAt` | Date | Không | Tombstone; có giá trị nghĩa là đã xóa |
| `intervalOverride` | Int32 | Có | Phút; 0 nghĩa là dùng chu kỳ chung |
| `nextRemindAt` | Date | Không | Do Scheduler tính |
| `lastRemindedAt` | Date | Không | |
| `originDevice` | String | Có | `"watch"` hoặc `"phone"` |

Index: `id` (unique), `isDone`, `deletedAt`.

### Entity `SyncOp` (chỉ dùng trên Watch)

| Thuộc tính | Kiểu | Ghi chú |
|---|---|---|
| `opId` | UUID | Unique; iPhone dùng để khử trùng |
| `todoId` | UUID | |
| `type` | String | `create`, `update`, `complete`, `delete` |
| `payload` | Binary | JSON của DTO |
| `createdAt` | Date | Thứ tự gửi |

### Cài đặt (UserDefaults, App Group)

| Key | Kiểu | Mặc định |
|---|---|---|
| `globalIntervalMinutes` | Int | 60 |
| `notificationPermissionAsked` | Bool | false |

Giá trị chu kỳ hợp lệ: 60, 120, 180, 240, 360, 480, 720, 1440 (phút). Không nhận giá trị khác ở v1.

## 5. Scheduler (phần quan trọng nhất)

> **Cần viết lại theo quyết định §1.7 (nhắc gộp kiểu lai).** Hợp đồng dưới đây mô tả cách nhắc riêng
> từng todo của bản đầu. Khi làm Phase 2 phải đổi: scheduler sinh **một** `ReminderPlan` lặp cho nhóm
> todo dùng chu kỳ chung (kèm tên todo cũ nhất và số việc còn lại), cộng một plan cho mỗi todo có
> `intervalOverride > 0`. `maxPending` và `horizon` gần như hết vai trò vì tổng slot còn rất nhỏ.
> Các quy tắc 1, 2 và 6 bên dưới vẫn giữ nguyên.

### Hợp đồng

```swift
struct ReminderPlan {
    let todoId: UUID
    let fireDate: Date
    let identifier: String   // "todo-<id>-<n>"
}

func plan(
    todos: [TodoSnapshot],          // chưa xong, chưa xóa
    now: Date,
    globalIntervalMinutes: Int,
    maxPending: Int = 60,           // chừa 4 chỗ đệm dưới giới hạn 64
    horizon: TimeInterval = 24 * 3600
) -> [ReminderPlan]
```

### Quy tắc

1. Chỉ lấy todo `isDone == false` và `deletedAt == nil`.
2. Chu kỳ của mỗi todo = `intervalOverride` nếu > 0, ngược lại dùng `globalIntervalMinutes`.
3. Với mỗi todo, sinh các thời điểm `nextRemindAt + k * interval` trong khoảng `horizon`.
4. Gộp tất cả thời điểm, sắp xếp tăng dần, lấy tối đa `maxPending`.
5. Nếu số thời điểm vượt `maxPending`, ưu tiên các thời điểm sớm nhất. Ghi log số lượng bị bỏ.
6. Hàm thuần: không đọc Core Data, không gọi `UNUserNotificationCenter`. Input là snapshot, output là danh sách.

### Khi nào chạy lại Scheduler

- App chuyển sang foreground.
- Có thay đổi todo (thêm, sửa, hoàn thành, xóa).
- Đổi chu kỳ chung hoặc chu kỳ của một todo.
- Nhận sync từ Watch.
- Notification được xử lý (action Xong hoặc Nhắc lại sau).
- `BGAppRefreshTask` được hệ thống đánh thức (chỉ là cơ hội, không đảm bảo).

### Thực thi

- Trước khi lên lịch lại, hủy toàn bộ notification có prefix `todo-` rồi đặt lại. Không hủy từng cái một.
- Identifier: `todo-<uuid>-<n>`, `n` là số thứ tự lần nhắc.
- Mỗi notification có `userInfo["todoId"]` để xử lý action.
- Cập nhật `nextRemindAt` và `lastRemindedAt` trong Core Data sau khi lên lịch.

### Hành động trên notification

- **Xong** (`COMPLETE`): đánh dấu `isDone = true`, `completedAt = now`, `updatedAt = now`; sau đó chạy lại Scheduler.
- **Nhắc lại sau** (`SNOOZE_15`): đặt `nextRemindAt = now + 15 phút`; sau đó chạy lại Scheduler.
- Category đăng ký trên cả iPhone và Watch.

### Quyền thông báo

- Xin quyền lần đầu mở app, với `.alert`, `.sound`, `.badge`.
- Nếu bị từ chối: hiển thị màn hình hướng dẫn mở Cài đặt, kèm nút mở đúng trang cài đặt của app.

## 6. Đồng bộ

### Watch sang iPhone

1. Mọi thay đổi trên Watch tạo `SyncOp` trong **cùng một transaction** với thay đổi `Todo`.
2. Gửi bằng `transferUserInfo` với payload là `SyncOp` đã mã hóa JSON.
3. iPhone nhận: nếu `opId` đã xử lý thì bỏ qua; ngược lại áp dụng qua `MergeService` và lưu `opId`.
4. iPhone gửi ACK bằng `transferUserInfo` với danh sách `opId` đã xử lý.
5. Watch nhận ACK thì xóa `SyncOp` tương ứng.
6. Watch không xóa `SyncOp` nếu chưa có ACK.

### iPhone sang Watch

- Thay đổi todo: gửi `transferUserInfo` với DTO đầy đủ của todo bị đổi.
- Cài đặt chu kỳ chung: `updateApplicationContext` (chỉ giữ trạng thái mới nhất).

### Merge

- So sánh theo `updatedAt`. Nếu bằng nhau, ưu tiên bản từ iPhone.
- `deletedAt` luôn thắng nếu có giá trị, trừ khi bản kia có `updatedAt` mới hơn `deletedAt` và được khôi phục rõ ràng (v1 không có khôi phục, nên tombstone luôn thắng).
- Tombstone được dọn sau 30 ngày kể từ `deletedAt`.

### Trạng thái đồng bộ

- Watch hiển thị số `SyncOp` đang chờ ACK.
- iPhone hiển thị thời điểm đồng bộ thành công gần nhất.

## 7. Giao diện

### Apple Watch

- **Danh sách chính:** todo chưa xong, sắp theo `createdAt` tăng dần.
- **Thêm:** nút mở `TextField`; dictation nhập; nút Lưu tạo todo. Không tạo todo rỗng.
- **Hoàn thành:** vuốt trái, hiển thị nút Xong.
- **Chi tiết:** chạm để xem và sửa tiêu đề.
- **Trạng thái:** dòng cuối "Chờ đồng bộ: N" khi có `SyncOp` chưa ACK.

### iPhone

- **Tab 1, Đang làm:** todo chưa xong.
- **Tab 2, Đã xong:** todo đã xong, có nút xóa vĩnh viễn (tombstone).
- **Sửa todo:** tiêu đề, chu kỳ riêng (chọn "Dùng chung" hoặc một trong các giá trị hợp lệ).
- **Cài đặt:**
  - Chu kỳ chung (dropdown các giá trị hợp lệ).
  - Trạng thái quyền thông báo, kèm nút mở Cài đặt nếu bị tắt.
  - Ghi chú giới hạn: chỉ hiện khi có todo đặt chu kỳ riêng, vì chỉ những todo đó mới tốn slot.
  - Trạng thái đồng bộ.
  - Nút "Xóa các việc đã xong" (xóa mềm).

### Quy ước giao diện

- Tiếng Anh cho toàn bộ chuỗi hiển thị. Chuỗi đặt trong `Localizable.strings` để sau này thêm ngôn ngữ.
- Hỗ trợ Dynamic Type.
- Không dùng màu làm cách duy nhất để truyền thông tin.

## 8. Lộ trình thực hiện

Mỗi giai đoạn kết thúc bằng: build pass, test pass, commit, và cập nhật checklist ở mục 10. **Không bắt đầu giai đoạn sau khi giai đoạn trước chưa đạt tiêu chí.**

### Giai đoạn 0: Prototype (bắt buộc, 1–2 ngày)

Mục tiêu: kiểm chứng hai giả định nền tảng. Có thể bỏ UI, chỉ cần màn hình test tạm.

- [ ] Dictation tiếng Việt có dấu trên Watch: nhập ít nhất 10 câu mẫu, ghi tỉ lệ đúng.
- [ ] **A — độ chính xác:** lên lịch 40–60 notification một lần (`repeats: false`) cách nhau 60 phút, không mở app. Ghi độ lệch từng cái.
- [ ] **B — trigger lặp:** đặt **một** notification `repeats: true` chu kỳ 60 phút, để chạy ít nhất 6 giờ không mở app. Kiểm tra nó còn bắn và không trôi nhịp. Đây mới là cơ chế v1 thực sự dùng sau quyết định §1.7.

**Tiêu chí qua:** dictation đúng ở mức chấp nhận được (người dùng sửa tối đa 1 từ mỗi câu); phép đo A đạt ít nhất 90% đúng giờ (±5 phút); phép đo B không bỏ nhịp nào và lần bắn cuối lệch không quá ±5 phút.
**Nếu không qua:** dừng và báo người dùng. Không tiếp tục sang giai đoạn 1.

### Giai đoạn 1: Scaffold (1 ngày)

- [x] Tạo project Xcode với hai target iOS và watchOS. **App Group bỏ qua** — không dùng chung được giữa hai thiết bị, xem CLAUDE.md.
- [x] Tạo cấu trúc thư mục ở mục 3 (`Shared/` là Swift package nội bộ).
- [x] Core Data model với entity `Todo`, `SyncOp` và `ProcessedOp`, **viết bằng code** chứ không dùng `.xcdatamodeld`.
- [x] Shared module build được cho cả hai target.

**Hoàn thành khi:** build pass cả hai target; app mở được, màn hình trống.

### Giai đoạn 2: Scheduler (2 ngày)

- [ ] Viết `ReminderScheduler.plan` theo mục 5.
- [ ] `SchedulerTests` gồm: chu kỳ mặc định, chu kỳ riêng, todo đã xong bị loại, todo đã xóa bị loại, vượt `maxPending` thì giữ thời điểm sớm nhất, nhiều todo cùng thời điểm, `now` nằm giữa khoảng.

**Hoàn thành khi:** toàn bộ test pass; không có import UIKit hay Core Data trong file scheduler.

### Giai đoạn 3: Repository và Merge (2 ngày)

- [x] `TodoRepository` protocol và `CoreDataTodoRepository`.
- [x] `MergeService` theo mục 6.
- [x] `SyncOp` được ghi cùng transaction với `Todo`.
- [ ] `MergeTests`: cùng `updatedAt`, `deletedAt` thắng, bản cũ bị bỏ, hai thay đổi đồng thời.
- [ ] `OutboxTests`: ACK xóa đúng op, op không ACK được giữ lại, `opId` trùng bị bỏ.
- [ ] `RepositoryTests` với store in-memory.

**Hoàn thành khi:** test pass; không view nào gọi Core Data trực tiếp.

### Giai đoạn 4: Watch UI (2–3 ngày)

- [ ] Danh sách, thêm bằng dictation, vuốt để hoàn thành, chi tiết.
- [ ] Hiển thị số `SyncOp` chờ ACK.
- [ ] Watch hoạt động đầy đủ khi không có iPhone kết nối (thêm, xem, hoàn thành).

**Hoàn thành khi:** trên Watch thật, thêm được todo bằng giọng nói và thấy trạng thái chờ đồng bộ.

### Giai đoạn 5: Đồng bộ WCSession (2–3 ngày)

- [x] `WatchSessionManager` và `PhoneSessionManager`.
- [x] Gửi và nhận `SyncOp`, ACK, đẩy DTO từ iPhone, `updateApplicationContext` cho cài đặt.
- [x] Xử lý khi `WCSession` chưa activate hoặc không reachable.

**Hoàn thành khi:** trên máy thật, tắt iPhone khi thêm 5 todo trên Watch, bật lại iPhone thì cả 5 xuất hiện và không bị trùng.

### Giai đoạn 6: iPhone UI và cài đặt (2 ngày)

- [ ] Hai tab, sửa, xóa mềm, chu kỳ riêng, màn hình cài đặt theo mục 7.
- [ ] Màn hình hướng dẫn khi quyền thông báo bị tắt.

**Hoàn thành khi:** đổi chu kỳ chung, Scheduler chạy lại (kiểm tra qua log hoặc debug view).

### Giai đoạn 7: Notification (2 ngày)

- [ ] Gắn Scheduler vào các thời điểm ở mục 5.
- [ ] Đăng ký category Xong và Nhắc lại sau.
- [ ] Hủy và đặt lại notification khi todo thay đổi.

**Hoàn thành khi:** trên máy thật, notification đúng giờ, hai action hoạt động trên cả hai máy.

### Giai đoạn 8: Kiểm thử thực tế và hoàn thiện (2–3 ngày)

- [ ] Chạy checklist mục 10.
- [ ] Đo pin trong một ngày sử dụng.
- [ ] Sửa lỗi phát sinh.

**Hoàn thành khi:** checklist mục 10 đạt hết, hoặc các mục còn lại được ghi rõ là đã biết và chấp nhận.

## 9. Ngoài phạm vi v1

Không làm các mục sau trừ khi người dùng yêu cầu:
- Watch tự nhắc khi không có iPhone.
- iCloud sync.
- Widget, Siri Shortcut, Live Activity, complication.
- Thêm todo bằng giọng nói qua `SFSpeechRecognizer` (để v1.1).
- Quiet hours.
- Đa ngôn ngữ ngoài tiếng Anh.
- Đăng App Store, ký phát hành.

## 10. Checklist kiểm thử trên thiết bị thật

- [ ] Thêm todo bằng giọng nói tiếng Việt có dấu trên Watch.
- [ ] Thêm trên Watch khi iPhone tắt; mở iPhone lại thì todo xuất hiện, không trùng.
- [ ] Đánh dấu xong trên iPhone, Watch cập nhật và ngừng nhắc.
- [ ] Đánh dấu xong trên Watch, iPhone cập nhật và ngừng nhắc.
- [ ] Notification đúng chu kỳ liên tục trong ít nhất 3 giờ, không mở app.
- [ ] Action Xong và Nhắc lại sau hoạt động trên cả hai máy.
- [ ] Đổi chu kỳ chung; todo không có chu kỳ riêng được cập nhật theo.
- [ ] Đặt chu kỳ riêng cho một todo; chỉ todo đó đổi theo.
- [ ] Tắt quyền thông báo; app hiển thị hướng dẫn đúng.
- [ ] Mất kết nối giữa hai máy một ngày; khi nối lại, dữ liệu khớp nhau.
- [ ] Xóa một todo trên Watch; iPhone không còn hiển thị và không nhắc nữa.
- [ ] Pin Watch: đo trong một ngày, ghi lại mức tiêu thụ.

## 11. Quy tắc làm việc cho Claude

- Làm đúng thứ tự giai đoạn. Không nhảy cóc.
- Không tự đổi quyết định ở mục 1. Nếu thấy cần đổi, dừng và hỏi người dùng.
- Mỗi giai đoạn: build, chạy test, commit với message nêu rõ giai đoạn (ví dụ `Phase 2: scheduler and tests`).
- Không đánh dấu checklist mục 10 là đã đạt. Chỉ người dùng xác nhận trên máy thật.
- Khi viết code liên quan đến notification, sync hoặc dictation, ghi rõ trong phản hồi những gì **chưa được kiểm chứng trên thiết bị thật**.
- Không thêm thư viện bên thứ ba nếu chưa được hỏi. Chỉ dùng framework của Apple.
- Không xóa hoặc đổi tên file trong `Shared/Model` mà không báo trước, vì có thể làm hỏng migration Core Data.
- Core Data: mọi thay đổi schema phải tạo model version mới, không sửa model cũ.
