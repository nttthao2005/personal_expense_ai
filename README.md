# Personal Expense AI

Ứng dụng quản lý chi tiêu cá nhân được xây dựng bằng **Flutter**, hỗ trợ theo dõi thu nhập, chi tiêu, quản lý ngân sách và mục tiêu tiết kiệm. Ứng dụng tích hợp OCR để trích xuất thông tin từ hóa đơn và sử dụng Gemini AI thông qua backend để phân tích tình hình tài chính.

## ✨ Tính năng chính

- **Quản lý giao dịch:** Thêm, sửa, xóa và tìm kiếm các giao dịch thu nhập, chi tiêu; hỗ trợ phân loại theo danh mục.
- **Thống kê tài chính:** Tổng hợp thu nhập, chi tiêu và số dư theo ngày, tháng, năm hoặc khoảng thời gian tùy chỉnh.
- **Biểu đồ báo cáo:** Trực quan hóa chi tiêu theo danh mục và theo dõi xu hướng dòng tiền qua các kỳ.
- **Quản lý ngân sách:** Thiết lập ngân sách chi tiêu theo danh mục và theo dõi tiến độ sử dụng.
- **Mục tiêu tiết kiệm:** Tạo mục tiêu, cập nhật số tiền đã tiết kiệm và theo dõi tiến độ hoàn thành.
- **Quét hóa đơn bằng OCR:** Sử dụng Google ML Kit để nhận diện văn bản trên hóa đơn, hỗ trợ trích xuất thông tin phục vụ tạo giao dịch.
- **Phân tích tài chính bằng AI:** Tích hợp Gemini thông qua backend FastAPI để phân tích dữ liệu thu nhập và chi tiêu, đưa ra nhận xét hỗ trợ quản lý tài chính cá nhân.

## 🛠️ Công nghệ sử dụng

| Thành phần | Công nghệ |
|---|---|
| Ứng dụng di động | Flutter, Dart |
| Cơ sở dữ liệu cục bộ | SQLite |
| Nhận diện văn bản OCR | Google ML Kit Text Recognition |
| Biểu đồ thống kê | fl_chart |
| Backend API | Python, FastAPI |
| Phân tích AI | Google Gemini API |
| Giao tiếp với backend | HTTP / REST API |

## 📁 Cấu trúc dự án

```text
personal_expense_ai/
├── android/                 # Cấu hình Android
├── ios/                     # Cấu hình iOS
├── linux/                   # Cấu hình Linux
├── macos/                   # Cấu hình macOS
├── web/                     # Cấu hình Web
├── windows/                 # Cấu hình Windows
├── backend/
│   ├── main.py              # Backend FastAPI
│   └── schemas.py            # Các schema dữ liệu API
├── lib/
│   ├── models/              # Các model dữ liệu
│   ├── screens/             # Các màn hình ứng dụng
│   ├── services/            # Xử lý dữ liệu, database, OCR, AI
│   └── widgets/              # Các thành phần giao diện
├── test/                    # Các bài kiểm thử
├── pubspec.yaml             # Dependencies Flutter
└── README.md
```

## ⚙️ Yêu cầu hệ thống

- Flutter SDK và Dart SDK tương thích với dự án.
- Android Studio hoặc môi trường phát triển Flutter tương đương.
- Python 3.11 trở lên để chạy backend.
- Gemini API key để sử dụng tính năng phân tích tài chính bằng AI.

## 🚀 Cài đặt và chạy ứng dụng

### 1. Tải mã nguồn
git clone https://github.com/nttthao2005/personal_expense_ai.git
cd personal_expense_ai

### 2. Cài đặt dependencies Flutter 
flutter pub get

### 3. Cấu hình backend

Mở thư mục `backend`, tạo môi trường Python ảo và cài đặt các thư viện cần thiết theo cấu hình backend của dự án.

Trên Windows PowerShell:

cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install fastapi uvicorn google-genai python-dotenv

Tạo file `backend/.env` và cấu hình Gemini API key theo tên biến môi trường mà backend sử dụng. **Không đưa file `.env` hoặc API key lên GitHub.**

Khởi chạy backend từ thư mục `backend`: python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Có thể kiểm tra trạng thái backend tại: http://127.0.0.1:8000/health

### 4. Chạy ứng dụng Flutter

Mở một terminal khác tại thư mục gốc của dự án: flutter run

Khi chạy trên Android Emulator, ứng dụng sử dụng địa chỉ `http://10.0.2.2:8000` để kết nối đến backend chạy trên máy tính. Nếu chạy trên thiết bị hoặc nền tảng khác, cần cấu hình lại địa chỉ backend phù hợp.

## 🔒 Lưu trữ và bảo mật

- Dữ liệu giao dịch được lưu trữ cục bộ bằng SQLite.
- Backend xử lý yêu cầu phân tích AI và giữ Gemini API key ở phía máy chủ, không nhúng khóa API trực tiếp vào mã nguồn Flutter.
- OCR được thực hiện trên thiết bị; ứng dụng lưu thông tin văn bản OCR phục vụ xử lý giao dịch, không lưu ảnh hóa đơn như một phần của quy trình này.
- Các file môi trường, database cục bộ và thư mục sinh tự động cần được loại trừ khỏi Git theo cấu hình `.gitignore`.

## 🧪 Kiểm thử

Chạy phân tích mã nguồn: flutter analyze
Chạy các bài kiểm thử: flutter test

## 🎯 Mục tiêu dự án

Xây dựng một ứng dụng quản lý tài chính cá nhân có giao diện trực quan, dễ sử dụng, kết hợp lưu trữ dữ liệu cục bộ với OCR và AI nhằm hỗ trợ người dùng theo dõi thói quen chi tiêu và quản lý ngân sách hiệu quả hơn.

## 👤 Tác giả

**nttthao2005**

GitHub: [github.com/nttthao2005](https://github.com/nttthao2005)

