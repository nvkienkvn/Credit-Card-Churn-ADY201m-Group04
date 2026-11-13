# Analyzing and Predicting Customer Churn in Credit Card Services Using Machine Learning and SQL

Đồ án cuối kỳ môn **Data Science with Python & SQL (ADY201m)** — Lớp **AI2107**, Khoa Trí tuệ Nhân tạo, Đại học FPT Hà Nội (2026).

## 1. Giới thiệu đề tài
Dự án xây dựng quy trình Khoa học Dữ liệu khép kín nhằm phát hiện sớm dấu hiệu khách hàng rời bỏ dịch vụ thẻ tín dụng (`Churn`) và đề xuất giải pháp giữ chân khách hàng cho ngân hàng:
* **Dữ liệu:** *BankChurners* (Kaggle) gồm **10.127 hồ sơ khách hàng** và **23 thuộc tính gốc** (còn **20 thuộc tính** sau tiền xử lý).
* **Tỷ lệ mất cân bằng nhãn:** **83,93%** khách hàng ở lại (`8.500`) vs. **16,07%** khách hàng rời bỏ (`1.627`) — tỷ lệ `5,22 : 1`.
* **Công cụ sử dụng:** SQL Server , Python (Pandas, Matplotlib, Seaborn, Scikit-learn), Google Looker Studio.

## 2. Thành viên thực hiện
* **Giảng viên hướng dẫn:** Ngô Trường Minh
* **Nhóm thực hiện:** Nhóm 04 — Lớp AI2107

| Họ và Tên | MSSV | Vai trò & Công việc chính |
| :--- | :---: | :--- |
| **Nguyễn Văn Kiên** | `HE200682` | Trưởng nhóm — Thiết kế CSDL SQL Server, truy vấn T-SQL khai phá dữ liệu. |
| **Tống Việt Thảo** | `HE204303` | Tiền xử lý & làm sạch dữ liệu (`data_clean.ipynb`), xây dựng & đánh giá mô hình ML (`ML.ipynb`). |
| **Nguyễn Anh Tới** | `HE201009` | Phân tích khám phá & trực quan hóa (`EDA.ipynb`), thiết kế Looker Studio Dashboard & báo cáo. |

## 3. Cấu trúc thư mục
```text
Credit-Card-Churn-ADY201m-Group04/
├── data/raw/
│   ├── BankChurners.csv            # Dữ liệu gốc từ Kaggle
│   └── BankChurners_clean.csv      # Dữ liệu đã làm sạch
├── notebooks/
│   ├── data_clean.ipynb            # Làm sạch dữ liệu & kiểm định chất lượng
│   ├── EDA.ipynb                   # Phân tích khám phá & trực quan hóa biểu đồ
│   └── ML.ipynb                    # Huấn luyện mô hình dự báo & xuất Watchlist
├── report/
|   ├── Final_Project_Nhom04_AI2107_TV # Bản Final Report
├── sql/
│   ├── taidulieu.sql               # ETL nạp dữ liệu & tạo 2 bảng Customers, Card_Activity
│   └── khaiphadulieu.sql           # 4 truy vấn phân tích nghiệp vụ & chấm điểm Risk_Score
└── README.md
