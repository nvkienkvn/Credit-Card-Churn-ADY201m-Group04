/* ============================================================================
   ĐỀ TÀI: Analyzing and Predicting Customer Churn in Credit Card Services
   ------------------ KHAI PHÁ DỮ LIỆU BẰNG SQL -------------------------------
   ============================================================================ */

/* ============================================================================
   QUERY 1 — SO SÁNH HÀNH VI TRUNG BÌNH GIỮA 2 NHÓM KHÁCH HÀNG
   Mục tiêu: So sánh số lần quẹt thẻ (Total_Trans_Ct), tổng tiền chi tiêu 
   (Total_Trans_Amt) và mức thay đổi giao dịch Q4 so với Q1 (Total_Ct_Chng_Q4_Q1) 
   giữa nhóm ở lại (0) và nhóm rời bỏ (1).
   ============================================================================ */
SELECT
    c.Attrition_Flag AS Attrition_Flag,
    COUNT(*) AS Number_Customers,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Pct_Of_Total,
    CAST(AVG(a.Total_Trans_Ct * 1.0) AS DECIMAL(10,2)) AS Avg_Trans_Ct,
    MIN(a.Total_Trans_Ct) AS Min_Trans_Ct,
    MAX(a.Total_Trans_Ct) AS Max_Trans_Ct,
    CAST(AVG(a.Total_Trans_Amt * 1.0) AS DECIMAL(10,2)) AS Avg_Trans_Amt,
    CAST(AVG(a.Total_Ct_Chng_Q4_Q1 * 1.0) AS DECIMAL(10,3)) AS Avg_Ct_Change_Q4_vs_Q1
FROM dbo.Customers c 
INNER JOIN dbo.Card_Activity a ON c.CLIENTNUM = a.CLIENTNUM
GROUP BY c.Attrition_Flag;
/*
NHẬN XÉT (QUERY 1):
  1. Tỷ lệ rời bỏ chung của ngân hàng là 16.07% (1.627 khách rời bỏ / 8.500 khách ở lại, 
     tỷ lệ chênh lệch 5.22 : 1).
  2. Khách rời bỏ giao dịch ít hơn hẳn (~45 lần và ~3.095 USD/năm) so với khách ở lại 
     (~69 lần và ~4.655 USD/năm). Đà quẹt thẻ Quý 4 so với Quý 1 của nhóm rời bỏ cũng 
     giảm mạnh (0.554 so với 0.742).
  3. Bước tiếp theo (Query 2): Chia nhỏ số lần quẹt thẻ theo từng mốc để tìm ngưỡng 
     bắt đầu có rủi ro cao.
*/


/* ============================================================================
   QUERY 2 — TÌM NGƯỠNG RỦI RO THEO SỐ LẦN QUẸT THẺ (Total_Trans_Ct)
   Mục tiêu: Chia số lượt giao dịch thành các mốc từ thấp đến cao để xem khách 
   hàng rời bỏ tập trung ở vùng nào.
   ============================================================================ */
