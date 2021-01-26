
SELECT
    min(CONCAT(year, '-', LPAD(month, 2, '0'), '-', LPAD(day, 2, '0'))) AS session_start,
    event.searchSessionId AS search_session,
    event.isAnon AS is_anonymous,
    wiki AS wiki,
    event.skinVersion as skin_version,
-- wikis in test and similar wikis
    CASE
        WHEN (wiki IN('euwiki', 'frwiki', 'hewiki', 'ptwikiversity', 'frwiktionary', 'fawiki') AND event.skinVersion = 'latest') THEN 'WikiProjectInTest'
        WHEN (wiki IN ('slwiki', 'bewiki', 'dewiki', 'ruwiktionary', 'eswiktionary', 'cawiki',
            'da.wikipedia', 'rowiki', 'arwiki', 'idwiki', 'jawikiversity') AND event.skinVersion = 'legacy') THEN 'WikiProjectNotInTest' 
        ELSE 'NA'
        END AS test_group,
    IF(event.inputLocation = 'header-moved', 'new location', 'old location') AS search_location,
    Count(*) AS events
FROM event.searchSatisfaction 
WHERE 
-- review two week period before and after deployment
    year = 2020 
    AND ((month = 10 and day >= 05) OR (month = 11 and day < 04)) 
--  all search widget session searches
    AND event.action = 'searchResultPage'
    AND event.source = 'autocomplete'
    AND wiki IN ('euwiki', 'frwiki', 'hewiki', 'ptwikiversity', 'frwiktionary', 'fawiki',
    'slwiki', 'bewiki', 'dewiki', 'ruwiktionary', 'eswiktionary', 'cawiki',
    'da.wikipedia', 'rowiki', 'arwiki', 'idwiki', 'jawikiversity')
-- only review sessions on vector 
    AND event.skin = 'vector'
    AND event.inputLocation IN ('header-moved', 'header-navigation')
    AND event.subTest IS NULL
    -- remove bots
    AND useragent.is_bot = false 
GROUP BY 
    event.searchSessionId,
    event.isAnon,
    wiki,
    event.skinVersion,
    CASE
        WHEN (wiki IN('euwiki', 'frwiki', 'hewiki', 'ptwikiversity', 'frwiktionary', 'fawiki') AND event.skinVersion = 'latest') THEN 'WikiProjectInTest'
        WHEN (wiki IN ('slwiki', 'bewiki', 'dewiki', 'ruwiktionary', 'eswiktionary', 'cawiki',
            'da.wikipedia', 'rowiki', 'arwiki', 'idwiki', 'jawikiversity') AND event.skinVersion = 'legacy') THEN 'WikiProjectNotInTest' 
        ELSE 'NA'
        END,
    IF(event.inputLocation = 'header-moved', 'new location', 'old location');