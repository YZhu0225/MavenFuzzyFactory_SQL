/*
We’re about to launch a new product, and I’d like to do a deep dive on our current flagship product. Can you please pull monthly trends to date for number of sales, total revenue, and total margin generated for the business
*/

SELECT YEAR(created_at) AS yr, 
	   MONTH(created_at) AS mo, 
	   COUNT(order_id) AS number_of_sales, 
       SUM(price_usd) AS total_revenue,
       SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < "2013-01-04"
GROUP BY 1, 2;


/*
We launched our second product back on January 6th. Can you pull together some trended analysis? I’d like to see monthly order volume, overall conversion rates, revenue per session, and a breakdown of sales by 
product, all for the time period since April 1, 2012.
*/

SELECT YEAR(ws.created_at) AS yr,        # should be ws.created_at, not o.created_at
       MONTH(ws.created_at) AS mo,
       COUNT(DISTINCT o.order_id) AS orders, 
       COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS conv_rate,
       SUM(o.price_usd) / COUNT(DISTINCT ws.website_session_id) AS revenue_per_session, 
       COUNT(DISTINCT CASE WHEN o.primary_product_id = 1 THEN order_id ELSE NULL END) AS product_one_orders,
       COUNT(DISTINCT CASE WHEN o.primary_product_id = 2 THEN order_id ELSE NULL END) AS product_two_orders
FROM website_sessions AS ws
LEFT JOIN orders AS o
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at BETWEEN "2012-04-01" AND "2013-04-05"
GROUP BY 1, 2


/*
Now that we have a new product, I’m thinking about our user path and conversion funnel. Let’s look at sessions which hit the /products page and see where they went next. 
Could you please pull clickthrough rates from /products since the new product launch on January 6th 2013, by product, and compare to the 3 months leading up to launch as a baseline?
*/

-- Step 1: finding the /products pageviews we care about
CREATE TEMPORARY TABLE products_pageviews
SELECT website_session_id, 
       website_pageview_id,
       created_at,
       CASE
			WHEN created_at < "2013-01-06" THEN "A. Pre_Product_2"
            WHEN created_at > "2013-01-06" THEN "B. Post_Product_2"
		END AS time_period
FROM website_pageviews
WHERE created_at BETWEEN "2012-10-06" AND "2013-04-06"
	  AND pageview_url = "/products";      
     
     
-- Step 2: find the next pageview id that occurs AFTER the product pageview
CREATE TEMPORARY TABLE sessions_next_pageview
SELECT pp.time_period, 
	   pp.website_session_id, 
	   MIN(wp.website_pageview_id) AS min_next_pageview_id      
FROM products_pageviews AS pp
LEFT OUTER JOIN website_pageviews AS wp
ON pp.website_session_id = wp.website_session_id
   AND wp.website_pageview_id > pp.website_pageview_id    # make sure it's the next page
GROUP BY 1, 2;


-- Step 3: find the pageview_url associated with any applicable next pageview id
CREATE TEMPORARY TABLE session_next_pageview_url
SELECT snp.time_period,
	   snp.website_session_id,
       wp.pageview_url AS next_pageview_url
FROM sessions_next_pageview AS snp
LEFT OUTER JOIN website_pageviews AS wp
ON snp.min_next_pageview_id = wp.website_pageview_id;


