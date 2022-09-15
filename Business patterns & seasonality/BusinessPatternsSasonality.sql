/*
2012 was a great year for us. As we continue to grow, we should take a look at 2012’s monthly and weekly volume patterns, to see if we can find any seasonal trends we 
should plan for in 2013. If you can pull session volume and order volume, that would be excellent.
*/

SELECT DATE(ws.created_at) AS week_start_date, 
       COUNT(DISTINCT ws.website_session_id) AS sessions, 
       COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions AS ws
LEFT OUTER JOIN orders AS o ON ws.website_session_id = o.website_session_id
WHERE YEAR(ws.created_at) = 2012 
GROUP BY WEEK(ws.created_at);


SELECT YEAR(ws.created_at) AS yr,
	   MONTH(ws.created_at) AS mo,
       COUNT(DISTINCT ws.website_session_id) AS sessions, 
       COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions AS ws
LEFT OUTER JOIN orders AS o ON ws.website_session_id = o.website_session_id
WHERE YEAR(ws.created_at) = 2012 
GROUP BY 1, 2;



/*
We’re considering adding live chat support to the website to improve our customer experience. Could you analyze the average website session volume, by hour of day and 
by day week, so that we can staff appropriately? Let’s avoid the holiday time period and use a date range of Sep 15 - Nov 15, 2012
*/

SELECT hr,
	   ROUND(AVG(CASE WHEN wk_day = 0 THEN website_sessions ELSE NULL END), 2) AS mon,
       ROUND(AVG(CASE WHEN wk_day = 1 THEN website_sessions ELSE NULL END), 2) AS tue,
       ROUND(AVG(CASE WHEN wk_day = 2 THEN website_sessions ELSE NULL END), 2) AS wes,
       ROUND(AVG(CASE WHEN wk_day = 3 THEN website_sessions ELSE NULL END), 2) AS thu,
       ROUND(AVG(CASE WHEN wk_day = 4 THEN website_sessions ELSE NULL END), 2) AS fri,
       ROUND(AVG(CASE WHEN wk_day = 5 THEN website_sessions ELSE NULL END), 2) AS sat,
       ROUND(AVG(CASE WHEN wk_day = 6 THEN website_sessions ELSE NULL END), 2) AS sun
FROM (
SELECT DATE(created_at) AS created_date, 
       WEEKDAY(created_at) AS wk_day,
       HOUR(created_at) AS hr,
       COUNT(DISTINCT website_session_id) AS website_sessions
FROM website_sessions
WHERE created_at BETWEEN "2012-09-15" AND "2012-11-15"
GROUP BY 1, 2, 3
) AS day_hr_session
GROUP BY 1



