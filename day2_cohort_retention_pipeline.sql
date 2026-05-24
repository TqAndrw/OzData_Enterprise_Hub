-- Table: Raw_Retail_Transactions
-- Cols: OrderID, CustomerID, OrderDate (Timestamp), và TotalAmount
CREATE OR REPLACE VIEW Silver_Cohort_Retention AS
WITH Cohort_Base AS(
    SELECT 
        OrderID, 
        CustomerID, 
        --1. First_Purchase_Month: YYYY-MM-01 per CustomerID
        DATE_TRUNC('month', MIN(OrderDate) OVER (PARTITION BY CustomerID)) AS First_Purchase_Month,
        --2. Transaction_Month: YYYY-MM-01 per OrderID
        DATE_TRUNC('month', OrderDate) AS Transaction_Month
    FROM Raw_Retail_Transactions
),
Cohort_Metrics AS (
    SELECT 
        First_Purchase_Month,
        Transaction_Month,
        CustomerID,
        -- 3.Month_Index = tran - first
        DATEDIFF(month, First_Purchase_Month, Transaction_Month) AS Month_Index
    FROM Cohort_Base
)    
    
SELECT 
        First_Purchase_Month,
        Month_Index,
        --4 Group by First_Purchase_Month and Month_Index => COUNT(CustomerID) = Retained_Customers
        COUNT (DISTINCT CustomerID) AS Retained_Customers 
    FROM Cohort_Metrics
    GROUP BY First_Purchase_Month, Month_Index;