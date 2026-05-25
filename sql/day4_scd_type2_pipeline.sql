--Raw_Customer_Updates
--CustomerID, CreditScore, State, và UpdateDate

CREATE VIEW Gold_Dim_Customer_SCD2 AS
WITH Customer_Lifespan AS (
    SELECT
        CustomerId,
        CreditScore,
        State,
        UpdateDate AS Valid_From,
        --1. Lifespan: Window Function LEAD() to get value of UpdateDate
        -- next update of the same CustomerID => Valid_to
        COALESCE(LEAD(UpdateDate) OVER (PARTITION BY CustomerID ORDER BY UpdateDate ASC), CAST('9999-12-31' AS DATE)) AS Valid_To
    FROM  Raw_Customer_Updates
)
SELECT
    CustomerID,
    CreditScore,
    State,
    Valid_From,
    Valid_To,
    CASE 
        WHEN Valid_To = CAST('9999-12-31' AS DATE) THEN 1
        ELSE 0
    END AS Is_Current
FROM Customer_Lifespan;
