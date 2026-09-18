WITH city_rank as (
SELECT team_id, city, RANK () OVER (PARTITION BY team_id ORDER BY years DESC, city ASC) as ranking
FROM (
	SELECT team_id, city, COUNT (*) as years
	FROM valuations
	GROUP BY team_id, city
	) as year_count
), top_city as (
SELECT team_id, city
FROM city_rank
WHERE ranking = 1
), team_evals as (
SELECT team_id, AVG(evaluation) as avg_eval
FROM valuations
GROUP BY team_id
), team_market as (
SELECT te.team_id, 
te.avg_eval, 
mm.media_market_rank, 
AVG(te.avg_eval) OVER() as total_avg_eval,
AVG(mm.media_market_rank) OVER()as avg_media_market_rank
FROM top_city tc
JOIN team_evals te
	ON tc.team_id = te.team_id
JOIN media_markets mm 
	ON tc.city = mm.market_name
), deviations as (
SELECT team_id, 
avg_eval, 
(avg_eval - total_avg_eval) as ae_dev,
(avg_eval - total_avg_eval) * (avg_eval - total_avg_eval) as ae_dev_sq,
media_market_rank,
(media_market_rank - avg_media_market_rank) as mmr_dev,
(media_market_rank - avg_media_market_rank) * (media_market_rank - avg_media_market_rank) as mmr_dev_sq,
(avg_eval - total_avg_eval) * (media_market_rank - avg_media_market_rank) as ind_covariance
FROM team_market
), correlation as (
SELECT AVG(ae_dev_sq) as avg_eval_var, 
AVG(mmr_dev_sq) as avg_mmr_var,
AVG(ind_covariance) as covariance,
SQRT(AVG(ae_dev_sq)) as eval_st_dev,
SQRT(AVG(mmr_dev_sq)) as mmr_st_dev,
AVG(ind_covariance) / (SQRT(AVG(ae_dev_sq)) * SQRT(AVG(mmr_dev_sq))) as r,
AVG(ind_covariance) / AVG(mmr_dev_sq) as slope
FROM deviations 
)
SELECT team_id, 
media_market_rank,
avg_eval,
avg_eval - (ae_dev - (slope * mmr_dev)) as predicted,
ae_dev - (slope * mmr_dev) as residual
FROM deviations
CROSS JOIN correlation
;