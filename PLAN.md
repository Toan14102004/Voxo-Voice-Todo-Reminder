# Tidy — Personal Todo App: Kế hoạch triển khai

> Tài liệu này là nguồn sự thật cho việc phát triển. Khi có mâu thuẫn giữa code và tài liệu, hỏi người dùng trước khi đổi.

## Trạng thái — cập nhật 09/11/2026

**Dự án vừa đổi spec: từ "Voxo" tự thiết kế sang design Figma "Tidy".** Xem §1.8.
Phần nền (model, repository, merge, đồng bộ, lên lịch nhắc) giữ nguyên và dùng lại được;
phần giao diện phải dựng lại theo design.

### Hai việc song song

**1. Đo trên máy thật — vẫn còn nợ, không phụ thuộc đổi spec**

| Phép đo | Cách chạy | Kết quả |
|---|---|---|
| Nhắc việc có nổ đúng giờ không | Mở app, cho phép thông báo, thêm 2–3 việc, để qua đêm. Xem **Settings → Chẩn đoán nhắc việc** | _chưa chạy_ |
| Đồng bộ Watch ↔ iPhone | Để iPhone xa, thêm 3 việc trên đồng hồ, mở iPhone kiểm tra | _chưa chạy_ |
| Dictation tiếng Việt | Trên đồng hồ, trang 2, đọc 10 câu mẫu | _chưa chạy_ |

Trước khi đo: tắt "Tóm tắt theo lịch trình", không bật Focus, không xoá thông báo của app.

**2. Dựng lại giao diện theo Tidy** — đã xong **Giai đoạn A → F**; tiếp theo là **Giai đoạn G
(Stats)** ở §8.

### Đã xong (dùng lại được)

- Core Data model, `TodoRepository`, `MergeService`, outbox — 37 test, chạy bằng `cd Shared && swift test`
- `ReminderScheduler` (hàm thuần) + `ReminderService` (đặt lịch thật, trigger lặp)
- Đồng bộ WCSession hai chiều — **chưa chạy thử trên máy thật**
- Khung giao diện iOS + Watch, điều hướng FlowStacks với Coordinator enum

### Phải làm lại hoặc mở rộng

- Toàn bộ lớp hình ảnh: màu, font **Be Vietnam Pro**, icon, component — `VoxoDesign` hiện dùng indigo tự chọn
- Model thêm `priority`, `dueAt`, `listId`, `repeatRule` và entity `TodoList` → **Core Data model version 2**
- Từ 3 màn lên 10 màn, 4 tab
- Chuyển sang **song ngữ VI / EN** (trước đây plan ghi chỉ tiếng Anh)

### Chạy thế nào

```bash
pod install                      # sau khi pull lần đầu
open VoiceTodo.xcworkspace
cd Shared && swift test          # 37 test, không cần simulator
```

Scheme `VoiceTodo-Dev` là app thật. `VoiceTodo-SampleData` có dữ liệu mẫu.
`VoiceTodo-Phase0` là bộ đo notification, xoá sau khi đo xong.

Target vẫn tên `VoiceTodo` / bundle `com.limgrow.voxo` — **chưa đổi theo tên Tidy**, chưa quyết có đổi không.

Ký bằng tài khoản Apple miễn phí nên **profile hết hạn sau 7 ngày**, hết hạn thì cắm máy build lại.

Code mới nhất nằm trên nhánh **`develop`**, không phải `main`.

## 0. Thông tin dự án

| Mục | Giá trị |
|---|---|
| Tên app | Tidy — Personal Todo App |
| Phụ đề | Minimal todo, nhắc việc lặp lại |
| Thiết kế | Figma, board **"Tidy – Todo App"** (node `9155:14723`). Design là nguồn sự thật cho giao diện |
| Nền tảng | iOS 16+, watchOS 10+ |
| Ngôn ngữ / UI | Swift, SwiftUI. **Song ngữ VI / EN**, mọi chuỗi phải có cả hai |
| Lưu trữ | Core Data, mỗi thiết bị một store |
| Đồng bộ | WatchConnectivity (`transferUserInfo`, `updateApplicationContext`) |
| Khung máy | iPhone 390×844 · Apple Watch 46mm 396×484 |
| Phạm vi | Dùng cá nhân trước, chuẩn bị cho App Store sau |

### Design system (lấy từ Figma, không đoán từ pixel)

