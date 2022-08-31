
DECLARE @timeto datetime = DATEADD(HOUR,0,CURRENT_TIMESTAMP)

--get inplay matches
SELECT 
	--DATEDIFF(s, kickofftime, getdate()) durationFromKO,
	l.LeagueGroupID, l.[Group], m.sporttype,
	m.matchid,eventstatus,  m.leagueid, l.leaguename, h.teamname home, a.teamname awayteam,m.kickofftime, homeid, awayid , livehomescore, liveawayscore
--INTO #InPlayMatch	
FROM bodb02.dbo.match m(nolock) 
	left join bodb02.dbo.League l (nolock) on m.leagueid=l.leagueid
	left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
	left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
WHERE 
	m.eventdate BETWEEN DATEADD(dd, DATEDIFF(dd, 0, @timeto), 0) AND DATEADD(dd, DATEDIFF(dd, 0, @timeto), 1)
	AND  m.eventstatus='running'
	--AND m.eventStatus NOT IN ('completed', 'refund', 'internal')
	AND l.isTest = 0-- exclude test leagues
	AND m.sporttype in (1 ) --soccer, basketball
	AND m.kickofftime <= @timeto --inplay
	AND m. ParentID is null  --main match only
	AND l.[Group] not in ('Specials','Specific 15min','Specific 10min')  --exclude special leagues
	AND m.matchcode NOT LIKE 'hedge%'
	AND m.matchcode NOT LIKE 'Betdaq%'
	AND m.matchcode NOT LIKE '%ET%'
	AND m.matchcode NOT LIKE '%PEN%'
	AND l.leaguename NOT LIKE '%Number of Regular Season Wins%'
	AND l.leaguename NOT LIKE '%First 3-Point%'
	AND l.leaguename NOT LIKE '%Most 3-Point%'
	AND l.leaguename NOT LIKE '%Most Point%'
	and l.LeagueGroupID  not in (42,74,108)
ORDER BY kickofftime 


--select * from odds (nolock)
--where matchid=42216786
--and bettype=3