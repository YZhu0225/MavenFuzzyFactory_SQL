/*
Could you help me get my head around the site by pulling the most-viewed website pages, ranked by session volume?
*/

SELECT pageview_url,
       COUNT(DISTINCT website_session_id) AS sessions
FROM website_pageviews
WHERE created_at < "2012-06-09"
GROUP BY pageview_url
ORDER BY sessions DESC;



/*
Would you be able to pull a list of the top entry pages? I want to confirm where our users are hitting the site. 
If you could pull all entry pages and rank them on entry volume, that would be great.
*/

CREATE TEMPORARY TABLE first_pageviews
SELECT website_session_id,
       MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
WHERE created_at < "2012-06-12"
GROUP BY website_session_id;

SELECT wp.pageview_url AS landing_page,
       COUNT(first_pageviews.website_session_id) AS sessions_hitting_this_landing_page
FROM first_pageviews
LEFT OUTER JOIN website_pageviews AS wp
ON first_pageviews.min_pageview_id = wp.website_pageview_id
GROUP BY wp.pageview_url;


/* 
The other day you showed us that all of our traffic is landing on the homepage right now. We should check how that landing page is performing. 
Can you pull bounce rates for traffic landing on the homepage? I would like to see three numbers…Sessions, Bounced Sessions, and % of Sessions which Bounced 
(aka “Bounce Rate”).
*/

CREATE TEMPORARY TABLE first_pageview
SELECT website_session_id, MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE created_at < "2012-06-14"
GROUP BY website_session_id;

CREATE TEMPORARY TABLE landing_page
SELECT wp.pageview_url, 
       fp.website_session_id 
FROM first_pageview AS fp
JOIN website_pageview AS wp
ON fp.first_pageview_id = wp.website_pageview_id
WHERE wp.pageview_url = "/home";

CREATE TEMPORARY TABLE bounce_session
SELECT lp.pageview_url, 
       lp.website_session_id, 
       COUNT(wp.website_session_id)
FROM landing_page AS lp
JOIN website_pageviews AS wp
ON lp.website_session_id = wp.website_session_id
GROUP BY 1, 2
HAVING COUNT(wp.website_session_id) = 1;

SELECT lp.pageview_url,
       COUNT(lp.website_session_id) AS sessions,
       COUNT(bs.website_session_id) AS bounce_sessions,
       COUNT(bs.website_session_id) / COUNT(lp.website_session_id) AS bounce_rate
FROM landing_page AS lp
LEFT OUTER JOIN bounce_session AS bs
ON lp.website_session_id = bs.website_session_id
GROUP BY 1;



/*
Based on your bounce rate analysis, we ran a new custom landing page (/lander-1) in a 50/50 test against the homepage (/home) for our gsearch nonbrand traffic. 
Can you pull bounce rates for the two groups so we can evaluate the new page? Make sure to just look at the time period where /lander-1 was getting traffic, so that it is a fair 
comparison
*/

CREATE TEMPORARY TABLE first_pageview
SELECT wp.website_session_id, 
       MIN(wp.website_pageview_id) AS first_pageview_id
FROM website_pageview AS wp
JOIN website_sessions AS ws
ON wp.website_session_id = ws.website_session_id
WHERE ws.created_at <BETWEEN "2012-06-19" AND "2012-07-28"
      AND ws.utm_source = "gsearch"
      AND utm_campaign = "nonbrand"
GROUP BY wp.website_session_id;

CREATE TEMPORARY TABLE landing_page
SELECT wp.pageview_url, 
       fp.website_session_id 
FROM first_pageview AS fp
JOIN website_pageview AS wp
ON fp.first_pageview_id = wp.website_pageview_id
WHERE wp.pageview_url = "/home" OR wp.pageview_url = "/lander-1";

CREATE TEMPORARY TABLE bounce_session
SELECT lp.pageview_url, 
       lp.website_session_id, 
       COUNT(wp.website_session_id)
FROM landing_page AS lp
JOIN website_pageviews AS wp
ON lp.website_session_id = wp.website_session_id
GROUP BY 1, 2
HAVING COUNT(wp.website_session_id) = 1;

SELECT lp.pageview_url,
       COUNT(lp.website_session_id) AS sessions,
       COUNT(bs.website_session_id) AS bounce_sessions,
       COUNT(bs.website_session_id) / COUNT(lp.website_session_id) AS bounce_rate
FROM landing_page AS lp
LEFT OUTER JOIN bounce_session AS bs
ON lp.website_session_id = bs.website_session_id
GROUP BY 1;



/*
Could you pull the volume of paid search nonbrand traffic landing on /home and /lander-1, trended weekly since June 1st? I want to confirm the traffic is all routed correctly.
Could you also pull our overall paid search bounce rate trended weekly? I want to make sure the lander change has improved the overall picture.
*/

CREATE TEMPORARY TABLE sessions_min_view_count SELECT wp.website_session_id,    
       MIN(wp.website_pageview_id) AS first_pageview_id,
       COUNT (wp.website_pageview_id) AS count_pageview
FROM website_pageviews AS wp
JOIN website_sessions AS ws ON wp.website_session_id = ws.website_session_id 
WHERE wp.created_at BETWEEN "2012-06-1" AND "2012-08-31"
  AND ws.utm_source = "gsearch"
  AND ws.utm_campaign = "nonbrand"
GROUP BY wp.website_session_id;


CREATE TEMPORARY TABLE sessions_counts_lander_and_created_at 
SELECT sessions_min_view_count.website_session_id, sessions_min_view_count.first_pageview_id,
       sessions_min_view_count.count_pageview, 
       wp.pageview_url AS landing_page,
       wp.created at As session_created_at got date
FROM sessions_min_view_count
LEFT JOIN website_pageviews AS wp
ON sessions_min_view_count.first_pageview_id = wp.website_pageview_id;


SELECT DATE (session_created_at),
       COUNT (DISTINCT CASE WHEN count_pageview = 1 THEN website_session_id END) *1/COUNT (DISTINCT website_session_id) AS bounce_rate,
       COUNT (DISTINCT CASE WHEN landing_page = "/home" THEN website_session_id END) AS home_sessions,
       COUNT (DISTINCT CASE WHEN landing_page = "/lander-1" THEN website_session_id END) AS lander_sessions
FROM sessions_counts_lander_and_created_at
GROUP BY 1;



/*
I’d like to understand where we lose our gsearch visitors between the new /lander-1 page and placing an order. Can you build us a full conversion funnel, analyzing how many 
customers make it to each step? Start with /lander-1 and build the funnel all the way to our thank you page. Please use data since August 5th.
*/




/*
We tested an updated billing page based on your funnel analysis. Can you take a look and see whether /billing-2 is doing any better than the original /billing page? 
We’re wondering what % of sessions on those pages end up placing an order. FYI – we ran this test for all traffic, not just for our search visitors.
*/









