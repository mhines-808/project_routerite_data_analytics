SELECT * FROM routerite_leads;

-- Assign a fleet-size score to each lead.

SELECT
	first_name, 
	company_name, 
	email,
    fleet_size_range,
    CASE
        WHEN fleet_size_range = '1-5' THEN 1
        WHEN fleet_size_range = '6-15' THEN 2
        WHEN fleet_size_range = '16-30' THEN 3
        WHEN fleet_size_range = '30+' THEN 4
        ELSE 0
    END AS fleet_size_score
FROM routerite_leads;

-- Creating view for this so I can come back to use it easily
CREATE VIEW leads_scored AS
SELECT
    record_id,
    email,
    first_name,
    last_name,
    company_name,
    fleet_size_range,
    CASE
        WHEN fleet_size_range = '1-5' THEN 1
        WHEN fleet_size_range = '6-15' THEN 2
        WHEN fleet_size_range = '16-30' THEN 3
        WHEN fleet_size_range = '30+' THEN 4
        ELSE 0
    END AS fleet_size_score,
    demo_requested_date,
    quote_requested_date,
    lead_status
FROM routerite_leads;

-- Test the view and have here for ease of use
SELECT * FROM leads_scored;
SELECT * FROM routerite_leads;


-- Score leads based on how far along they are in the funnel.
SELECT 
    first_name,
    last_name,
    company_name,
    CASE
        WHEN lead_status = 'In Progress' THEN 3
        WHEN lead_status = 'Open Deal' THEN 2
        WHEN lead_status = 'Open' THEN 1
        ELSE 0
    END AS lead_progress_score
FROM routerite_leads;

-- Add Lead Progress to our other view
CREATE OR REPLACE VIEW leads_scored AS
SELECT
    record_id,
    email,
    first_name,
    last_name,
    company_name,
    fleet_size_range,
    CASE
        WHEN fleet_size_range = '1-5' THEN 1
        WHEN fleet_size_range = '6-15' THEN 2
        WHEN fleet_size_range = '16-30' THEN 3
        WHEN fleet_size_range = '30+' THEN 4
        ELSE 0
    END AS fleet_size_score,
    demo_requested_date,
    quote_requested_date,
    lead_status,
    CASE
        WHEN lead_status = 'In Progress' THEN 3
        WHEN lead_status = 'Open Deal' THEN 2
        WHEN quote_requested_date IS NOT NULL THEN 2
        WHEN lead_status = 'Open' THEN 1
        ELSE 0
    END AS lead_progress_score
FROM routerite_leads;

-- pasting these here to use
SELECT * FROM leads_scored;
SELECT * FROM routerite_leads;

-- Combine the fleet-size score and funnel-progress score into a single total lead score, 
-- so each lead has one overall priority number."
-- Now take that total score and bucket it into Hot/Warm/Cold tiers."

WITH lead_totals AS (
    SELECT
        fleet_size_score,
        lead_progress_score,
        fleet_size_score + lead_progress_score AS total_score
    FROM leads_scored
)
SELECT
    total_score,
    CASE
        WHEN total_score >= 5 THEN 'Hot'
        WHEN total_score = 4 THEN 'Warm'
        ELSE 'Cold'
    END AS priority_tier
FROM lead_totals;

-- Updating my view

CREATE OR REPLACE VIEW leads_scored AS
WITH base_scores AS (
    SELECT
        record_id,
        email,
        first_name,
        last_name,
        company_name,
        fleet_size_range,
        CASE
            WHEN fleet_size_range = '1-5' THEN 1
            WHEN fleet_size_range = '6-15' THEN 2
            WHEN fleet_size_range = '16-30' THEN 3
            WHEN fleet_size_range = '30+' THEN 4
            ELSE 0
        END AS fleet_size_score,
        demo_requested_date,
        quote_requested_date,
        lead_status,
        CASE
            WHEN lead_status = 'In Progress' THEN 3
            WHEN lead_status = 'Open Deal' THEN 2
            WHEN quote_requested_date IS NOT NULL THEN 2
            WHEN lead_status = 'Open' THEN 1
            ELSE 0
        END AS lead_progress_score
    FROM routerite_leads
)
SELECT
    record_id,
    email,
    first_name,
    last_name,
    company_name,
    fleet_size_range,
    fleet_size_score,
    demo_requested_date,
    quote_requested_date,
    lead_status,
    lead_progress_score,
    fleet_size_score + lead_progress_score AS total_score,
    CASE
        WHEN fleet_size_score + lead_progress_score >= 5 THEN 'Hot'
        WHEN fleet_size_score + lead_progress_score = 4 THEN 'Warm'
        ELSE 'Cold'
    END AS priority_tier,
    quote_requested_date - demo_requested_date AS days_to_quote
FROM base_scores;

-- pasting these here to use
SELECT * FROM leads_scored;
SELECT * FROM routerite_leads;

-- How many days does it take, on average, for a lead to go from 
-- requesting a demo to requesting a quote — 
-- and does that average differ by priority tier
SELECT
priority_tier,
    ROUND(AVG(quote_requested_date - demo_requested_date), 2) AS days_to_quote
FROM leads_scored
GROUP BY priority_tier;





