CREATE TABLE vanorder (
  `idvanOrder` int(10) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `order_status` tinyint(3) unsigned NOT NULL DEFAULT '0',  
  `order_subset` varchar(10) NOT NULL DEFAULT 'A',
  `requestor_client_id` int(11) DEFAULT NULL,
  `servicer_auth` int(10) unsigned DEFAULT NULL,  
  `total_price` smallint(5) unsigned NOT NULL DEFAULT '0',
  `order_datetime` datetime NOT NULL,  
  `txCreate` datetime NOT NULL
)
;

CREATE TABLE vaninterest (
  `idvanInterest` int(10) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `idvanOrder` int(10) unsigned NOT NULL,
  `order_subset_assigned` varchar(10) NOT NULL DEFAULT 'A',
  `servicer_auth` int(10) unsigned DEFAULT NULL,
  `txCreate` datetime NOT NULL
)
;


--1) For hours with orders, how many orders are there each hour based on order time?
SELECT hour(order_datetime) as hr, count(*)
FROM vanorder
GROUP BY hr;

--2) What is the percentage of money spent for each of the following group of clients?
-- Clients who completed 1 order : 71.39%
-- Clients who completed more than 1 order : 28.61%
CREATE temporary TABLE clients AS
SELECT requestor_client_id AS ID,
COUNT(*) AS orders,
SUM(total_price) AS price
FROM vanorder
GROUP requestor_client_id
;
SELECT
ROUND(sum(CASE WHEN orders = 1 THEN price END)/sum(price)*100, 2) AS one_order,
ROUND(sum(CASE WHEN orders > 1 THEN price END)/sum(price)*100, 2) AS multi_order
FROM clients;

/*3) List of unique Client ID who completed at least one order,
also show each client's total money spent, and the total order(s)
completed. Order the list by total money spent (descending), then by
total order(s) completed (descending)*/

SELECT requestor_client_id, COUNT(*), SUM(total_price)
from vanorder where order_status = 2

/*4) List of all drivers who took order(s) (regardless of whether they
eventually complete the order), also show each driver's total income
and total order(s) completed. Order the list by total income
(descending), then by total order(s) completed*/

SELECT vaninterest.servicer_auth,
A.SO AS noOrder,
B.SM AS income FROM vaninterest
inner join (SELECT servicer_auth, COUNT(*) AS SO
FROM vanorder WHERE order_status = 2 GROUP BY servicer_auth) A
ON vaninterest.servicer_auth = A.servicer_auth
inner JOIN (SELECT servicer_auth, sum(total_price) AS SM
FROM vanorder WHERE order_status = 2 GROUP BY servicer_auth) B
ON B.servicer_auth = vaninterest.servicer_auth
GROUP BY servicer_auth
ORDER BY income DESC, noOrder
;
--Group by requestor_client_id
--Order by sum(total_price) DESC, count(*) DESC;

--5) List of driver ID who took orders, but never complete an order?
SELECT servicer_auth
FROM (
  SELECT vanorder.servicer_auth
  FROM vanorder
  UNION ALL
  SELECT vaninterest.servicer_auth
  FROM vaninterest
) van
GROUP BY servicer_auth
HAVING COUNT(*) = 1
ORDER BY servicer_auth;
