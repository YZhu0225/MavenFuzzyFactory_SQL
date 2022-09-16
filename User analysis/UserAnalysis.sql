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



