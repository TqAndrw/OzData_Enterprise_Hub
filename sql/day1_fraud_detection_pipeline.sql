CREATE OR REPLACE VIEW Silver_Fraud_Flags AS
WITH Rolling_Metrics AS (
    SELECT
        TransactionID,
        CustomerID,
        TransactionDate,
        MerchantCategory,
        Amount,
        -- 1. Rolling 7 day window sum(amount) and count(transactionID)
        SUM(Amount) OVER (PARTITION BY CustomerID ORDER BY TransactionDate RANGE BETWEEN INTERVAL 7 DAY PRECEDING AND CURRENT ROW) AS Total_Amount_7D,
        COUNT(TransactionID) OVER (PARTITION BY CustomerID ORDER BY TransactionDate RANGE BETWEEN INTERVAL 7 DAY PRECEDING AND CURRENT ROW) AS Txn_Count_7D,

        -- 2. Rolling 30 day window avg(amount) 30 days
        AVG(Amount) OVER (PARTITION BY CustomerID ORDER BY TransactionDate RANGE BETWEEN INTERVAL 30 DAY PRECEDING AND CURRENT ROW) AS Avg_Amount_30D
    
    FROM Raw_Credit_Transactions
)
-- 3. Risk_Flag based on metrics calculated
SELECT
    TransactionID,
    CustomerID,
    TransactionDate,
    MerchantCategory,
    Amount,
    Total_Amount_7D,
    Txn_Count_7D,
    Avg_Amount_30D,
    CASE 
        WHEN Amount > (3 * Avg_Amount_30D) THEN 1
        WHEN Txn_Count_7D > 20 THEN 1
        ELSE 0
    END AS Risk_Flag
FROM Rolling_Metrics;