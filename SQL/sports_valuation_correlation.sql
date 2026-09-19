-- Assigns a ranking value to each team/city pair based on the amount of years spent in that city  
WITH city_rank AS (
	SELECT 
		team_id, 
		city, 
		RANK () OVER (PARTITION BY team_id ORDER BY years DESC, city ASC) AS ranking
	FROM (
		SELECT team_id, city, COUNT (*) AS years
		FROM valuations
		GROUP BY team_id, city
	) AS year_count
), 

-- Creates one row for each team with its top-ranked city
top_city AS (    
	SELECT 
		team_id, 
		city
	FROM city_rank
	WHERE ranking = 1
), 

-- Creates a snapshot avg valution for each team
team_evals AS ( 
	SELECT 
		team_id, 
		AVG(evaluation) AS avg_eval
	FROM valuations
	GROUP BY team_id
), 

-- Displays the total avg evaluation and media market rank of all teams and years across each team row
team_market AS (
	SELECT 
		te.team_id, 
		te.avg_eval, 
		mm.media_market_rank, 
		AVG(te.avg_eval) OVER() AS total_avg_eval,
		AVG(mm.media_market_rank) OVER()AS avg_media_market_rank
	FROM top_city tc
	JOIN team_evals te
		ON tc.team_id = te.team_id
	JOIN media_markets mm 
		ON tc.city = mm.market_name
), 

-- Begins the deviation calculation for the correlation cooefficient 
deviations AS (
	SELECT 
		team_id, 
		avg_eval, 
		(avg_eval - total_avg_eval) AS ae_dev,
		(avg_eval - total_avg_eval) * (avg_eval - total_avg_eval) AS ae_dev_sq,
		media_market_rank,
		(media_market_rank - avg_media_market_rank) AS mmr_dev,
		(media_market_rank - avg_media_market_rank) * (media_market_rank - avg_media_market_rank) AS mmr_dev_sq,
		(avg_eval - total_avg_eval) * (media_market_rank - avg_media_market_rank) AS ind_covariance
	FROM team_market
), 

-- Correlation computed manually to display the underlying statistics
correlation AS (
	SELECT 
		AVG(ae_dev_sq) AS avg_eval_var, 
		AVG(mmr_dev_sq) AS avg_mmr_var,
		AVG(ind_covariance) AS covariance,
		SQRT(AVG(ae_dev_sq)) AS eval_st_dev,
		SQRT(AVG(mmr_dev_sq)) AS mmr_st_dev,
		AVG(ind_covariance) / (SQRT(AVG(ae_dev_sq)) * SQRT(AVG(mmr_dev_sq))) AS r,
		AVG(ind_covariance) / AVG(mmr_dev_sq) AS slope
	FROM deviations 
)

-- Outer query that performs the regression calculation and displays each teams true and predicted evaluation along with any residual
SELECT 
	team_id, 
	media_market_rank,
	avg_eval,
	avg_eval - (ae_dev - (slope * mmr_dev)) AS predicted,
	ae_dev - (slope * mmr_dev) AS residual
FROM deviations
CROSS JOIN correlation
;