| Token | Giá trị |
|---|---|
| Primary / tint | `#1E6FD0` / `#EEF5FE` |
| Chữ | Ink `#1C1917` · phụ `#78716C` · mờ `#A8A29E` |
| Nền / viền | `#FAFAF9` / `#E7E5E4` |
| Ưu tiên | Cao `#EF4444` · Vừa `#F59E0B` · Thấp `#3B82F6` |
| Success | `#16A34A` |
| Dark mode | nền `#0C0A09` · card `#1C1917` · giữ nguyên màu nhấn |
| Watch | nền đen tuyệt đối · nhấn `#4D9AF0` / `#8CC0F7` · chữ ≥ 13pt |
| Font | **Be Vietnam Pro** — Display 28 Bold · Title 24 Bold · Headline 17 SemiBold · Body 15–16 · Caption 12–13 · Overline 12 SemiBold |
| Icon | **Material Symbols Rounded**, một bộ duy nhất, 20/24px |
| Lưới | 8pt · lề màn 24 · spacing 4/8/12/16/24/32 |
| Bo góc | chip 8–18 · task row 14 · card/button 16–20 · sheet 28 |
| Chạm | tối thiểu 44pt · tương phản WCAG AA |

Font và icon **chưa có trong repo**, phải bổ sung trước khi dựng giao diện.

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
8. **Chuyển sang spec Tidy** (chốt 09/11/2026, thay thiết kế Voxo tự dựng trước đó). Hệ quả:
   - App đổi tên thành **Tidy**, giao diện bám design Figma.
   - **Song ngữ VI / EN**, thay cho quy định chỉ tiếng Anh ở §7 bản cũ.
   - `Todo` thêm **mức ưu tiên**, **ngày đến hạn**, **thuộc danh sách nào**, **luật lặp** (§4).
   - iPhone có 4 tab: **Today · Calendar · Lists · Stats**, cộng Settings và Onboarding.
9. **Không làm Wear OS ở v1** dù design có vẽ. Đó là app Android/Kotlin, repo riêng, không phải một target
   của project này.
10. **Watch giữ dictation đơn giản** (`TextField` + bàn phím đọc của hệ thống). Phần tách câu nói thành
   tiêu đề + ngày giờ + danh sách mà design mô tả ở mục 05 **để v2** — nó khó hơn toàn bộ phần còn lại cộng lại.

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
| `priority` | Int16 | Có | 0 không đặt · 1 Thấp · 2 Vừa · 3 Cao. Mặc định 0 |
| `dueAt` | Date | Không | Hạn chót. Không có nghĩa là việc không gắn ngày |
| `listId` | UUID | Không | Thuộc danh sách nào. Nil nghĩa là chưa phân loại |
| `repeatRule` | String | Không | `daily` / `weekly` / nil. Khác `intervalOverride` (chu kỳ *nhắc*) |

Index: `id` (unique), `isDone`, `deletedAt`, `dueAt`, `listId`.

**4 trường cuối là bổ sung của spec Tidy** so với bản đầu. Theo §11, đây là đổi schema nên phải tạo
Core Data model version mới, không sửa `version1` tại chỗ.

### Entity `TodoList` (mới, theo spec Tidy)

| Thuộc tính | Kiểu | Bắt buộc | Ghi chú |
|---|---|---|---|
| `id` | UUID | Có | |
| `name` | String | Có | Không rỗng sau trim |
| `colorHex` | String | Có | Màu nhãn, dùng cho icon và chip |
| `createdAt` | Date | Có | |
| `updatedAt` | Date | Có | Dùng cho merge, cùng luật với `Todo` |
| `deletedAt` | Date | Không | Tombstone, cùng luật 30 ngày |

Xoá danh sách **không xoá** todo trong đó: các todo liên quan chuyển `listId` về nil.

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

Bám design Figma board **"Tidy – Todo App"**. Dưới đây là cấu trúc; chi tiết pixel đọc thẳng từ Figma.

### Đồ thị điều hướng — 10 đích đến

```
Onboarding (chỉ lần đầu) ──► Today
                              │
Tab bar:  Today · Calendar · Lists · Stats
                              │
          ├─ Quick add (bottom sheet)
          ├─ Task detail
          ├─ New list (modal)
          ├─ List view
          └─ Settings
```

Ràng buộc trong design: **từ bất kỳ tab nào cũng không sâu quá 2 cấp.**

### Màn hình