-- Step 4: summarize the data and analyze the pre vs post periods
SELECT time_period,
	   COUNT(DISTINCT website_session_id) AS sessions,
      	   COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg,
	   COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS pct_w_next_pg,
	   COUNT(DISTINCT CASE WHEN next_pageview_url = "/the-original-mr-fuzzy" THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
	   COUNT(DISTINCT CASE WHEN next_pageview_url = "/the-original-mr-fuzzy" THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS pct_to_mrfuzzy,
	   COUNT(DISTINCT CASE WHEN next_pageview_url = "/the-forever-love-bear" THEN website_session_id ELSE NULL END) AS to_lovebear,
	   COUNT(DISTINCT CASE WHEN next_pageview_url = "/the-forever-love-bear" THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS pct_to_lovebear
FROM session_next_pageview_url
GROUP BY time_period


/*
I’d like to look at our two products since January 6th and analyze the conversion funnels from each product page to conversion. It would be great if you could produce a comparison between 
the two conversion funnels, for all website traffic.
*/


-- Step 1: select all pageviews for relevant sessions
CREATE TEMPORARY TABLE sessions_seeing_product
SELECT website_session_id, 
       website_pageview_id,
       pageview_url AS product_page_seen
FROM website_pageviews
WHERE created_at BETWEEN "2013-01-06" AND "2013-04-10"      # after the love_bear is launched
      AND pageview_url IN ("/the-original-mr-fuzzy", "/the-forever-love-bear");

-- Step 2: figure out which pageview urls to look for
SELECT DISTINCT wp.pageview_url
FROM sessions_seeing_product AS ssp
LEFT OUTER JOIN website_pageviews AS wp
ON wp.website_session_id = ssp.website_session_id
   AND wp.website_pageview_id > ssp.website_pageview_id;   # limit to pageviews after the customers see the product page


-- Step 3: pull all pageviews and identify the funnel steps
SELECT ssp.website_session_id,
       ssp.product_page_seen,      # original / love_bear
       CASE WHEN wp.pageview_url = "/cart" THEN 1 ELSE 0 END AS cart_page,
       CASE WHEN wp.pageview_url = "/shipping" THEN 1 ELSE 0 END AS shipping_page,
       CASE WHEN wp.pageview_url = "/billing-2" THEN 1 ELSE 0 END AS billing_page,
       CASE WHEN wp.pageview_url = "/thank-you-for-your-order" THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product AS ssp
LEFT OUTER JOIN website_pageviews AS wp
ON wp.website_session_id = ssp.website_session_id
   AND wp.website_pageview_id > ssp.website_pageview_id 
ORDER BY ssp.website_session_id, wp.created_at;


-- Step 4: create the session-level conversion funnel view
CREATE TEMPORARY TABLE session_product_level_made_it_flags
SELECT website_session_id,
	   CASE
		WHEN product_page_seen = "/the-original-mr-fuzzy" THEN "mrfuzzy"
		WHEN product_page_seen = "/the-forever-love-bear" THEN "lovebear"
	   END AS product_seen,
       MAX(cart_page) AS cart_made_it,
       MAX(shipping_page) AS shipping_made_it,
       MAX(billing_page) AS billing_made_it,
       MAX(thankyou_page) AS thankyou_made_it
FROM (
	SELECT ssp.website_session_id,
		   ssp.product_page_seen,      # original / love_bear
		   CASE WHEN wp.pageview_url = "/cart" THEN 1 ELSE 0 END AS cart_page,
		   CASE WHEN wp.pageview_url = "/shipping" THEN 1 ELSE 0 END AS shipping_page,
		   CASE WHEN wp.pageview_url = "/billing-2" THEN 1 ELSE 0 END AS billing_page,
		   CASE WHEN wp.pageview_url = "/thank-you-for-your-order" THEN 1 ELSE 0 END AS thankyou_page
	FROM sessions_seeing_product AS ssp
	LEFT OUTER JOIN website_pageviews AS wp
	ON wp.website_session_id = ssp.website_session_id
	   AND wp.website_pageview_id > ssp.website_pageview_id 
	ORDER BY ssp.website_session_id, wp.created_at
) AS pageview_level
GROUP BY website_session_id,
		 CASE
			WHEN product_page_seen = "/the-original-mr-fuzzy" THEN "mrfuzzy"
			WHEN product_page_seen = "/the-forever-love-bear" THEN "lovebear"
	     END;


-- Step 5：aggregate the data to assess funnel performance
SELECT product_seen, 
       COUNT(DISTINCT website_session_id) AS sessions,
       COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
       COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
       COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
       COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_product_level_made_it_flags
GROUP BY product_seen;

SELECT product_seen, 
       COUNT(DISTINCT website_session_id) AS sessions,
       COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS to_cart_click_rt,
       COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping_click_rt,
       COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing_click_rt,
       COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou_click_rt
FROM session_product_level_made_it_flags
GROUP BY product_seen;
       
       

/*
On September 25th we started giving customers the option to add a 2nd product while on the /cart page. Morgan says this has been positive, but I’d like your take on it. Could you please compare the month before vs the month 
after the change? I’d like to see CTR from the /cart page, Avg Products per Order, AOV, and overall revenue per /cart page view.
*/

USE mavenfuzzyfactory;

-- STEP 1: Identify the relevant /cart pageviews and their sessions
CREATE TEMPORARY TABLE sessions_seeing_cart
SELECT CASE WHEN created_at < "2013-09-25" THEN "Pre_Cross_Sell"
            WHEN created_at >= "2013-09-25" THEN "Post_Cross_Sell"
		END AS time_period,
		website_session_id AS cart_session_id,
        website_pageview_id AS cart_pageview_id
FROM website_pageviews
WHERE created_at BETWEEN "2013-08-25" AND "2013-10-25" AND pageview_url = "/cart";


-- STEP 2: See which of those /cart sessions clicked through to the shopping page
CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT ssc.time_period,
       ssc.cart_session_id,
       MIN(wp.website_pageview_id) AS pv_id_after_cart    # get the next pageview_id after cart
FROM sessions_seeing_cart AS ssc
LEFT OUTER JOIN website_pageviews AS wp
ON wp.website_session_id = ssc.cart_session_id 
	AND wp.website_pageview_id > ssc.cart_pageview_id    # seeing another page after the /cart
GROUP BY ssc.time_period, ssc.cart_session_id      
HAVING MIN(wp.website_pageview_id) IS NOT NULL;


-- STEP 3: Find the orders associated with the /car sessions. Analyze products purchased, ADV
CREATE TEMPORARY TABLE sessions_orders
SELECT ssc.time_period, 
	   ssc.cart_session_id, 
       o.order_id, 
       o.items_purchased, 
       o.price_usd
FROM sessions_seeing_cart AS ssc
JOIN orders AS o
ON ssc.cart_session_id = o.website_session_id;


-- STEP 4: Aggregate and analyze a summary of our findings.
CREATE TEMPORARY TABLE full_data
SELECT ssc.time_period,
       ssc.cart_session_id,
       CASE WHEN cssap.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
       CASE WHEN so.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
       so.items_purchased,
       so.price_usd
FROM sessions_seeing_cart AS ssc
LEFT JOIN cart_sessions_seeing_another_page AS cssap
	ON ssc.cart_session_id = cssap.cart_session_id
LEFT JOIN sessions_orders AS so
	ON ssc.cart_session_id = so.cart_session_id
GROUP BY cart_session_id;

SELECT time_period, 
       COUNT(DISTINCT cart_session_id) AS cart_sessions,
       SUM(clicked_to_another_page) AS clickthrouhgs,
       SUM(clicked_to_another_page) / COUNT(DISTINCT cart_session_id) AS cart_ctr,
       SUM(items_purchased) / SUM(placed_order) AS products_per_order,
       SUM(price_usd) / SUM(placed_order) AS aov,                                  # AverageOrderValue
       SUM(price_usd) / COUNT(DISTINCT cart_session_id) AS rev_per_cart_sesson     # revenue per cart session
FROM full_data
GROUP BY time_period;



/*
On December 12th 2013, we launched a third product targeting the birthday gift market (Birthday Bear). Could you please run a pre-post analysis comparing the month before vs. the month after, in terms of session-toorder conversion rate, AOV, products per order, and 
revenue per session?
*/

USE mavenfuzzyfactory;

SELECT CASE WHEN ws.created_at < "2013-12-12" THEN "Pre_Birthday_Bear" ELSE "Post_Birthday_Bear" END AS time_period,
	   COUNT(DISTINCT order_id) / COUNT(DISTINCT ws.website_session_id) AS conv_rate,
       SUM(price_usd) / COUNT(DISTINCT order_id) AS aov,    
       SUM(items_purchased) / COUNT(DISTINCT order_id) AS products_per_order,
       SUM(price_usd) / COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
FROM website_sessions AS ws
LEFT JOIN orders AS o
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at BETWEEN "2013-11-12" AND "2014-01-12"
GROUP BY 1
ORDER BY 1;



/*
Our Mr. Fuzzy supplier had some quality issues which weren’t corrected until September 2013. Then they had a major problem where the bears’ arms were falling off in 
Aug/Sep 2014. As a result, we replaced them with a new supplier on September 16, 2014. Can you please pull monthly product refund rates, by product, and confirm our quality issues are now fixed?
*/










