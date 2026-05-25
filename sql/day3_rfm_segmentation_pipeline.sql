-- Silver_Retail_Transactions
-- OrderID, CustomerID, OrderDate, TotalAmount
-- CurrentDate = 2024-12-31
DECLARE @currentdate DATE;
SET @currentdate = '2024-12-31';
CREATE VIEW Gold_RFM_Segments AS
WITH Raw_RFM AS(
    --1. Calculate Base Metrics: Recency, Frequency, Monetary
    SELECT 
        CustomerID,
        --Recency = Days from last purchase date = current_date - orderdate
        DATEDIFF(day, MAX(OrderDate), @currentdate) AS Recency,
        --Frequency = Total order per customer
        COUNT(OrderID) AS Frequency,
        --Monetary = Total spend per customer
        SUM(TotalAmount) AS Monetary,    
    FROM Silver_Retail_Transactions
    WHERE OrderDate <= @currentdate
    GROUP BY CustomerID
),
-- 2.Dynamic scoring NTILE(4)
Dynamic_Scoring AS 
(SELECT 
    CustomerID,
    Frequency,
    Recency,
    Monetary,
    --Dynamic NTILE for R F M independently
    NTILE(4) OVER (PARTITION BY Recency ORDER BY Recency DESC) AS R_score,
    NTILE(4) OVER (PARTITION BY Frequency ORDER BY Frequency ASC) AS F_score,
    NTILE(4) OVER (PARTITION BY Monetary ORDER BY Monetary ASC) AS M_score
FROM Raw_RFM),
-- Concat into RFM score
Segment_Mapping AS(
SELECT 
    CustomerID,
    Recency,
    Frequency,
    Monetary,
    R_score,
    F_score,
    M_score,
    CONCAT(CAST(R_score AS VARCHAR), CAST(F_score AS VARCHAR), CAST(M_score AS VARCHAR)) AS RFM_Score
FROM Dynamic_Scoring
)

SELECT
    CustomerID,
    Recency,
    Frequency,
    Monetary,
    R_score,
    F_score,
    M_score,
    RFM_Score,
    CASE 
        WHEN RFM_Score = '444' THEN 'VIP Customers'
        WHEN R_score = 1 AND (F_score = 4 OR M_score = 4) THEN 'At Risk Big Spenders'
        WHEN RFM_Score = '111' THEN 'Lost Cheap Customers'
        ELSE 'Regular Customers'
    END AS customer_segment
FROM Segment_Mapping;