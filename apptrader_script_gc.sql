--Calculating the total profit
WITH calculations AS (
SELECT
	name,
	MAX(genres) AS genre,
	(CASE WHEN COUNT(play_store_apps.price) > 0 AND COUNT(app_store_apps.price) > 0 THEN true ELSE false END) AS in_both_stores,
	(CASE WHEN (MAX(play_store_apps.price::money) * 10000) < 25000::money THEN 25000::money ELSE  (MAX(play_store_apps.price::money) * 10000) END) AS acq_cost_play_store,
	(CASE WHEN (MAX(app_store_apps.price::money) * 10000) < 25000::money THEN 25000::money ELSE (MAX(app_store_apps.price::money) * 10000) END) AS acq_cost_app_store,
--both together:
	(CASE WHEN MAX(play_store_apps.price::money) IS NULL THEN 0::money WHEN (MAX(play_store_apps.price::money) * 10000) < 25000::money THEN 25000::money ELSE (MAX(play_store_apps.price::money) * 10000) END) +
	(CASE WHEN MAX(app_store_apps.price::money) IS NULL THEN 0::money WHEN (MAX(app_store_apps.price::money) * 10000) < 25000::money THEN 25000::money ELSE (MAX(app_store_apps.price::money) * 10000) END) AS acq_cost_total,
--ratings:
	COALESCE(MAX(play_store_apps.rating), 0) AS play_rating,
	--COALESCE(FLOOR((MAX(play_store_apps.rating)/ .25))*6 + 12, 0) AS play_months_longevity,
	--round to NEAREST .25:
	COALESCE(ROUND((MAX(play_store_apps.rating)/ 25),2)*100*6 + 12, 0) AS play_months_longevity,
	COALESCE(MAX(app_store_apps.rating),0) AS app_rating,
	--COALESCE(FLOOR((MAX(app_store_apps.rating)/ .25))*6 + 12,0) AS app_months_longevity,
	COALESCE(ROUND((MAX(app_store_apps.rating)/ 25),2)*100*6 + 12,0) AS app_months_longevity,
--profit
	COALESCE((FLOOR((MAX(play_store_apps.rating)/ .25))*6 + 12),0) * 5000 +
	COALESCE((FLOOR((MAX(app_store_apps.rating)/ .25))*6 + 12),0) * 5000 AS total_gross,
--advertising
	(CASE WHEN COALESCE((FLOOR((MAX(play_store_apps.rating)/ .25))*6 + 12),0) > COALESCE((FLOOR((MAX(app_store_apps.rating)/ .25))*6 + 12),0) THEN COALESCE((FLOOR((MAX(play_store_apps.rating)/ .25))*6 + 12),0) ELSE COALESCE((FLOOR((MAX(app_store_apps.rating)/ .25))*6 + 12),0) END) * 1000 AS advertising_expense,
	--
	COUNT(play_store_apps.price) + COUNT(app_store_apps.price) AS times_listed,
	COUNT(play_store_apps.price) AS times_listed_in_play_store,
	COUNT(app_store_apps.price) AS times_listed_in_app_store,
	MIN(play_store_apps.price::money) AS min_price_play,
	MAX(play_store_apps.price::money) AS max_price_play,
	MIN(app_store_apps.price::money) AS min_price_app,
	MAX(app_store_apps.price::money) AS max_price_app,
	(CASE WHEN MIN(play_store_apps.price::money) <> MAX(play_store_apps.price::money) THEN 1
		  WHEN MIN(play_store_apps.price::money) <> MIN(app_store_apps.price::money) THEN 1
		  WHEN MIN(play_store_apps.price::money) <> MAX(app_store_apps.price::money) THEN 1
		  WHEN MAX(play_store_apps.price::money) <> MIN(app_store_apps.price::money) THEN 1
		  WHEN MAX(play_store_apps.price::money) <> MAX(app_store_apps.price::money) THEN 1
		  WHEN MIN(app_store_apps.price::money) <> MAX(app_store_apps.price::money) THEN 1
		  ELSE 0 END	  
	) AS is_there_a_difference,
	MAX(play_store_apps.price::money) - MIN(play_store_apps.price::money) AS play_difference,
	MAX(app_store_apps.price::money) - MIN(app_store_apps.price::money) AS app_difference
FROM play_store_apps
LEFT JOIN app_store_apps USING(name)
GROUP BY name
				-- in_both_stores
--HAVING (CASE WHEN COUNT(play_store_apps.price) > 0 AND COUNT(app_store_apps.price) > 0 THEN true ELSE false END) = true
ORDER BY acq_cost_total DESC NULLS LAST
--ORDER BY in_both_stores DESC, is_there_a_difference DESC, play_difference DESC, app_difference DESC, times_listed DESC
)
SELECT
	total_gross::money - (acq_cost_total + advertising_expense::money) AS total_profit,
	*
