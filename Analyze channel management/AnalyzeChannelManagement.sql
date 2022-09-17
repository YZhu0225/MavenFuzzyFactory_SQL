/*
With gsearch doing well and the site performing better, we launched a second paid search channel, bsearch, around August 22.
Can you pull weekly trended session volume since then and compare to gsearch nonbrand so I can get a sense for how important this will be for the business?
*/

SELECT DATE(created_at),
       COUNT(DISTINCT CASE WHEN utm_source = "gsearch" THEN website_session_id END) AS gsearch_sessions,
       COUNT(DISTINCT CASE WHEN utm_source = "bsearch" THEN website_session_id END) AS bsearch_sessions
FROM website_sessions
WHERE created_at BETWEEN "2012-08-22" AND "2012-11-29" AND utm_campaign = "nonbrand"
GROUP BY WEEK(created_at);



/*
I’d like to learn more about the bsearch nonbrand campaign. Could you please pull the percentage of traffic coming on Mobile, and compare that to gsearch? Feel free 
to dig around and share anything else you find interesting. Aggregate data since August 22nd is great, no need to show trending at this point.
*/

SELECT utm_source,
       COUNT(website_session_id) AS session,
       COUNT(CASE WHEN device_type = "mobile" THEN website_session_id END) AS mobile_sessions,
       COUNT(CASE WHEN device_type = "mobile" THEN website_session_id END) / COUNT(website_session_id) AS pct_sessions
FROM website_sessions
WHERE created_at BETWEEN "2012-08-22" AND "2012-11-30" AND utm_campaign = "nonbrand"
GROUP BY 1;


/*
I’m wondering if bsearch nonbrand should have the same bids as gsearch. Could you pull nonbrand conversion rates from session to order for gsearch and bsearch, and slice the 
data by device type? Please analyze data from August 22 to September 18; we ran a special pre-holiday campaign for gsearch starting on September 19th, so the data after that isn’t fair game.
*/

SELECT ws.device_type, ws.utm_source,
       COUNT(DISTINCT ws.website_session_id) AS sessions,
       COUNT(DISTINCT o.order_id) AS orders,
       COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS conv_rate 
FROM website_sessions AS ws
LEFT OUTER JOIN orders AS o
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at BETWEEN "2012-08-22" AND "2012-09-18" AND utm_campaign = "nonbrand" 
GROUP BY 1,2
GROUP BY 1,2;



/*
Based on your last analysis, we bid down bsearch nonbrand on December 2nd.
Can you pull weekly session volume for gsearch and bsearch nonbrand, broken down by device, since November 4th?
If you can include a comparison metric to show bsearch as a percent of gsearch for each device, that would be great too.
*/

SELECT DATE(created_at) AS week_start_date,
       COUNT(DISTINCT case when utm_source = "gsearch" AND device_type = "desktop" then website_session_id end) AS g_dtop_sessions, 
       COUNT(DISTINCT case when utm_source = "bsearch" AND device_type = "desktop" then website_session_id end) AS b_dtop_sessions, 
       COUNT(DISTINCT case when utm_source = "bsearch" AND device_type = "desktop" then website_session_id end) 
          / COUNT(DISTINCT case when utm_source = "gsearch" AND device_type = "desktop" then website_session_id end) AS b_pct_of_g_dtop, 
       COUNT(DISTINCT case when utm_source = "gsearch" AND device_type = "mobile" then website_session_id end) AS g_mob_sessions, 
       COUNT(DISTINCT case when utm_source = "bsearch" AND device_type = "mobile" then website_session_id end) AS b_mob_sessions, 
       COUNT(DISTINCT case when utm_source = "bsearch" AND device_type = "mobile" then website_session_id end)
          / COUNT(DISTINCT case when utm_source = "gsearch" AND device_type = "mobile" then website_session_id end) AS b_pct_of_g_mob fram website_sessions
WHERE created_at BETWEEN "2012-11-04" AND "2012-12-22" AND utm_campaign = "nonbrand"
GROUP BY WEEK(created_at)


/*
A potential investor is asking if we’re building any momentum with our brand or if we’ll need to keep relying on paid traffic.
Could you pull organic search, direct type in, and paid brand search sessions by month, and show those sessions as a % of paid search nonbrand?
*/

SELECT YEAR(created_at) AS yr,
       MONTH(created_at) AS mo,
       COUNT (DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand,
       COUNT (DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END) AS brand,
       COUNT (DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END)
          / COUNT (DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS brand_pct_of_nonbrand, 
       COUNT (DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END) AS direct,      
       COUNT (DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END)
          / COUNT (DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS direct_pct_of_nonbrand, COUNT (DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END) AS organic,
       COUNT (DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END)
          / COUNT (DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand
FROM(
      SELECT website_session_id,
      created_at, 
      CASE WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search)
           WHEN utm_campaign = 'nonbrand' THEN paid_nonbrand
           WHEN utm_campaign = 'brand' THEN paid_brand
           WHEN utm_source IS NULL AND http_referer IS NULL THEN direct_type_in
           END AS channel_group
      FROM website_sessions
      WHERE created_at < '2012-12-23' ) AS sessions_w_channel_group
GROUP BY YEAR(created_at), MONTH(created_at)





