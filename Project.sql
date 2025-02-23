-- Insurance and Policy Project --
create database supply_chain;
use supply_chain;
show tables;
select * from policy_details; 
select * from customer_information;
select * from claims;
select * from payment_methods;
select * from aditional_fileds;

select * from brokerage;
select * from fees;
select * from individual_budgets;
select * from invoice;
select * from meeting;
select * from opportunity;

-- policy queries --

-- Total policy --
select count(policy_id) as Total_policies from policy_details; 

-- claim amount --
select sum(claim_amount) from claims; 

-- Total Customers --
create view total_customer as select distinct customer_id, count(policy_id) as policycount from policy_details group by customer_id order by policycount desc;
select count(*) from total_customer;

-- Age group wise policy --
create view age_group as select customer_id, name, gender, age, case
when age between "18" and "25" then "18-25"
when age between "26" and "35" then "26-35"
when age between "36" and "45" then "36-45"
else "46+"
end as age_bucket from customer_information;
select count(*) as policy_count, age_bucket from age_group group by age_bucket;

-- Gender wise policy --
select gender, count(customer_id) from customer_information group by gender; 

-- Policy type wise policy count --
select count(policy_id), policy_type from policy_details group by policy_type; 

-- Policy status -- 
 CREATE VIEW current_status AS
SELECT 
    policy_end_date,
    CASE
        WHEN YEAR(policy_end_date) = YEAR(CURDATE()) THEN 'Running'
        ELSE 'Expired'
    END AS policy_status
FROM policy_details;

SELECT policy_status, COUNT(*) 
FROM current_status 
GROUP BY policy_status;


-- Claim Status wise policy count --
select claim_status, count(*) as policycount from claims group by claim_status;

-- payment wise policy count --
select payment_status, count(policy_id) as policy_count from payment_methods group by payment_status; 

-- growth rate --
WITH policy_details AS 
(SELECT policy_start_date, Premium_Amount,
LAG(Premium_Amount)
 OVER (ORDER BY year(Policy_Start_Date)) AS previous_premiums 
 FROM policy_details)
SELECT Policy_Start_Date, Premium_Amount,
concat(round(((Premium_Amount - previous_premiums) / previous_premiums) * 100, 2), "%") AS growth_rate_percentage
FROM policy_details;

-- Growth Rate Yearly --
WITH yearly_premiums AS (
    SELECT 
        YEAR(policy_start_date) AS year,
        AVG(Premium_Amount) AS average_premium,
        LAG(AVG(Premium_Amount)) OVER (ORDER BY YEAR(policy_start_date)) AS previous_year_premium
    FROM 
        policy_details
    GROUP BY 
        YEAR(policy_start_date)
)
SELECT 
    year,
    average_premium,
    CONCAT(ROUND(((average_premium - previous_year_premium) / previous_year_premium) * 100, 2), '%') AS growth_rate_percentage
FROM 
    yearly_premiums
WHERE 
    previous_year_premium IS NOT NULL;



-- Branch deatails --

-- yearly meeting count --
select year(meeting_date) as year, count(global_attendees) from meeting group by year;

-- No of Invoice by Account Exec --
select count(income_class), account_executive, income_class from invoice group by account_executive, income_class;

-- Stage Funnel by Revenue --
select stage, sum(revenue_amount) from opportunity group by stage;

-- No of meeting By Account Exe --
select account_executive, count(global_attendees) as meeting_count from meeting group by account_executive;

-- Oppty-Product Distribution --
select product_group, count(opportunity_id) from opportunity group by product_group;

-- Oppty by Revenue-top 10 --
select opportunity_name, sum(revenue_amount) as amount from opportunity group by opportunity_name order by amount desc limit 10;

-- opportunity difference --
select stage, count(stage), case
when stage="qualify opportunity" or "propose solution" then "open"
when stage="negotiate" then "closed won"
else "open"
end as oppty_type from opportunity group by stage;

-- total opportunity --
select count(stage) as total_oppty from opportunity;

-- open opportunity --
create view open_oppty as select count(stage) as open_oppty from opportunity where stage in ("qualify opportunity", "propose solution");
select * from open_oppty;

-- open oppty top 10 --
select distinct Opportunity_name, stage, revenue_amount from opportunity  where stage in ("qualify opportunity", "propose solution") order by revenue_amount desc limit 10;

-- target --
select sum(cross_sell_bugdet) as target_cross_sell from individual_budgets; -- cross
select sum(new_budget) as target_new from individual_budgets;  -- neww
select sum(renewal_budget) as target_renewal from individual_budgets; -- renewal

-- Invoiced Achievement --
select sum(amount) from invoice where income_class = "cross sell";
select sum(amount) from invoice where income_class = "new";
select sum(amount) from invoice where income_class = "renewal";

-- cross sell Placed Achievement --
create view cross_sell_plcd_achived as (select(select sum(amount) from brokerage where brokerage.income_class in ("cross sell")) + sum(amount) as achived_amount, 
income_class from fees where income_class in ("cross sell"));
select * from cross_sell_plcd_achived;

-- new plcd achive --
create view new_plcd_achiv as (select(select sum(amount) from brokerage where brokerage.income_class in ("new")) + sum(amount) as achived_amount,
income_class from fees where income_class in ("new"));
select * from new_plcd_achiv;

-- renewal plcd achive --
create view renewal_plcd_achive as (select(select sum(amount) from brokerage where brokerage.income_class in ("renewal")) + sum(amount) as achived_amount,
income_class from fees where income_class in ("renewal"));
select * from renewal_plcd_achive;

-- cross sell plcd achive % --
SELECT CONCAT(ROUND(((SELECT SUM(amount) FROM brokerage WHERE income_class = "cross sell")+(SELECT SUM(amount) FROM fees WHERE income_class = "cross sell"))
/(SELECT SUM(Cross_sell_bugdet) FROM individual_budgets)* 100, 2),"%") AS "Cross sell plcd Ach %";

-- cross sell invoice achive % --
select concat(round((select sum(amount) from invoice
 where income_class = "Cross sell")/ (select sum(Cross_sell_bugdet)
 from individual_budgets)*100,2),"%") As "Cross sell invoice Ach %" ;

-- new plcd achiv % --
select concat(round(((select sum(amount) from brokerage where income_class = "new")+
(select sum(amount) from fees where income_class ="new"))/(select sum(new_budget) from individual_budgets)*100, 2),"%") as "new_plcd_achiv_%";

-- new invoice achive % --
select concat(round((select sum(amount) from invoice
 where income_class = "new")/ (select sum(new_budget)
 from individual_budgets)*100,2),'%') As "new invoice Ach %" ;

-- renewal plcd achiv % --
select concat(round(((select sum(amount) from brokerage where income_class = "renewal")+
(select sum(amount) from fees where income_class ="renewal"))/(select sum(renewal_budget) from individual_budgets)*100, 2),"%") as "renewal_plcd_achiv_%";

-- renewal invoice achive % --
select concat(round((select sum(amount) from invoice
 where income_class = "renewal")/ (select sum(renewal_budget)
 from individual_budgets)*100,2),'%') As "renewal invoice Ach %" ;

-------------------------------------------------------------------------------------------------------------------------------------------------------------








