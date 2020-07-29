USE booksales;

SELECT * FROM newsletter;
SELECT * FROM web;
SELECT * FROM store;

-- Step 2
SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Online, COUNT(PurchaseAmount) AS Visits_Online
FROM web
GROUP BY UserID;

SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Store, COUNT(PurchaseAmount) AS Visits_Store
FROM store
GROUP BY UserID;


-- Step 3
SELECT 	web.UserID, 
		COALESCE(Purchases_Online, 0) AS Purchases_Online,
        COALESCE(Visits_Online, 0) AS Visits_Online,
        COALESCE(Purchases_Store, 0) AS Purchases_Store,
        COALESCE(Visits_Store, 0) AS Visits_Store
FROM
(
	SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Online, COUNT(PurchaseAmount) AS Visits_Online
	FROM web
	GROUP BY UserID
) AS web
LEFT JOIN 
	(
		SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Store, COUNT(PurchaseAmount) AS Visits_Store
		FROM store
		GROUP BY UserID
	) AS store
    ON web.UserID = store.UserID
;


SELECT 	store.UserID AS UserID, 
		COALESCE(Purchases_Online, 0) AS Purchases_Online,
        COALESCE(Visits_Online, 0) AS Visits_Online,
        COALESCE(Purchases_Store, 0) AS Purchases_Store,
        COALESCE(Visits_Store, 0) AS Visits_Store
FROM
(
	SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Online, COUNT(PurchaseAmount) AS Visits_Online
	FROM web
	GROUP BY UserID
) AS web
RIGHT JOIN 
	(
		SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Store, COUNT(PurchaseAmount) AS Visits_Store
		FROM store
		GROUP BY UserID
	) AS store
    ON web.UserID = store.UserID
;



SELECT 	web.UserID AS UserID, 
		COALESCE(Purchases_Online, 0) AS Purchases_Online,
        COALESCE(Visits_Online, 0) AS Visits_Online,
        COALESCE(Purchases_Store, 0) AS Purchases_Store,
        COALESCE(Visits_Store, 0) AS Visits_Store
FROM
(
	SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Online, COUNT(PurchaseAmount) AS Visits_Online
	FROM web
	GROUP BY UserID
) AS web
LEFT JOIN 
	(
		SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Store, COUNT(PurchaseAmount) AS Visits_Store
		FROM store
		GROUP BY UserID
	) AS store
    ON web.UserID = store.UserID
UNION
SELECT 	store.UserID AS UserID, 
		COALESCE(Purchases_Online, 0) AS Purchases_Online,
        COALESCE(Visits_Online, 0) AS Visits_Online,
        COALESCE(Purchases_Store, 0) AS Purchases_Store,
        COALESCE(Visits_Store, 0) AS Visits_Store
FROM
(
	SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Online, COUNT(PurchaseAmount) AS Visits_Online
	FROM web
	GROUP BY UserID
) AS web
RIGHT JOIN 
	(
		SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Store, COUNT(PurchaseAmount) AS Visits_Store
		FROM store
		GROUP BY UserID
	) AS store
    ON web.UserID = store.UserID
ORDER BY UserID;

-- Step 4
DROP TABLE IF EXISTS salesdw_wide;

CREATE TABLE salesdw_wide AS
(SELECT web.UserID, 
		COALESCE(Purchases_Online, 0) AS Purchases_Online,
        COALESCE(Visits_Online, 0) AS Visits_Online,
        COALESCE(Purchases_Store, 0) AS Purchases_Store,
        COALESCE(Visits_Store, 0) AS Visits_Store
FROM
(
	SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Online, COUNT(PurchaseAmount) AS Visits_Online
	FROM web
	GROUP BY UserID
) AS web
LEFT JOIN 
	(
		SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Store, COUNT(PurchaseAmount) AS Visits_Store
		FROM store
		GROUP BY UserID
	) AS store
    ON web.UserID = store.UserID
UNION
SELECT 	store.UserID AS UserID, 
		COALESCE(Purchases_Online, 0) AS Purchases_Online,
        COALESCE(Visits_Online, 0) AS Visits_Online,
        COALESCE(Purchases_Store, 0) AS Purchases_Store,
        COALESCE(Visits_Store, 0) AS Visits_Store
FROM
(
	SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Online, COUNT(PurchaseAmount) AS Visits_Online
	FROM web
	GROUP BY UserID
) AS web
RIGHT JOIN 
	(
		SELECT UserID, ROUND(SUM(PurchaseAmount),2) AS Purchases_Store, COUNT(PurchaseAmount) AS Visits_Store
		FROM store
		GROUP BY UserID
	) AS store
    ON web.UserID = store.UserID
ORDER BY UserID);

