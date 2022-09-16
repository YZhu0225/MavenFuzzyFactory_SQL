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










/*
Let’s do a bit more digging into our repeat customers. Can you help me understand the channels they come back through? Curious if it’s all direct type-in, or if 
we’re paying for these customers with paid search ads multiple times. Comparing new vs. repeat sessions by channel would be really valuable, if you’re able to pull it! 
2014 to date is great.
*/










/*
Sounds like you and Tom have learned a lot about our repeat customers. Can I trouble you for one more thing? I’d love to do a comparison of conversion rates and 
revenue per session for repeat sessions vs new sessions. Let’s continue using data from 2014, year to date.
*/











/*

*/






