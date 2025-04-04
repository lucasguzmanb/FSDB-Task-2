-- Query A
SELECT b.TITLE, b.AUTHOR
FROM books b
JOIN editions e ON b.TITLE = e.TITLE AND b.AUTHOR = e.AUTHOR
JOIN copies c ON e.ISBN = c.ISBN
LEFT JOIN loans l ON c.SIGNATURE = l.SIGNATURE
GROUP BY b.TITLE, b.AUTHOR
HAVING COUNT(DISTINCT e.LANGUAGE) >= 3
   AND COUNT(l.SIGNATURE) = 0;


-- Query B
SELECT d.fullname,
       FLOOR(MONTHS_BETWEEN(SYSDATE, d.birthdate) / 12) AS age,
       FLOOR(MONTHS_BETWEEN(SYSDATE, d.cont_start) / 12) AS seniority,
       COUNT(DISTINCT EXTRACT(YEAR FROM a.taskdate)) AS active_years,
       COUNT(DISTINCT s.town) / COUNT(DISTINCT EXTRACT(YEAR FROM a.taskdate)) AS stops_per_active_year,
       COUNT(DISTINCT l.signature) / COUNT(DISTINCT EXTRACT(YEAR FROM a.taskdate)) AS loans_per_active_year,
       NVL(
           TRUNC(100 * COUNT(CASE WHEN l.return IS NULL AND l.signature IS NOT NULL THEN 1 END)
           / NULLIF(COUNT(l.signature), 0), 3), 0
       ) || '%' AS percent_unreturned  --We truncate to 3 decimals and add '%'
FROM drivers d
JOIN assign_drv a ON d.passport = a.passport
JOIN stops s ON a.route_id = s.route_id
JOIN services sv ON a.passport = sv.passport
LEFT JOIN loans l ON l.town = sv.town AND sv.taskdate = l.stopdate AND sv.passport = a.passport
GROUP BY d.fullname, d.birthdate, d.cont_start;