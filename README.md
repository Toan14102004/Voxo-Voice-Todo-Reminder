# Voxo: Voice Todo Reminder

Ứng dụng ghi việc bằng giọng nói trên Apple Watch, nhắc lặp lại trên iPhone cho tới khi xong.

**Đọc `PLAN.md` trước.** Đó là nguồn sự thật của dự án: quyết định kỹ thuật, kiến trúc, lộ trình,
và mục **Trạng thái** ở đầu file cho biết đang ở đâu và việc tiếp theo là gì.

## Chạy

```bash
pod install                      # lần đầu sau khi clone
open VoiceTodo.xcworkspace
cd Shared && swift test          # 93 test, chạy trên macOS, không cần simulator
```

| Scheme | Dùng để |
|---|---|
| `VoiceTodo-Dev` | app thật |
| `VoiceTodo-SampleData` | app kèm dữ liệu mẫu, để xem giao diện |
| `VoiceTodo-Phase0` | bộ đo notification, xoá sau khi xong giai đoạn 0 |
| `VoiceTodoWatch` | app đồng hồ — **chạy scheme này để cài lên Apple Watch thật**, đừng chờ iPhone tự đẩy sang |

Yêu cầu: Xcode 26+, iOS 16+, watchOS 10+.

## Cấu trúc

```
Shared/              Swift package nội bộ, dùng chung cho cả hai app
  VoxoShared/        model, repository, merge, scheduler — không dính UI
  VoxoDesign/        màu, chữ, khoảng cách, component dùng chung
VoiceTodo/           app iPhone
VoiceTodoWatch/      app Apple Watch
PLAN.md              kế hoạch và trạng thái
CLAUDE.md            ghi chú kỹ thuật, các cái bẫy đã gặp
Docs/Tracking.md     từ template BaseSource, chưa dùng ở v1
```

## Lưu ý khi build lên máy thật

Dự án ký bằng tài khoản Apple miễn phí (Personal Team), nên:

- Provisioning profile **hết hạn sau 7 ngày** — hết hạn thì cắm máy build lại
- **Không thêm** In-App Purchase, Push Notification hay App Group: Personal Team không ký được
- Apple Watch phải bật **Chế độ nhà phát triển** và đang mở khoá thì Xcode mới cài được
- Cài lên đồng hồ: chạy **scheme `VoiceTodoWatch`**. Cài app iPhone rồi chờ nó tự đẩy sang là
  đường của App Store, bản phát triển sẽ báo "Không thể cài đặt"
- `MARKETING_VERSION` của hai target phải **giống nhau**, lệch là watchOS từ chối cài

Chi tiết các lỗi đã gặp và cách xử lý nằm trong `CLAUDE.md`.

## Nền tảng

Dự án bắt đầu từ template nội bộ BaseSource, nên còn mang theo AdMob, Firebase, mua hàng trong app
và `TrackingKit`. **v1 của Voxo không dùng những thứ đó** (xem `PLAN.md` §1 và §9); việc gỡ bỏ chưa
được quyết.
