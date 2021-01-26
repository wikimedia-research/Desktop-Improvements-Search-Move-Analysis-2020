WITH clicks AS (
SELECT
    event.searchSessionId AS click_session,
    wiki AS click_wiki,
    COUNT(*) AS click_events
FROM event.searchSatisfaction
WHERE
    -- ab test restarted on Oct 20th when isAnon field was added
    year = 2020 
    AND ((month = 10 and day >= 20) OR (month = 11 and day < 04)) 
    AND event.action = 'click'
    AND event.source = 'autocomplete'
    -- review test wikis
    AND wiki IN ('euwiki', 'frwiki', 'hewiki', 'ptwikiversity', 'frwiktionary', 'fawiki')
    -- deployed on on the new vector skin
    AND event.skinVersion = 'latest'
    AND event.skin = 'vector'
-- remove bots
    AND useragent.is_bot = false 
GROUP BY 
    event.searchSessionId,
    wiki
),

-- all search sessions from AB test
searches AS (

SELECT
    IF(event.inputLocation = 'header-moved', 'new_location', 'old_location') AS search_location,
    event.isAnon AS is_anonymous,
    event.searchSessionId AS search_session,
    wiki AS search_wiki,
       CASE
        WHEN event.hitsReturned > 0 THEN 'TRUE'
        WHEN event.hitsReturned = 0 THEN 'FALSE'
        ELSE NULL
        END AS results_returned,
    COUNT(*) AS search_events
FROM event.searchSatisfaction 
WHERE 
-- ab test restarted on Oct 20th when isAnon field was added
    year = 2020 
    AND ((month = 10 and day >= 20) OR (month = 11 and day < 04)) 
    AND event.action = 'searchResultPage'
    AND event.source = 'autocomplete'
    AND event.inputLocation IN ('header-moved', 'header-navigation')
-- remove events that were logged prior to isAnon field addition
    AND event.isAnon IS NOT NULL
-- review test wikis
    AND wiki IN ('euwiki', 'frwiki', 'hewiki', 'ptwikiversity', 'frwiktionary', 'fawiki')
-- deployed on on the new vector skin
    AND event.skinVersion = 'latest'
    AND event.skin = 'vector'
-- remove bots
    AND useragent.is_bot = false 
GROUP BY 
    IF(event.inputLocation = 'header-moved', 'new_location', 'old_location') ,
    event.isAnon,
    event.searchSessionId,
    wiki,
    CASE
        WHEN event.hitsReturned > 0 THEN 'TRUE'
        WHEN event.hitsReturned = 0 THEN 'FALSE'
        ELSE NULL
        END 
)
--Main Query--
SELECT
    search_location,
    is_anonymous,
    search_session,
    search_wiki,
    results_returned,
    sum(search_events) AS search_events,
    SUM(CAST(click_events is NOT NULL as int)) AS click_events,
    SUM(CAST(click_session IS NOT NULL AS int)) = 1 AS is_clickthrough_session
FROM searches
LEFT JOIN clicks ON
    searches.search_session = clicks.click_session AND
    searches.search_wiki = clicks.click_wiki 
GROUP BY 
    search_location,
    is_anonymous,
    search_session,
    results_returned,
    search_wiki;