SELECT * FROM salesdw_wide;

-- add newsletter
SELECT *, CASE
			WHEN Newsletter.UserID IS NULL THEN 0
            ELSE 1
		END AS Newsletter
FROM salesdw_wide dw
	LEFT JOIN Newsletter ON dw.UserID = Newsletter.UserID
;

ALTER TABLE salesdw_wide
ADD COLUMN Newsletter	INT;

UPDATE salesdw_wide
	LEFT JOIN Newsletter ON salesdw_wide.UserID = Newsletter.UserID
SET Newsletter = 	CASE
						WHEN Newsletter.UserID IS NULL THEN 0
						ELSE 1
					END 						
;

SELECT * FROM salesdw_wide;

-- 
SELECT 	Newsletter,
		SUM(Purchases_Online) AS Online_Total, SUM(Visits_Online) AS Online_Visits, SUM(Purchases_Online)/SUM(Visits_Online) AS Online_Avg,
		SUM(Purchases_Store) AS Store_Total, SUM(Visits_Store) AS Store_Visits, SUM(Purchases_Store)/SUM(Visits_Store) AS Store_Avg
FROM salesdw_wide
GROUP BY Newsletter WITH ROLLUP;


SELECT Visits_Online, COUNT(*) AS Freq
FROM salesdw_wide
GROUP BY Visits_Online WITH ROLLUP;

SELECT Visits_Online, Visits_Store, COUNT(*) AS Freq
FROM salesdw_wide
GROUP BY Visits_Online, Visits_Store WITH ROLLUP;




-- alternate method
SELECT * FROM newsletter;
SELECT * FROM web;
SELECT * FROM store;

SELECT UserID, PurchaseAmount AS Purchase_Online, 0 AS Purchase_Store
FROM web
UNION
SELECT UserID, 0 AS Purchase_Online, PurchaseAmount AS Purchase_Store
FROM store
ORDER BY UserID, Purchase_Online DESC, Purchase_Store DESC;

SELECT 	UserID,
		ROUND(SUM(Purchase_Online),2) AS Purchases_Online, 
		SUM(CASE WHEN Purchase_Online > 0 THEN 1 ELSE 0 END) AS Visits_Online,
		ROUND(SUM(Purchase_Store),2) AS Purchases_Store, 
        SUM(CASE WHEN Purchase_Store > 0 THEN 1 ELSE 0 END) AS Visits_Store
FROM
(
	SELECT UserID, PurchaseAmount AS Purchase_Online, 0 AS Purchase_Store
	FROM web
	UNION
	SELECT UserID, 0 AS Purchase_Online, PurchaseAmount AS Purchase_Store
	FROM store
) AS u
GROUP BY UserID
ORDER BY UserID;

SELECT summary.UserID, Purchases_Online, Visits_Online, Purchases_Store, Visits_Store,
		CASE
			WHEN Newsletter.UserID IS NULL THEN 0
            ELSE 1
		END AS Newsletter
FROM
(
	SELECT UserID, ROUND(SUM(Purchase_Online),2) AS Purchases_Online, SUM(CASE WHEN Purchase_Online > 0 THEN 1 ELSE 0 END) AS Visits_Online,
			   ROUND(SUM(Purchase_Store),2) AS Purchases_Store, SUM(CASE WHEN Purchase_Store > 0 THEN 1 ELSE 0 END) AS Visits_Store
	FROM
	(
		SELECT UserID, PurchaseAmount AS Purchase_Online, 0 AS Purchase_Store
		FROM web
		UNION
		SELECT UserID, 0 AS Purchase_Online, PurchaseAmount AS Purchase_Store
		FROM store
	) AS u
	GROUP BY UserID
) AS summary
LEFT JOIN Newsletter ON summary.UserID = Newsletter.UserID
ORDER BY summary.UserID;






