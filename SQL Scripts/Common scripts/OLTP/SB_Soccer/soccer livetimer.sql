 -- drop table #match

SELECT  L.[GROUP] LeagueGroup,LeagueGroupID,
		m.leagueid, l.leaguename, SessionTime,
        m.matchid,             
        MatchCode, 
		h.teamname home, a.teamname away,
		eventstatus,
		finalhomescore,
		finalawayscore,
		kickofftime,
		GlobalShowTime,
		m.eventdate, mr.SubType, m.ChildMatchType, m.ParentID --, m.ParentID2
		into #match
FROM Match m WITH(NOLOCK)
	INNER JOIN league l WITH(NOLOCK) ON m.LeagueId = l.LeagueId
left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
left join match_remark mr (nolock) on mr.matchid=m.matchid
WHERE
-- m.matchid=42216786 and
m.sporttype=1
and LeagueGroupID not in (113, 74, 42,108) --SABA PinGoal, , Virtual Sport Bacarr,Virtual, Virtual Futsal
--LeagueGroupID 12,14,--Specials,Specific 15min
and ISNULL(l.isTest,0)=0


select * from LeagueGroup


-- drop table #tmp
--raw tickets
select matchid, ExtraInfo , 
	ISNULL(CAST(ExtraInfo AS xml ).value('(/p1/@isht)[1]', 'varchar(10)'),0) isHT,
	ISNULL(CAST(ExtraInfo AS xml ).value('(/p1/@hlt)[1]', 'varchar(10)'),'') isHideLiveTimer,
	ISNULL(CAST(ExtraInfo AS xml ).value('(/p1/@H)[1]', 'varchar(10)'),'') Half,
	ISNULL(CAST(ExtraInfo AS xml ).value('(/p1/@min)[1]', 'varchar(10)'),'') MatchTimer, 
	transid, transdate, bettype, liveindicator, livehomescore, liveawayscore
into #tmp
from bettrans (nolock)
where matchid in (
			select matchid from #match 
			where eventdate='2022/03/02'
			) 
	and liveindicator=1 
	and currency not in (20,27,28)
	and bettype in (1,3,7,8)
 


--select distinct qt
--from #tmp

--drop table #FirstTicket
-- calculate first ticket for case No timer
  
select   * 
from #match
where matchid in (select distinct matchid from #tmp)
--and matchid in (51117556)
order by kickofftime desc

-- check tickets of 1 match 
select --m.leaguename, 
	m.matchid, transdate, transid,

	case when liveindicator=0 then 'Nonlive'
		when isHT=1 then 'HT'
		when isHideLiveTimer=1 or Half=0 then 'NA' -- No timer
		when Half=1 and MatchTimer= '00:00' then 'KO'
		when Half=1 and LEFT(MatchTimer,6)= '45:00+' then '45(+)'
		when Half=2 and LEFT(MatchTimer,6)= '90:00+' then '90(+)'
		
		when MatchTimer='' then 'NA'

		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  0 AND 4 THEN '0.00-5.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  5 AND 9 THEN '5.01-10.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  10 AND 14 THEN '10.01-15.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  15 AND 19 THEN '15.01-20.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  20 AND 24 THEN '20.01-25.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  25 AND 29 THEN '25.01-30.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  30 AND 34 THEN '30.01-35.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  35 AND 39 THEN '35.01-40.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  40 AND 44 THEN '40.01-45.00'
		
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  0 AND 4 THEN '45.00-50.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  5 AND 9 THEN '50.01-55.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  10 AND 14 THEN '55.01-60.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  15 AND 19 THEN '60.01-65.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  20 AND 24 THEN '65.01-70.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  25 AND 29 THEN '70.01-75.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  30 AND 34 THEN '75.01-80.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  35 AND 39 THEN '80.01-85.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  40 AND 44 THEN '85.01-90.00'

	end TimerGroup,
	t.Half,

	case when liveindicator=0 then -1
	when isHT=1 then 0
	when isHideLiveTimer=1  or Half= 0 then -1
	when Half=1 and MatchTimer= '00:00' then 0
	when Half=1 and LEFT(MatchTimer,6)= '45:00+' then DATEPART(MINUTE,cast(REPLACE(MatchTimer,'45:00+','00:') as time))
	when Half=2 and LEFT(MatchTimer,6)= '90:00+' then  DATEPART(MINUTE,cast(REPLACE(MatchTimer,'90:00+','00:') as time))
	when MatchTimer='' then -1
	else
			DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) 
		end timerMin ,  

	ExtraInfo, 
	t.isHT,	t.MatchTimer, t.isHideLiveTimer,	t.bettype