| Màn | Nội dung chính |
|---|---|
| **Onboarding** | Chỉ hiện lần đầu, rồi vào thẳng Today |
| **Today** | Danh sách việc hôm nay, task row vuốt được, FAB thêm nhanh |
| **Calendar** | Dải ngày (component `Day`), event card theo ngày |
| **Lists** | List card, mỗi danh sách một màu nhãn; vào List view xem chi tiết |
| **Stats** | Stat card và Progress card |
| **Quick add** | Bottom sheet, bo góc 28 |
| **Task detail** | Details card: tiêu đề, ưu tiên, hạn, danh sách, chu kỳ nhắc |
| **New list** | Modal, đặt tên và chọn màu |
| **Settings** | Chu kỳ nhắc chung, quyền thông báo, trạng thái đồng bộ, ngôn ngữ |

### Component đã vẽ sẵn trong Figma

Task row (2 biến thể) · Chip / Chip selected / Chip priority · Button Primary · FAB · List card ·
Event card · Tab bar · Day · Stat card · Progress card · Details card · Bottom sheet.

Dựng chúng trong `VoxoDesign` trước, rồi mới lắp màn hình.

### Tương tác (DS / Rules)

- **Vuốt phải** = hoàn thành · **vuốt trái** = dời sang mai / xoá · **Hoàn tác 4 giây**
- Check task: gạch ngang + mờ dần + haptic nhẹ
- FAB nổi trên cùng, cách tab bar 14px, đổ bóng xanh 30%
- Ngày hiển thị theo ngôn ngữ: `T7, 07/11` ↔ `Sat, Nov 7`

### Apple Watch

- Nền đen tuyệt đối, nhấn `#4D9AF0` / `#8CC0F7`, chữ ≥ 13pt, chạm ≥ 44pt
- v1: danh sách việc + thêm bằng dictation hệ thống + vuốt hoàn thành
- Nhắc có nút **Xong** và **Hoãn 10 phút**
- Luồng voice → task tách ngữ nghĩa ở mục 05 của design: **để v2** (§1.10)

### Quy ước

- **Song ngữ VI / EN.** Mọi chuỗi nằm trong `Localizable.xcstrings`, không hardcode
- Hỗ trợ Dynamic Type
- Không dùng màu làm cách duy nhất để truyền thông tin: ưu tiên phải có cả chữ hoặc hình, không chỉ chấm màu

## 8. Lộ trình thực hiện

Giai đoạn 0–5 của bản kế hoạch đầu **đã xong** (xem mục Trạng thái ở đầu file): model, repository,
merge, outbox, đồng bộ WCSession, bộ lên lịch nhắc. Phần đó **không phải làm lại** khi chuyển sang
spec Tidy — chỉ lớp giao diện và vài trường trong model là mở rộng.

Mỗi giai đoạn kết thúc bằng: build pass, test pass, commit đặt tên theo giai đoạn.

### Giai đoạn A: Nền thiết kế (1 ngày)

- [ ] Nhúng font **Be Vietnam Pro** (các weight Regular / Medium / SemiBold / Bold) vào cả 2 target
- [ ] Thêm bộ icon **Material Symbols Rounded** hoặc chốt dùng SF Symbols thay thế và ghi lại lý do
- [ ] Viết lại `VoxoDesign` theo token ở §0: màu, thang chữ, bo góc, spacing
- [ ] Bật song ngữ: mọi chuỗi vào `Localizable.xcstrings`, có đủ VI và EN

**Hoàn thành khi:** đổi ngôn ngữ máy giữa VI và EN, app đổi theo, không còn chuỗi hardcode.

### Giai đoạn B: Mở rộng model — **XONG 09/11/2026**

- [x] Core Data **model version 2**: `Todo` thêm `priority`, `dueAt`, `listId`, `repeatRule`
- [x] Entity `TodoList` mới
- [x] Migration từ version 1, có test — **viết tay trong `StoreMigrator`**, vì model dựng bằng code
      nên Core Data không tự tìm được model nguồn
- [x] `TodoDTO` và `MergeService` cập nhật theo; xoá danh sách thì todo về `listId = nil`

50 test, trong đó 5 test di trú và 8 test danh sách.

### Giai đoạn C: Component — **XONG 09/11/2026**

- [x] Dựng trong `VoxoDesign`: Task row, Chip, Chip priority, Button Primary, FAB, List card,
      Event card, Tab bar, Day, Stat card, Progress card, Details card, Bottom sheet
