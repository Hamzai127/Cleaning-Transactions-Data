CREATE DATABASE Cleaning_Transactions_Data;
USE Cleaning_Transactions_Data;

SELECT *
FROM transactions_dirty;

-- Remove duplicates

SELECT *
FROM (
	SELECT *,
    ROW_NUMBER()OVER(PARTITION BY Transaction_ID ORDER BY Date) as RN
    FROM transactions_dirty
    ) t
WHERE RN = 1;

-- Fix negative amounts (set to ABS)

SELECT Transaction_ID, ABS(Amount) as Clean_Amount
FROM transactions_dirty;

-- Standardize transaction type labels

SELECT Transaction_ID, ABS(Amount),
	CASE
		WHEN LOWER(TYPE) LIKE '%depo%' THEN 'Deposits'
        WHEN UPPER(TYPE) LIKE '%with%' THEN 'Withdrawal'
        ELSE 'Others'
	END as Clean_Labels
FROM transactions_dirty;

-- Unify status values

SELECT Transaction_ID, ABS(Amount),
	CASE 
		WHEN LOWER(TYPE) LIKE '%depo%' THEN 'Deposits'
        WHEN UPPER(TYPE) LIKE '%with%' THEN 'Withdrawal'
        ELSE 'Others'
	END as Clean_Labels,
	CASE
		WHEN Status IN ('Success','Completed','Done') THEN 'Completed'
        WHEN Status IN ('Fail','Error','Declined') THEN 'Failed'
        ELSE 'Pending'
	END as Updated_Status
FROM transactions_dirty;

-- Check invalid amounts

SELECT *
FROM transactions_dirty
WHERE Amount IS NULL OR Amount = 0;

-- Find customers with multiple transactions on the same date

SELECT Customer_ID, Date, COUNT(*) as Trxn_Count
FROM transactions_dirty
GROUP BY Customer_ID, Date
ORDER BY COUNT(*) >1;

-- Use UNION to merge failed + pending txns

SELECT *, ABS(Amount),
		CASE 
		WHEN LOWER(TYPE) LIKE '%depo%' THEN 'Deposits'
        WHEN UPPER(TYPE) LIKE '%with%' THEN 'Withdrawal'
        ELSE 'Others'
	END as Clean_Labels
FROM transactions_dirty
WHERE Status = 'Fail'
UNION 
SELECT *, ABS(Amount),
		CASE 
		WHEN LOWER(TYPE) LIKE '%depo%' THEN 'Deposits'
        WHEN UPPER(TYPE) LIKE '%with%' THEN 'Withdrawal'
        ELSE 'Others'
	END as Clean_Labels
FROM transactions_dirty
WHERE Status = 'Pending';

-- Final cleaned table

SELECT DISTINCT 
	Transaction_ID,
    Customer_ID,
    ABS(Amount) as Amount,
		CASE
			WHEN LOWER(TYPE) LIKE '%depo%' THEN 'Deposits'
			WHEN UPPER(TYPE) LIKE '%with%' THEN 'Withdrawal'
        ELSE 'Others'
	END as Labels,
		CASE
			WHEN LOWER(TYPE) LIKE '%depo%' THEN 'Deposits'
			WHEN UPPER(TYPE) LIKE '%with%' THEN 'Withdrawal'
        ELSE 'Others'
	END as Labels,
    Date
FROM transactions_dirty;