from #tmp t
left join #match m on m.matchid=t.matchid
where   t.matchid= 51112299-- 51117556
order by transdate


-- count by time section
select 
	case when liveindicator=0 then 'Nonlive'
		when isHT=1 then 'HT'
		when isHideLiveTimer=1 or Half=0 then 'NA'
		when Half=1 and MatchTimer= '00:00' then 'KO'
		when Half=1 and LEFT(MatchTimer,6)= '45:00+' then '45(+)'
		when Half=2 and LEFT(MatchTimer,6)= '90:00+' then '90(+)'
		
		when MatchTimer='' then 'NA'

		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  0 AND 4 THEN '0.00-5.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  5 AND 9 THEN '5.01-10.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  10 AND 14 THEN '10.01-15.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  15 AND 19 THEN '15.01-20.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  20 AND 24 THEN '20.01-25.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  25 AND 29 THEN '25.01-30.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  30 AND 34 THEN '30.01-35.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  35 AND 39 THEN '35.01-40.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  40 AND 44 THEN '40.01-45.00'
		
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  0 AND 4 THEN '45.00-50.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  5 AND 9 THEN '50.01-55.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  10 AND 14 THEN '55.01-60.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  15 AND 19 THEN '60.01-65.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  20 AND 24 THEN '65.01-70.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  25 AND 29 THEN '70.01-75.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  30 AND 34 THEN '75.01-80.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  35 AND 39 THEN '80.01-85.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  40 AND 44 THEN '85.01-90.00'

	end TimerGroup,

	--case when liveindicator=0 then -1
	--when isHT=1 then 0
	--when isHideLiveTimer=1  or Half= 0 then -1
	--when Half=1 and MatchTimer= '00:00' then 0
	--when Half=1 and LEFT(MatchTimer,6)= '45:00+' then DATEPART(MINUTE,cast(REPLACE(MatchTimer,'45:00+','00:') as time))
	--when Half=2 and LEFT(MatchTimer,6)= '90:00+' then  DATEPART(MINUTE,cast(REPLACE(MatchTimer,'90:00+','00:') as time))
		
	--when MatchTimer='' then -1
	--else
	--		DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) 
	--	end timerMin, 
	COUNT(1) betcount
from #tmp t
--where t.matchid=50773162
where t.matchid not in (select matchid from #match where LeagueGroupID   in (12,14))
group by 
	case when liveindicator=0 then 'Nonlive'
		when isHT=1 then 'HT'
		when isHideLiveTimer=1 or Half=0 then 'NA'
		when Half=1 and MatchTimer= '00:00' then 'KO'
		when Half=1 and LEFT(MatchTimer,6)= '45:00+' then '45(+)'
		when Half=2 and LEFT(MatchTimer,6)= '90:00+' then '90(+)'
		
		when MatchTimer='' then 'NA'

		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  0 AND 4 THEN '0.00-5.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  5 AND 9 THEN '5.01-10.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  10 AND 14 THEN '10.01-15.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  15 AND 19 THEN '15.01-20.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  20 AND 24 THEN '20.01-25.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  25 AND 29 THEN '25.01-30.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  30 AND 34 THEN '30.01-35.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  35 AND 39 THEN '35.01-40.00'
		when Half=1 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  40 AND 44 THEN '40.01-45.00'
		
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  0 AND 4 THEN '45.00-50.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  5 AND 9 THEN '50.01-55.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  10 AND 14 THEN '55.01-60.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  15 AND 19 THEN '60.01-65.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  20 AND 24 THEN '65.01-70.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  25 AND 29 THEN '70.01-75.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  30 AND 34 THEN '75.01-80.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  35 AND 39 THEN '80.01-85.00'
		when Half=2 and DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) BETWEEN  40 AND 44 THEN '85.01-90.00'

	end  

	--,case when liveindicator=0 then -1
	--when isHT=1 then 0
	--when isHideLiveTimer=1  or Half= 0 then -1
	--when Half=1 and MatchTimer= '00:00' then 0
	--when Half=1 and LEFT(MatchTimer,6)= '45:00+' then DATEPART(MINUTE,cast(REPLACE(MatchTimer,'45:00+','00:') as time))
	--when Half=2 and LEFT(MatchTimer,6)= '90:00+' then  DATEPART(MINUTE,cast(REPLACE(MatchTimer,'90:00+','00:') as time))
		
	--when MatchTimer='' then -1
	--else
	--		DATEPART(MINUTE,cast(('00:' + matchtimer) as time )) 
	--	end timerMin,  
order by betcount desc






 