WITH Bang_Ct AS (
    SELECT
        c.Attrition_Flag,
        a.Total_Ct_Chng_Q4_Q1,
        CASE
            WHEN a.Total_Trans_Ct <= 30 THEN '1. <=30'
            WHEN a.Total_Trans_Ct <= 40 THEN '2. 31-40'
            WHEN a.Total_Trans_Ct <= 50 THEN '3. 41-50'
            WHEN a.Total_Trans_Ct <= 60 THEN '4. 51-60'
            WHEN a.Total_Trans_Ct <= 70 THEN '5. 61-70'
            WHEN a.Total_Trans_Ct <= 80 THEN '6. 71-80'
            WHEN a.Total_Trans_Ct <= 90 THEN '7. 81-90'
            ELSE                             '8. >90'
        END AS Trans_Ct_Group
    FROM dbo.Customers c 
    INNER JOIN dbo.Card_Activity a ON c.CLIENTNUM = a.CLIENTNUM
)
SELECT 
    Trans_Ct_Group,
    COUNT(*) AS Num_Customers,
    SUM(Attrition_Flag) AS Num_Attrited,
    CAST(SUM(Attrition_Flag) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Churn_rate_Pct,
    CAST(SUM(Attrition_Flag) * 100.0 / SUM(SUM(Attrition_Flag)) OVER() AS DECIMAL(5,2)) AS Pct_Of_All_Attrited,
    CAST(AVG(Total_Ct_Chng_Q4_Q1 * 1.0) AS DECIMAL(6,3)) AS Avg_Ct_Chng_Q4_Q1
FROM Bang_Ct
GROUP BY Trans_Ct_Group
ORDER BY Trans_Ct_Group;
/* 
NHẬN XÉT (QUERY 2):
  1. Tỷ lệ rời bỏ KHÔNG tăng đều khi số lần quẹt giảm: Nhóm quẹt 41-50 lần có tỷ lệ 
     hủy thẻ cao nhất (48.40%), cao hơn cả nhóm quẹt rất ít <= 30 lần (29.23%). 
     Lý do: Nhóm 41-50 lần đang giảm dùng thẻ mạnh vào cuối năm (Q4/Q1 = 0.628), 
     còn nhóm <= 30 lần tuy dùng ít nhưng duy trì ổn định (Q4/Q1 = 0.754).
  2. Mốc 60 lần/năm (~5 lần/tháng) là ranh giới rủi ro: Vùng <= 60 lần chứa tới 85.50% 
     tổng số khách rời bỏ của ngân hàng. Từ 61 lần trở lên rất an toàn (churn chỉ 3.88%).
  3. Vấn đề cần giải quyết ở Query 3: Nếu chỉ lọc khách quẹt <= 60 lần thì tỷ lệ hủy thẻ 
     thực tế mới đạt 34.37% (gần 2/3 là cảnh báo nhầm). Cần kết hợp thêm các biến khác 
     ở Query 3 để lọc chính xác hơn.
*/


/* ============================================================================
   QUERY 3 — KIỂM TRA THÊM 5 DẤU HIỆU PHỤ TRỢ ĐỂ LỌC CẢNH BÁO GIẢ
   Mục tiêu: Kiểm tra tác động của đà giảm giao dịch Q4/Q1 (Q3A), dư nợ xoay vòng 
   (Q3B), số lần gọi tổng đài (Q3C), số tháng ngừng dùng thẻ (Q3D) và số sản phẩm 
   đang dùng (Q3E).
   ============================================================================ */
-- Q3A: Xu hướng biến động số lượt giao dịch Q4 so với Q1 (Total_Ct_Chng_Q4_Q1)
SELECT 
    CASE 
        WHEN a.Total_Ct_Chng_Q4_Q1 < 0.5 THEN '1. <0.5'
        WHEN a.Total_Ct_Chng_Q4_Q1 < 0.7 THEN '2. 0.5-0.69'
        WHEN a.Total_Ct_Chng_Q4_Q1 < 1.0 THEN '3. 0.7-0.99'
        ELSE                                  '4. >=1.0'
    END AS Ct_Chng_Q4_Q1_Group,
    COUNT(*) AS Num_Customers,
    SUM(c.Attrition_Flag) AS Num_Attrited,
    CAST(SUM(c.Attrition_Flag) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Churn_rate_Pct,
    CAST(SUM(c.Attrition_Flag) * 100.0 / SUM(SUM(c.Attrition_Flag)) OVER() AS DECIMAL(5,2)) AS Pct_Of_All_Attrited
FROM dbo.Card_Activity a 
INNER JOIN dbo.Customers c ON a.CLIENTNUM = c.CLIENTNUM
GROUP BY 
    CASE 
        WHEN a.Total_Ct_Chng_Q4_Q1 < 0.5 THEN '1. <0.5'
        WHEN a.Total_Ct_Chng_Q4_Q1 < 0.7 THEN '2. 0.5-0.69'
        WHEN a.Total_Ct_Chng_Q4_Q1 < 1.0 THEN '3. 0.7-0.99'
        ELSE                                  '4. >=1.0'
    END
ORDER BY Ct_Chng_Q4_Q1_Group;

-- Q3B: Phân bổ rủi ro rời bỏ theo mức Dư nợ xoay vòng (Total_Revolving_Bal)
SELECT 
    CASE 
        WHEN a.Total_Revolving_Bal = 0    THEN '1. =0'
        WHEN a.Total_Revolving_Bal < 500  THEN '2. 1-499'
        WHEN a.Total_Revolving_Bal < 1000 THEN '3. 500-999'
        WHEN a.Total_Revolving_Bal < 1500 THEN '4. 1000-1499'
        ELSE                                   '5. >=1500'
    END AS Revolving_Bal_Group,
    COUNT(*) AS Num_Customers,
    SUM(c.Attrition_Flag) AS Num_Attrited,
    CAST(SUM(c.Attrition_Flag) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Churn_rate_Pct,
    CAST(SUM(c.Attrition_Flag) * 100.0 / SUM(SUM(c.Attrition_Flag)) OVER() AS DECIMAL(5,2)) AS Pct_Of_All_Attrited
FROM dbo.Card_Activity a 
INNER JOIN dbo.Customers c ON a.CLIENTNUM = c.CLIENTNUM
GROUP BY 
    CASE 
        WHEN a.Total_Revolving_Bal = 0    THEN '1. =0'
        WHEN a.Total_Revolving_Bal < 500  THEN '2. 1-499'
        WHEN a.Total_Revolving_Bal < 1000 THEN '3. 500-999'
        WHEN a.Total_Revolving_Bal < 1500 THEN '4. 1000-1499'
        ELSE                                   '5. >=1500'
    END
ORDER BY Revolving_Bal_Group;

-- Q3C: Tỷ lệ Churn theo Số lần liên hệ tổng đài CSKH (Contacts_Count_12_mon)
SELECT 
    a.Contacts_Count_12_mon,
    COUNT(*) AS Num_Customers,
    SUM(c.Attrition_Flag) AS Num_Attrited,
    CAST(SUM(c.Attrition_Flag) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Churn_rate_Pct,
    CAST(SUM(c.Attrition_Flag) * 100.0 / SUM(SUM(c.Attrition_Flag)) OVER() AS DECIMAL(5,2)) AS Pct_Of_All_Attrited
FROM dbo.Card_Activity a
INNER JOIN dbo.Customers c ON a.CLIENTNUM = c.CLIENTNUM
GROUP BY a.Contacts_Count_12_mon
ORDER BY a.Contacts_Count_12_mon;

-- Q3D: Tỷ lệ Churn theo Số tháng không giao dịch (Months_Inactive_12_mon)
SELECT 
    a.Months_Inactive_12_mon,
    COUNT(*) AS Num_Customers,
    SUM(c.Attrition_Flag) AS Num_Attrited,
    CAST(SUM(c.Attrition_Flag) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Churn_rate_Pct,
    CAST(SUM(c.Attrition_Flag) * 100.0 / SUM(SUM(c.Attrition_Flag)) OVER() AS DECIMAL(5,2)) AS Pct_Of_All_Attrited
FROM dbo.Card_Activity a
INNER JOIN dbo.Customers c ON a.CLIENTNUM = c.CLIENTNUM
GROUP BY a.Months_Inactive_12_mon
ORDER BY a.Months_Inactive_12_mon;

-- Q3E: Tỷ lệ Churn theo Tổng số sản phẩm gắn kết (Total_Relationship_Count)
SELECT 
    c.Total_Relationship_Count,
    COUNT(*) AS Num_Customers,
    SUM(c.Attrition_Flag) AS Num_Attrited,
    CAST(SUM(c.Attrition_Flag) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Churn_rate_Pct,
    CAST(SUM(c.Attrition_Flag) * 100.0 / SUM(SUM(c.Attrition_Flag)) OVER() AS DECIMAL(5,2)) AS Pct_Of_All_Attrited
FROM dbo.Card_Activity a
INNER JOIN dbo.Customers c ON a.CLIENTNUM = c.CLIENTNUM
GROUP BY c.Total_Relationship_Count
ORDER BY c.Total_Relationship_Count;
/*
NHẬN XÉT (QUERY 3):
  1. Đà giảm giao dịch (Q3A - Total_Ct_Chng_Q4_Q1):
     - Nhóm giảm mạnh < 0.5 (Q4 quẹt chưa bằng một nửa Q1) có tỷ lệ rời bỏ tới 50.88% 
       và chiếm 42.84% tổng số khách hủy thẻ. Nhóm giữ nhịp quẹt >= 0.7 rất an toàn (~7-8%).
  2. Dư nợ xoay vòng (Q3B - Total_Revolving_Bal):
     - Nhóm dư nợ < 500 USD chiếm 61.34% tổng số khách rời bỏ. 
     - Trong đó, nhóm nợ = 0 USD chiếm đông nhất (54.89% tổng ca hủy thẻ) nhưng tỷ lệ 
       churn chỉ 36.15% vì lẫn cả khách tốt trả nợ đúng hạn. Nhóm nợ lẻ 1-499 USD có 
       tỷ lệ hủy thẻ vọt lên 84.00% (dấu hiệu chỉ còn nợ/phí nhỏ kỳ cuối trước khi đóng thẻ).
  3. Số lần gọi tổng đài (Q3C - Contacts_Count_12_mon):
     - Gọi càng nhiều càng dễ hủy thẻ: từ >= 3 lần trở lên tỷ lệ rời bỏ tăng cao (20% - 33%), 
       đặc biệt cả 54/54 khách gọi 6 lần đều hủy thẻ (100%).
  4. Số tháng không giao dịch (Q3D - Months_Inactive_12_mon):
     - Rủi ro tập trung cao nhất ở mốc nghỉ 3-4 tháng (chiếm 58.76% tổng số khách rời bỏ).
     - Mốc 0 tháng có tỷ lệ 51.72% là do mẫu quá nhỏ (chỉ có 29 người). Mốc 6 tháng 
       tỷ lệ churn giảm về 15.32% vì người muốn hủy đã đóng thẻ ở tháng thứ 3-4, số còn lại 
       chủ yếu là thẻ mở dự phòng để quên trong ví.
  5. Số sản phẩm sử dụng (Q3E - Total_Relationship_Count):
     - Khách chỉ dùng 1-2 sản phẩm rất dễ rời bỏ (25.6% - 27.8%). Khi dùng từ 3 sản phẩm 
       trở lên, khách gắn bó hơn và tỷ lệ rời bỏ giảm xuống còn 10.5% - 17.3%.
*/

/* ============================================================================
   QUERY 4 — CHẤM ĐIỂM RỦI RO TỔNG HỢP (RISK SCORE TỪ 0 ĐẾN 6 ĐIỂM)
   Mục tiêu: Cộng gộp 6 dấu hiệu rủi ro từ Query 2 và Query 3 (mỗi dấu hiệu = 1 điểm) 
   để lọc danh sách khách hàng cần chăm sóc ưu tiên.
   ============================================================================ */

-- Q4A: Phân bổ Churn theo Thang điểm rủi ro 0 - 6
;WITH Risk_CTE AS (
    SELECT 
        c.CLIENTNUM,
        c.Card_Category,
        c.Attrition_Flag,
        a.Total_Trans_Ct,
        a.Total_Ct_Chng_Q4_Q1,
        a.Total_Revolving_Bal,
        a.Months_Inactive_12_mon,
        a.Contacts_Count_12_mon,
        c.Total_Relationship_Count,
        a.Total_Trans_Amt,
        (CASE WHEN a.Total_Trans_Ct <= 60          THEN 1 ELSE 0 END
       + CASE WHEN a.Total_Ct_Chng_Q4_Q1 < 0.5     THEN 1 ELSE 0 END
       + CASE WHEN a.Total_Revolving_Bal < 500     THEN 1 ELSE 0 END
       + CASE WHEN a.Months_Inactive_12_mon >= 3   THEN 1 ELSE 0 END
       + CASE WHEN a.Contacts_Count_12_mon >= 3    THEN 1 ELSE 0 END
       + CASE WHEN c.Total_Relationship_Count <= 2 THEN 1 ELSE 0 END) AS Risk_Score
    FROM dbo.Card_Activity a
    INNER JOIN dbo.Customers c ON a.CLIENTNUM = c.CLIENTNUM
)
SELECT 
    Risk_Score,
    COUNT(*) AS Num_Customers,
    SUM(Attrition_Flag) AS Num_Attrited,
    CAST(SUM(Attrition_Flag) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Churn_rate_Pct,
    CAST(SUM(Attrition_Flag) * 100.0 / SUM(SUM(Attrition_Flag)) OVER() AS DECIMAL(5,2)) AS Pct_Of_All_Attrited
FROM Risk_CTE
GROUP BY Risk_Score
ORDER BY Risk_Score DESC;

-- Q4B: Watch-list 20 khách hàng ĐANG HIỆN HỮU (Attrition_Flag = 0) có điểm rủi ro cao nhất (>= 4 điểm)
;WITH Risk_CTE AS (
    SELECT 
        c.CLIENTNUM,
        c.Card_Category,
        c.Attrition_Flag,
        a.Total_Trans_Ct,
        a.Total_Ct_Chng_Q4_Q1,
        a.Total_Revolving_Bal,
        a.Months_Inactive_12_mon,
        a.Contacts_Count_12_mon,
        c.Total_Relationship_Count,
        a.Total_Trans_Amt,
        (CASE WHEN a.Total_Trans_Ct <= 60          THEN 1 ELSE 0 END
       + CASE WHEN a.Total_Ct_Chng_Q4_Q1 < 0.5     THEN 1 ELSE 0 END
       + CASE WHEN a.Total_Revolving_Bal < 500     THEN 1 ELSE 0 END
       + CASE WHEN a.Months_Inactive_12_mon >= 3   THEN 1 ELSE 0 END
       + CASE WHEN a.Contacts_Count_12_mon >= 3    THEN 1 ELSE 0 END
       + CASE WHEN c.Total_Relationship_Count <= 2 THEN 1 ELSE 0 END) AS Risk_Score
    FROM dbo.Card_Activity a
    INNER JOIN dbo.Customers c ON a.CLIENTNUM = c.CLIENTNUM
)
SELECT TOP 20
    CLIENTNUM,
    Card_Category,
    Risk_Score,
    Total_Trans_Ct,
    Total_Ct_Chng_Q4_Q1,
    Total_Revolving_Bal,
    Months_Inactive_12_mon,
    Contacts_Count_12_mon,
    Total_Relationship_Count,
    Total_Trans_Amt
FROM Risk_CTE
WHERE Attrition_Flag = 0
  AND Risk_Score >= 4  
ORDER BY Risk_Score DESC, Total_Trans_Amt DESC;
/*
NHẬN XÉT (QUERY 4):
  1. Hiệu quả của thang điểm 0 - 6:
     - Điểm càng cao, tỷ lệ rời bỏ thật càng tăng rõ rệt (từ < 2% ở mức 0-1 điểm lên 
       85% - 100% ở mức 5-6 điểm), khắc phục được việc báo động nhầm khi chỉ nhìn 1 biến.
  2. Đề xuất chia nhóm chăm sóc:
     - Nhóm Nguy kịch (>= 4 điểm): Rủi ro hủy thẻ rất cao nhưng số lượng ít -> Bộ phận 
       CSKH gọi điện hỗ trợ trực tiếp (ưu tiên người chi tiêu lớn như danh sách Q4B).
     - Nhóm Cảnh báo sớm (3 điểm): Gửi ưu đãi tự động (hoàn tiền, miễn phí thường niên) 
       để khuyến khích quẹt thẻ trở lại.
     - Nhóm An toàn (<= 2 điểm): Duy trì tích điểm bình thường để tiết kiệm chi phí.
*/