Use bank_churn;
Go
DROP TABLE IF EXISTS dbo.Card_Activity;
GO
DROP TABLE IF EXISTS dbo.Customers;
GO
Create table dbo.Customers(
CLIENTNUM BIGINT Primary key,
Attrition_Flag TINYINT,
Customer_Age TINYINT,
Gender Varchar(1),
Dependent_count TINYINT,
Education_Level VARCHAR(30),
Marital_Status VARCHAR(20),
Income_Category VARCHAR(20),
Card_Category VARCHAR(20),
Months_on_book TINYINT,
Total_Relationship_Count TINYINT
);
GO

Create table dbo.Card_Activity(
Activity_ID INT IDENTITY(1,1) Primary key,
CLIENTNUM BIGINT NOT NULL Foreign key References dbo.Customers(CLIENTNUM),
Months_Inactive_12_mon TINYINT,
Contacts_Count_12_mon TINYINT,
Credit_Limit DECIMAL(10,3),
Total_Revolving_Bal INT,
Avg_Open_To_Buy DECIMAL(10,3),
Total_Amt_Chng_Q4_Q1 DECIMAL(6,3),
Total_Trans_Amt INT,
Total_Trans_Ct INT,
Total_Ct_Chng_Q4_Q1 DECIMAL(6,3),
Avg_Utilization_Ratio DECIMAL(6,3),
);
GO

Insert into dbo.Customers
	(CLIENTNUM, Attrition_Flag, Customer_Age, Gender, Dependent_count,
     Education_Level, Marital_Status, Income_Category, Card_Category, Months_on_book,Total_Relationship_Count)
	 Select
	 CLIENTNUM, Attrition_Flag, Customer_Age, Gender, Dependent_count,
     Education_Level, Marital_Status, Income_Category, Card_Category, Months_on_book,Total_Relationship_Count
	 From dbo.BankChurners_Staging;

Insert into dbo.Card_Activity
	(CLIENTNUM, Months_Inactive_12_mon, Contacts_Count_12_mon,
     Credit_Limit, Total_Revolving_Bal, Avg_Open_To_Buy, Total_Amt_Chng_Q4_Q1,
     Total_Trans_Amt, Total_Trans_Ct, Total_Ct_Chng_Q4_Q1, Avg_Utilization_Ratio)
	 SELECT
	 CLIENTNUM, Months_Inactive_12_mon, Contacts_Count_12_mon,
     Credit_Limit, Total_Revolving_Bal, Avg_Open_To_Buy, Total_Amt_Chng_Q4_Q1,
     Total_Trans_Amt, Total_Trans_Ct, Total_Ct_Chng_Q4_Q1, Avg_Utilization_Ratio
	 From dbo.BankChurners_Staging


Select count(*) as tong_card from dbo.Card_Activity
Select count(*) as tong_custom from dbo.Customers