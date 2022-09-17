/* 
We've been live for almost a month now and we’re starting to generate sales. Can you help me understand where the bulk of our website sessions are coming from, 
through yesterday? I’d like to see a breakdown by UTM source, campaign and referring domain if possible. Thanks!
*/

SELECT utm_source, 
       utm_campaign, 
       http_referer,
       COUNT(website_session_id) AS sessions 
FROM website_sessions
WHERE created_at < "2012-02-12"
GROUP BY 1, 2, 3
ORDER BY 4 DESC;


/*
We've been live for almost a month now and we’re starting to generate sales. Can you help me understand where the bulk of our website sessions are coming 
from, through yesterday? I’d like to see a breakdown by UTM source, campaign and referring domain if possible. Thanks!
*/

SELECT COUNT(ws.website_session_id) AS sessions,
       COUNT(o.order_id) AS orders,
       COUNT(o.order_id) / COUNT(ws.website_session_id) AS session_to_order_conv_rate
FROM website_sessions AS ws
LEFT OUTER JOIN orders AS o
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < "2012-04-14" AND ws.utm_source = "gsearch" AND ws.utm_campaign = "nonbrand";


/*
Based on your conversion rate analysis, we bid down gsearch nonbrand on 2012-04-15. Can you pull gsearch nonbrand trended session volume, by week, to see if the bid 
changes have caused volume to drop at all?
*/

SELECT DATE(created_at) AS week_start_date,
       COUNT(0) AS session
FROM website_sessions
WHERE created_at < "2012-05-12" AND utm_source = "gsearch" AND utm_campaign = "nonbrand"
GROUP BY WEEK(created_at);


/*
I was trying to use our site on my mobile device the other day, and the experience was not great. Could you pull conversion rates from session to order, by device type?
If desktop performance is better than on mobile we may be able to bid up for desktop specifically to get more volume?
*/

SELECT ws.device_type,
       COUNT(DISTINCT ws.website_session_id) AS sessions,
       COUNT(DISTINCT o.order_id) AS orders,
       COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS conv_rt
FROM website_sessions AS ws
LEFT OUTER JOIN orders AS o
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < "2012-05-11" AND utm_source = "gsearch" AND utm_campaign = "nonbrand";



/*
After your device-level analysis of conversion rates, we realized desktop was doing well, so we bid our gsearch nonbrand desktop campaigns up on 2012-05-19. 
Could you pull weekly trends for both desktop and mobile so we can see the impact on volume? You can use 2012-04-15 until the bid change as a baseline
*/

SELECT DATE(created_at),
       COUNT(DISTINCT CASE WHEN device_type = "desktop" THEN website_session_id END) AS dtop_sessions, 
       COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_session_id END) AS mob_sessions
FROM website_sessions
WHERE created_at BETWEEN "2012-04-15" AND "2012-06-09" AND utm_source = "gsearch" AND utm_campaign = "nonbrand"
GROUP BY WEEK(created_at);



