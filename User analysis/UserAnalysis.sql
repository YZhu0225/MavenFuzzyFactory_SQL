/*
We’ve been thinking about customer value based solely on their first session conversion and revenue. But if customers have repeat sessions, they may be more valuable 
than we thought. If that’s the case, we might be able to spend a bit more to acquire them.Could you please pull data on how many of our website visitors come back for another 
session? 2014 to date is good.
*/

USE mavenfuzzyfactory;

-- Step 1: Identify the relevant new sessions
-- Step 2: Use the user_id values from Step 1 to find any repeat sessions those users had
CREATE TEMPORARY TABLE repeated_sessions
SELECT new_sessions.user_id,
	   new_sessions.website_session_id AS new_session_id,
       website_sessions.website_session_id AS repeat_session_id
FROM (
SELECT user_id, website_session_id 
FROM website_sessions 
WHERE created_at BETWEEN "2014-01-01" AND "2014-11-01"   
	  AND is_repeat_session = 0   # new sessions only
) AS new_sessions
LEFT OUTER JOIN website_sessions 
ON website_sessions.user_id = new_sessions.user_id    # same user
	AND website_sessions.is_repeat_session = 1   # was a repeat session
    AND website_sessions.website_session_id > new_sessions.website_session_id
	AND website_sessions.created_at BETWEEN "2014-01-01" AND "2014-11-01" ;

-- Step 3: Analyze the data at the user level(how many sessions did each user have?)
-- Step 4: Aggregate the user-level analysis to generate behavioral analysis
SELECT num_repeat_sessions,
	   COUNT(DISTINCT user_id) AS users
FROM (
SELECT user_id, 
       COUNT(DISTINCT new_session_id) AS new_sessions,
       COUNT(DISTINCT repeat_session_id) AS num_repeat_sessions
FROM repeated_sessions
GROUP BY 1
ORDER BY 3 DESC
) AS user_level
GROUP BY 1;


/*
Now you’ve got me curious to better understand the behavior of these repeat customers. Could you help me understand the minimum, maximum, and average time between the 
first and second session for customers who do come back? Again, analyzing 2014 to date is probably the right time period.
*/

USE mavenfuzzyfactory;

-- Step 1: Identify the relevant new sessions
-- Step 2: Use the user_id values from Step 1 to find any repeat sessions those users had
CREATE TEMPORARY TABLE repeated_sessions
SELECT new_sessions.user_id,
	   new_sessions.website_session_id AS new_session_id,
       new_sessions.created_at AS new_session_created_at,
       website_sessions.website_session_id AS repeat_session_id,
       website_sessions.created_at AS repeat_created_at
FROM (
SELECT user_id, 
	   website_session_id,
       created_at
FROM website_sessions 
WHERE created_at BETWEEN "2014-01-01" AND "2014-11-03"   
	  AND is_repeat_session = 0   # new sessions only
) AS new_sessions
LEFT OUTER JOIN website_sessions 
ON website_sessions.user_id = new_sessions.user_id    # same user
	AND website_sessions.is_repeat_session = 1   # was a repeat session
    AND website_sessions.website_session_id > new_sessions.website_session_id
	AND website_sessions.created_at BETWEEN "2014-01-01" AND "2014-11-03" ;

-- Step 3: Find the created_at times for first and second sessions
-- Step 4: Find the difference between first and second sessions at a user level
CREATE TEMPORARY TABLE user_first_to_second
SELECT user_id,
	   DATEDIFF(second_session_created_at, new_session_created_at) AS diff_first_session_second_session
FROM (
SELECT user_id, 
	   new_session_id,
       new_session_created_at,
       MIN(repeat_session_id) AS second_session_id,
       MIN(repeat_created_at) AS second_session_created_at
FROM repeated_sessions
WHERE repeat_session_id IS NOT NULL
GROUP BY 1, 2, 3
) AS first_second;

-- Step 5: Aggregate the user level data to find the average, min, max
SELECT AVG(diff_first_session_second_session) AS avg_days_first_to_second,
       MIN(diff_first_session_second_session) AS min_days_first_to_second,
       MAX(diff_first_session_second_session) AS max_days_first_to_second
FROM user_first_to_second;



/*
Let’s do a bit more digging into our repeat customers. Can you help me understand the channels they come back through? Curious if it’s all direct type-in, or if 
we’re paying for these customers with paid search ads multiple times. Comparing new vs. repeat sessions by channel would be really valuable, if you’re able to pull it! 
2014 to date is great.
*/

USE mavenfuzzyfactory;

SELECT CASE WHEN utm_source IS NULL AND http_referer IN ( "https://www.gsearch.com", "https://www.socialbook.com") THEN "organic_search" 
			WHEN utm_campaign = "brand" THEN "paid_brand"
            WHEN utm_source IS NULL AND http_referer IS NULL THEN "direct_type_in"
            WHEN utm_campaign = "nonbrand" THEN "paid_nonbrand"
            WHEN utm_source = "socialbook" THEN "paid_social"
            END AS channel_group,
		COUNT(DISTINCT CASE WHEN is_repeat_session = 0 THEN website_session_id END) AS new_sessions,
        COUNT(DISTINCT CASE WHEN is_repeat_session = 1 THEN website_session_id END) AS repeat_sessions
FROM website_sessions
WHERE created_at BETWEEN "2014-01-01" AND "2014-11-05"
GROUP BY 1
ORDER BY 3 DESC;



/*
Sounds like you and Tom have learned a lot about our repeat customers. Can I trouble you for one more thing? I’d love to do a comparison of conversion rates and 
revenue per session for repeat sessions vs new sessions. Let’s continue using data from 2014, year to date.
*/

USE mavenfuzzyfactory;

SELECT is_repeat_session, 
	   COUNT(website_sessions.website_session_id) AS sessions,
	   COUNT(order_id) / COUNT(website_sessions.website_session_id) AS conv_rate,
       SUM(price_usd) / COUNT(website_sessions.website_session_id) AS rev_per_session
FROM website_sessions
LEFT OUTER JOIN orders 
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN "2014-01-01" AND "2014-11-08"
GROUP BY 1