- [x] Màn xem trước: chạy scheme `VoiceTodo-Dev` với cờ **`-gallery`** (thêm `-galleryBottom`
      để xem nửa dưới mà không phải cuộn)

**Ánh xạ icon Material Symbols → SF Symbols** nằm trong `VoxoIcon.swift`, viết thành bảng để đối
chiếu được từng cái với Figma.

### Giai đoạn D: Today + Quick add + Task detail — **code xong 09/11/2026, chờ thử máy thật**

- [x] Today theo design: header lời chào, thẻ tiến độ, nhóm Quá hạn / Hôm nay / Đã xong, FAB
- [x] Vuốt phải hoàn thành, vuốt trái dời sang mai / xoá, **hoàn tác 4 giây** (`UndoCenter`)
- [x] Bottom sheet Thêm nhanh
- [x] Task detail: ưu tiên, hạn, nhắc, lặp lại, danh sách, xoá
- [x] Thêm trường `note` vào model (design có ô ghi chú mà §4 chưa có)

**Chưa làm — cần quyết:** design màn chi tiết có mục **"VIỆC CON · 2/3"** (subtask). Đây là entity
mới, không có trong §4. Bỏ qua ở Giai đoạn D.

**Chưa kiểm chứng trên máy thật:** vuốt, hoàn tác, tạo việc từ Quick add. Mới chạy simulator.

### Giai đoạn E: Lists + New list — **code xong 09/11/2026**

- [x] Màn Lists: lưới 2 cột, thẻ nền màu riêng, ô "Danh sách mới"
- [x] Modal New list: tên, 6 màu, 6 biểu tượng, có xem trước thẻ ngay
- [x] List view: việc trong một danh sách, xoá danh sách kèm cảnh báo việc vẫn được giữ
- [x] **Lọc thông minh**: Ưu tiên cao / 7 ngày tới / Đã hoàn thành — tính từ dữ liệu, không thêm entity
- [x] Thêm trường `icon` cho `TodoList` (design ghi "Chọn màu & emoji")

- [x] Dòng "Danh sách" ở màn chi tiết đổi được danh sách (menu, có mục **Không thuộc danh sách**)

### Giai đoạn F: Calendar — **code xong 09/11/2026**

- [x] Tiêu đề tháng + mũi tên `‹` `›` chuyển tuần (giữ nguyên thứ đang chọn khi nhảy tuần)
- [x] Dải 7 ngày T2 → CN, ô đang chọn tô xanh
- [x] Dòng ngày "Thứ Hai, 9/11 · 4 việc"
- [x] Dòng thời gian: cột giờ 24h bên trái + `VoxoEventCard` nền tô theo màu danh sách
- [x] Chỉ hiện việc **có `dueAt`** — lịch nói về *khi nào*, việc không hạn thì không có chỗ đứng
- [x] Chạm vào thẻ mở màn chi tiết
- [x] Dữ liệu mẫu (`-voxoSeed`) nay có giờ, để xem được màn này

**Chưa làm:** design có dòng gợi ý "Giữ để kéo thả, đổi giờ nhanh". Cử chỉ kéo thả đổi giờ chưa
dựng; màn đang hiện câu "Kéo thả để đổi giờ — sẽ làm sau" thay cho nó.

### Giai đoạn G: Stats (1–2 ngày)

- [ ] Stat card và Progress card, tính từ dữ liệu thật

### Giai đoạn H: Onboarding + Settings (1 ngày)

- [ ] Onboarding chỉ hiện lần đầu
- [ ] Settings: chu kỳ chung, quyền thông báo, trạng thái đồng bộ, đổi ngôn ngữ

### Giai đoạn I: Notification actions (1 ngày)

- [ ] Nút **Xong** và **Hoãn 10 phút** trên thông báo, chạy trên cả iPhone lẫn Watch

### Giai đoạn J: Kiểm thử thực tế (2–3 ngày)

- [ ] Chạy checklist mục 10
- [ ] Đo pin một ngày

## 9. Ngoài phạm vi v1

Không làm các mục sau trừ khi người dùng yêu cầu:
- Watch tự nhắc khi không có iPhone.
- iCloud sync.
- Widget, Siri Shortcut, Live Activity, complication.
- **Wear OS** (§1.9) — app Android riêng, không nằm trong repo này.
- **Tách câu nói thành tiêu đề + ngày giờ + danh sách** qua `SFSpeechRecognizer` (§1.10, mục 05 của design).
- Widget, complication 🎙 trên mặt đồng hồ.
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
