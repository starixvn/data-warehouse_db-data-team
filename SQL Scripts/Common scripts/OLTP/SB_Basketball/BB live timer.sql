--drop table #match

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
m.sporttype=2
and LeagueGroupID not in (67,45,122) --SPECIALS, 3X3 3, SABA Basketball PinGoal
and ISNULL(l.isTest,0)=0

-- drop table #tmp
--raw tickets
select matchid, ExtraInfo , 
	ISNULL(CAST(ExtraInfo AS xml ).value('(/p1/@isht)[1]', 'varchar(10)'),0) isHT,
	ISNULL(CAST(ExtraInfo AS xml ).value('(/p1/@qt)[1]', 'varchar(10)'),'') qt,
	ISNULL(CAST(ExtraInfo AS xml ).value('(/p1/@min)[1]', 'varchar(10)'),'') MatchTimer, 
	transid, transdate, liveindicator, livehomescore, liveawayscore
into #tmp
from bettrans (nolock)
where matchid in (
			select matchid from #match 
			where eventdate='2022/3/20'
			) 
	and liveindicator=1 
	and currency not in (20,27,28)
order by transdate


--select distinct qt
--from #tmp

--drop table #FirstTicket
-- calculate first ticket for case No timer
select 
	 matchid, min(transid) FirstTicket
into #FirstTicket
from #tmp
where qt in (1)
group by matchid

select * from #FirstTicket
where matchid=50845637


select top 100 * 
from #match
where matchid in (select distinct matchid from #tmp)
and matchid in (50831795,
50831806,
50831824,
50805262,
50837376)

-- check tickets of 1 match 
select m.leaguename,m.kickofftime,eventstatus,
	case when isht=1 then 'BR2'
		when qt=0 and t.transid < f.FirstTicket   then 'Early TO' 
		when qt=0 and (t.transid > f.FirstTicket or f.FirstTicket Is null) then 'No timer' 
		when qt=1 and ISNULL(MatchTimer,'')='' then 'Early TO' 
		when qt=99 and ISNULL(MatchTimer,'')='' then 'BR4'
		when qt=99 and ISNULL(MatchTimer,'')!='' then 'OT'
		when  MatchTimer='00:00' then 'BR'+ cast(qt as varchar(5))
		when ISNULL(MatchTimer,'')='' then 'BR'+ cast( (qt -1) as varchar(5))	
		when qt>0 then 'Q'+ cast(qt as varchar(5)) end QT,
		--cast(matchtimer as time) t,  
		DATEPART(hour,cast(matchtimer as time)) Timer_Minute,	*
from #tmp t
left join #FirstTicket f on f.matchid = t.matchid
left join #match m on m.matchid=t.matchid
where   t.matchid=51708052
	 --  qt=0 and (t.transid > f.FirstTicket or f.FirstTicket Is null) and isht=0  --chec No timer cases
order by transdate

-- count by time section
select 
	case when isht=1 then 'BR2'
		when qt=0 and t.transid < f.FirstTicket  then 'Early TO' 
		when qt=0 and (t.transid > f.FirstTicket or f.FirstTicket Is null) then 'No timer' 
		when qt=1 and ISNULL(MatchTimer,'')='' then 'Early TO' 
		when qt=99 and ISNULL(MatchTimer,'')='' then 'BR4'
		when qt=99 and ISNULL(MatchTimer,'')!='' then 'OT'
		when  MatchTimer='00:00' then 'BR'+ cast(qt as varchar(5))
		when ISNULL(MatchTimer,'')='' then 'BR'+ cast( (qt -1) as varchar(5))	
		when qt>0 then 'Q'+ cast(qt as varchar(5)) end QT,
		--DATEPART(hour,cast(matchtimer as time)) Timer_Minute, 
		COUNT(1) betcount
from #tmp t
left join #FirstTicket f on f.matchid = t.matchid
--where t.matchid=51654336
--where t.matchid  in (select matchid from #match where LeagueGroupID not in (67))
group by 
	case when isht=1 then 'BR2'
		when qt=0 and t.transid < f.FirstTicket  then 'Early TO' 
		when qt=0 and (t.transid > f.FirstTicket or f.FirstTicket Is null) then 'No timer' 
		when qt=1 and ISNULL(MatchTimer,'')='' then 'Early TO' 
		when qt=99 and ISNULL(MatchTimer,'')='' then 'BR4'
		when qt=99 and ISNULL(MatchTimer,'')!='' then 'OT'
		when  MatchTimer='00:00' then 'BR'+ cast(qt as varchar(5))
		when ISNULL(MatchTimer,'')='' then 'BR'+ cast( (qt -1) as varchar(5))	
		when qt>0 then 'Q'+ cast(qt as varchar(5)) end  
		--, DATEPART(hour,cast(matchtimer as time))   
order by betcount desc






 