FROM calculations
--WHERE play_rating = 4
--WHERE name IN ('Egg, Inc.', 'Domino''s Pizza USA', 'Microsoft Excel', 'DoorDash - Food Delivery')
ORDER BY total_profit DESC --NULLS LAST
;

--Pi Day recommendations
--Egg, Inc.
--Domino's Pizza USA
--Microsoft Excel
--DoorDash - Food Delivery


--exploring the data:
/*
name	category	rating	review_count	size	install_count	type	price	content_rating	genres
"Photo Editor & Candy Camera & Grid & ScrapBook"	"ART_AND_DESIGN"	4.1	159	"19M"	"10,000+"	"Free"	"0"	"Everyone"	"Art & Design"
"Coloring book moana"	"ART_AND_DESIGN"	3.9	967	"14M"	"500,000+"	"Free"	"0"	"Everyone"	"Art & Design;Pretend Play"
"U Launcher Lite – FREE Live Cool Themes, Hide Apps"	"ART_AND_DESIGN"	4.7	87510	"8.7M"	"5,000,000+"	"Free"	"0"	"Everyone"	"Art & Design"
*/
SELECT * FROM play_store_apps;  --10840
SELECT * FROM play_store_apps ORDER BY price::money DESC;  --highest price is $400.00
/*
name	size_bytes		currency		price		review_count		rating		content_rating		primary_genre
"PAC-MAN Premium"	"100788224"	"USD"	3.99	"21292"	4.0	"4+"	"Games"
"Evernote - stay organized"	"158578688"	"USD"	0.00	"161065"	4.0	"4+"	"Productivity"
"WeatherBug - Local Weather, Radar, Maps, Alerts"	"100524032"	"USD"	0.00	"188583"	3.5	"4+"	"Weather"
*/
SELECT * FROM app_store_apps;   --7197


--Looking for price differences
--it looks like there are 32 apps that have a different price in the App Store vs the Play Store
--and it looks like 2 of them (Cardiac diagnosis and Calculator) have a couple diffent prices even in the same play store
SELECT
	name,
	COUNT(play_store_apps.price) + COUNT(app_store_apps.price) AS times_listed,
	COUNT(play_store_apps.price) AS times_listed_in_play_store,
	COUNT(app_store_apps.price) AS times_listed_in_app_store,
	MIN(play_store_apps.price::money) AS min_price_play,
	MAX(play_store_apps.price::money) AS max_pric_play,
	MIN(app_store_apps.price::money) AS min_price_app,
	MAX(app_store_apps.price::money) AS max_price_app,
	(CASE WHEN MIN(play_store_apps.price::money) <> MAX(play_store_apps.price::money) THEN 1
		  WHEN MIN(play_store_apps.price::money) <> MIN(app_store_apps.price::money) THEN 1
		  WHEN MIN(play_store_apps.price::money) <> MAX(app_store_apps.price::money) THEN 1
		  WHEN MAX(play_store_apps.price::money) <> MIN(app_store_apps.price::money) THEN 1
		  WHEN MAX(play_store_apps.price::money) <> MAX(app_store_apps.price::money) THEN 1
		  WHEN MIN(app_store_apps.price::money) <> MAX(app_store_apps.price::money) THEN 1
		  ELSE 0 END	  
	) AS is_there_a_difference,
	MAX(play_store_apps.price::money) - MIN(play_store_apps.price::money) AS play_difference,
	MAX(app_store_apps.price::money) - MIN(app_store_apps.price::money) AS app_difference
FROM play_store_apps
LEFT JOIN app_store_apps USING(name)
--WHERE name ILIKE '%puffin%'
GROUP BY name
ORDER BY is_there_a_difference DESC, play_difference DESC, app_difference DESC, times_listed DESC
--ORDER BY name
;

SELECT * FROM play_store_apps WHERE name = 'Cardiac diagnosis (heart rate, arrhythmia)' OR name = 'Calculator' ORDER BY name;




