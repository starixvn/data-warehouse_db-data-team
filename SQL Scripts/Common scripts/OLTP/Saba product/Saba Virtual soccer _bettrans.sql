DECLARE @winlostdate smalldatetime
SET @winlostdate = '2020/05/07'


IF OBJECT_ID('tempdb..#matches') IS NOT NULL DROP TABLE #matches;  

select * 
into #matches
from   (
	SELECT 
		l.LeagueGroupID, l.[Group],m. ParentID,
		m.matchid, m.leagueid, l.leaguename, h.teamname home, a.teamname awayteam,m.GlobalShowTime ko --,GlobalShowTime
		, m.finalhomescore, finalawayscore, hthomescore, htawayscore
		,(finalhomescore - finalawayscore) totalhandicap, (finalhomescore + finalawayscore) totalGoal
		,(hthomescore - htawayscore) totalhandicapH1, (hthomescore + htawayscore) totalGoalH1
	FROM match m with(nolock)
		INNER JOIN League l with(nolock) on m.leagueid = l.leagueid
		INNER JOIN team h with(nolock) on m.homeid = h.teamid
		INNER JOIN team a with(nolock) on m.awayid = a.teamid
	WHERE 
		m.eventdate = @winlostdate AND	
		m.sporttype = 1		
		AND m.eventstatus = 'completed'
		and isnull(l.LeagueGroupID,0) in (42,74)
		--and ( h.teamname not like '%(PEN)%')
		--(l.leaguename like '%PES%' 	) and
		and isTest=0
)	t

/*
 select * from #matches
 order by ko
*/

--punter data
-- drop table #CustData
SELECT
	b.custid,
	b.Username
	,count(b.transid) as betcount	
	,sum(ABS(b.stake)*actualrate) as memberTO			
	,sum(CASE WHEN b.recommend IN (52466) THEN 0 ELSE (winlost-actual_stake+playercomm)*actualrate END) memberWL
	,SUM(CASE
                              WHEN tpositiontaking = 1
                              THEN 0
                              ELSE(1 - b.tpositiontaking - ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * ABS(b.stake) * CASE
                                                                                                      WHEN virtualrate > actualrate
                                                                                                      THEN virtualrate
                                                                                                      ELSE actualrate
                                                                                                  END
                          END) AS RealTurnover
	,-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm - (CASE
                                                                                                  WHEN tpositiontaking = 1
                                                                                                  THEN 0
                                                                                                  ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
                                                                                             END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * actualrate) AS RealIncome
into #CustData
FROM dbo.bettrans b with(nolock)
	INNER JOIN #matches e ON b.matchid = e.matchid
	JOIN dbo.Customer ag WITH(NOLOCK) ON ag.custid = b.recommend
	JOIN dbo.Site s WITH(NOLOCK) ON s.site = ag.site
where  statusID IN(111, 112, 113)
	   and b.currency <>20
	  -- and ag.site='789y'
	   --and bettype=3
GROUP BY b.custid, b.Username--, e.leaguename
order by memberWL desc

-- top punter
select --top 100 
	su.username AS             SuperCode
	    , ma.username AS             MasterCode
	    , ag.username AS             AgentCode,
		c.username, 
		tc.betcount,
		tc.MemberTO,
		tc.memberWL,
		tc.memberWL/MemberTO Margin
from #CustData tc
join Customer c on c.custid = tc.CustID
LEFT JOIN bodb02.dbo.Customer AS su WITH (NOLOCK) ON c.srecommend = su.custid
LEFT JOIN bodb02.dbo.Customer AS ma WITH (NOLOCK) ON c.mrecommend = ma.custid
LEFT JOIN bodb02.dbo.Customer AS ag WITH (NOLOCK) ON c.recommend = ag.custid
order by memberWL desc 

--active member count
SELECT
	count(distinct b.custid) activeMember
FROM dbo.bettrans b with(nolock)
	INNER JOIN #matches e ON b.matchid = e.matchid
	JOIN dbo.Customer ag WITH(NOLOCK) ON ag.custid = b.recommend
	JOIN dbo.Site s WITH(NOLOCK) ON s.site = ag.site
where  ruben = 1
       AND statusID IN(111, 112, 113)
	   and b.currency <>20

--  drop table #rawdata

-- raw data
select ag.site,b.*
into #rawdata
from bettrans b(NOLOCK)
LEFT JOIN dbo.Customer ag WITH(NOLOCK) ON ag.custid = b.recommend
where b.matchid in (select matchid from #matches)
and b.currency<>20
and ruben = 1
AND statusID IN(111, 112, 113)
--and ag.site='789y'
--and bettype=3


--select * from #matches where 
--(home like '%vietnam%' and awayteam like '%china%')
--or  (awayteam like '%vietnam%' and home like '%china%')


-- drop table #MatchData
select b.winlostdate, 
	m.matchid, m.home, m.awayteam, 
	count(distinct b.custid) activeMember,
	sum(abs(stake * actualrate)) Stake, 
	SUM((winlost-actual_stake)*actualrate) WinlossP,
	COUNT(1) betcount,
	-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm - (CASE
                                                                                WHEN tpositiontaking = 1
                                                                                THEN 0
                                                                                ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
                                                                            END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * actualrate) AS RealIncome,
	-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost - CASE
																		WHEN tpositiontaking = 1
																		THEN 0
																		ELSE(winlost - actual_stake) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)
																	END) * virtualrate + (scomm - (CASE
																									WHEN tpositiontaking = 1
																									THEN 0
																									ELSE b.scomm / (1 - b.tpositiontaking)
																								END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * actualrate 
																									* CASE
																										WHEN virtualrate < actualrate
																										THEN virtualrate / actualrate
																										ELSE 1
																								END) VirtualIncome, 
	-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost - CASE
        WHEN tpositiontaking = 1
        THEN 0
        ELSE(winlost - actual_stake) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)
    END + CASE
            WHEN virtualrate < actualrate
            THEN(b.scomm - (CASE
                                WHEN tpositiontaking = 1
                                THEN 0
                                ELSE b.scomm / (1 - b.tpositiontaking)
                            END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0))
            ELSE 0
        END) * (actualrate - virtualrate)) VarianceIncome, 
                      SUM(CASE
                              WHEN tpositiontaking = 1
                              THEN 0
                              ELSE(1 - b.tpositiontaking - ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * ABS(b.stake) * CASE
                                                                                                      WHEN virtualrate > actualrate
                                                                                                      THEN virtualrate
                                                                                                      ELSE actualrate
                                                                                                  END
                          END) AS RealTurnover, 
                      SUM(CASE
                              WHEN tpositiontaking = 1
                              THEN 0
                              ELSE(1 - b.tpositiontaking - ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * ABS(b.stake) * virtualrate
                          END) AS VirtualTurnover
into #MatchData
from #rawdata b join #matches m on m.matchid=b.matchid
where  ruben = 1
       AND statusID IN(111, 112, 113)
	   --and liveindicator=1
group by b.winlostdate, m.matchid, m.home, m.awayteam
order by WinlossP desc


select m.ko,m.leaguename, d.* 
from #MatchData d join #matches m on m.matchid=d.matchid
--where RealIncome <0
order by m.ko


--select count(distinct custid) from #rawdata


--select count(1),sum(RealIncome)RealIncome, sum(m.RealTurnover) RealTurnover, sum(RealIncome)/sum(m.RealTurnover) margin 
--from #MatchData m
--where RealIncome >0


--select count(1),sum(RealIncome), sum(m.RealTurnover), sum(RealIncome)/sum(m.RealTurnover) 
--from #MatchData m
--where RealIncome <0


select winlostdate, count(1) NoOfMatch, 
	sum(m.Stake) Stake,
	sum(m.Stake)/ count(1) AVG_StakePerMatch,
	sum(m.betcount) betcount,
	sum(m.betcount)/ count(1) AVG_betcountPerMatch,
	sum(m.RealTurnover) RealTurnover,
	sum(m.RealTurnover)/ count(1) AVG_HouseTOPerMatch,
	sum(m.RealIncome) RealIncome,
	sum(m.RealIncome)/ count(1) AVG_RealIncomePerMatch,
	sum(m.activeMember)/ count(1) AVG_ActiveMemberPerMatch,
	sum(m.RealIncome)/sum(m.RealTurnover) Margin

from #MatchData m
group by winlostdate
order by winlostdate

--site

select b.site,
	--m.matchid, m.home, m.awayteam, 
	count(distinct b.custid) activeMember,
	sum(abs(stake * actualrate)) Stake, 
	SUM((winlost-actual_stake)*actualrate) WinlossP,
	COUNT(1) betcount,
	-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm - (CASE WHEN tpositiontaking = 1
                                                                            THEN 0
                                                                            ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
                                                                        END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * actualrate) AS RealIncome,
	-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost - CASE
                                                                        WHEN tpositiontaking = 1
                                                                        THEN 0
                                                                        ELSE(winlost - actual_stake) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)
                                                                    END) * virtualrate + (scomm - (CASE
                                                                                                    WHEN tpositiontaking = 1
                                                                                                    THEN 0
                                                                                                    ELSE b.scomm / (1 - b.tpositiontaking)
                                                                                                END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * actualrate 
																									* CASE
																										WHEN virtualrate < actualrate
																										THEN virtualrate / actualrate
																										ELSE 1
																										END) VirtualIncome, 
		-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost - CASE
            WHEN tpositiontaking = 1
            THEN 0
            ELSE(winlost - actual_stake) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)
        END + CASE
                WHEN virtualrate < actualrate
                THEN(b.scomm - (CASE
                                    WHEN tpositiontaking = 1
                                    THEN 0
                                    ELSE b.scomm / (1 - b.tpositiontaking)
                                END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0))
                ELSE 0
            END) * (actualrate - virtualrate)) VarianceIncome, 
            SUM(CASE
                    WHEN tpositiontaking = 1
                    THEN 0
                    ELSE(1 - b.tpositiontaking - ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * ABS(b.stake) * CASE
                                                                                            WHEN virtualrate > actualrate
                                                                                            THEN virtualrate
                                                                                            ELSE actualrate
                                                                                        END
                END) AS RealTurnover, 
            SUM(CASE
                    WHEN tpositiontaking = 1
                    THEN 0
                    ELSE(1 - b.tpositiontaking - ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * ABS(b.stake) * virtualrate
                END) AS VirtualTurnover

from #rawdata b join #matches m on m.matchid=b.matchid
where  ruben = 1
       AND statusID IN(111, 112, 113)
	   --and liveindicator=1
group by b.site
	--,m.matchid, m.home, m.awayteam
order by RealTurnover desc
-----
--bettype
select d.bettype, b.typenamee,
	sum(abs(stake * actualrate)) Stake, 
	SUM((winlost-actual_stake)*actualrate) WinlossP,
	-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm - (CASE
                                                                                                  WHEN tpositiontaking = 1
                                                                                                  THEN 0
                                                                                                  ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
                                                                                              END) * ISNULL(epositiontaking, 0)) * actualrate) AS RealIncome 
from #rawdata d join bettype b on b.typeid=d.bettype
where 
 ruben = 1
       AND statusID IN(111, 112, 113)

group by d.bettype, b.typenamee
order by WinlossP desc
--order by RealIncome asc


select b.liveindicator,count(1) betcount,
	sum(abs(stake * actualrate)) Stake, 
	SUM((winlost-actual_stake)*actualrate) WinlossP,
	-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm - (CASE
                                                                                                  WHEN tpositiontaking = 1
                                                                                                  THEN 0
                                                                                                  ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
                                                                                              END) * ISNULL(epositiontaking, 0)) * actualrate) AS RealIncome ,
	 SUM(CASE
                              WHEN tpositiontaking = 1
                              THEN 0
                              ELSE(1 - b.tpositiontaking - ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * ABS(b.stake) * CASE
                                                                                                      WHEN virtualrate > actualrate
                                                                                                      THEN virtualrate
                                                                                                      ELSE actualrate
                                                                                                  END
                          END) AS RealTurnover
from #rawdata b
where 
 ruben = 1
       AND statusID IN(111, 112, 113)

group by  b.liveindicator
--order by WinlossP desc
order by RealIncome asc

select b.bettype, bt.typenamee, b.liveindicator,
	sum(abs(stake * actualrate)) Stake, 
	SUM((winlost-actual_stake)*actualrate) WinlossP,
	-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm - (CASE
                                                                                                  WHEN tpositiontaking = 1
                                                                                                  THEN 0
                                                                                                  ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
                                                                                              END) * ISNULL(epositiontaking, 0)) * actualrate) AS RealIncome ,
 SUM(CASE
                              WHEN tpositiontaking = 1
                              THEN 0
                              ELSE(1 - b.tpositiontaking - ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * ABS(b.stake) * CASE
                                                                                                      WHEN virtualrate > actualrate
                                                                                                      THEN virtualrate
                                                                                                      ELSE actualrate
                                                                                                  END
                          END) AS RealTurnover
	-- -SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm ) * actualrate) AS RealIncome1 
from #rawdata b join bettype bt on bt.typeid=b.bettype
where 
 ruben = 1
       AND statusID IN(111, 112, 113)

group by b.bettype, bt.typenamee, b.liveindicator
--order by WinlossP desc
order by  RealIncome asc

--hour bet
select cast(transdate as Date) transdate, 
	DATEPART(hh,transdate) Hourbet,
	
	count(1) betcount,
	sum(abs(stake * actualrate)) Stake, 
	SUM((winlost-actual_stake)*actualrate) WinlossP,
	-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm - (CASE
                                                                                                  WHEN tpositiontaking = 1
                                                                                                  THEN 0
                                                                                                  ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
                                                                                              END) * ISNULL(epositiontaking, 0)) * actualrate) AS RealIncome ,
	 SUM(CASE
                              WHEN tpositiontaking = 1
                              THEN 0
                              ELSE(1 - b.tpositiontaking - ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * ABS(b.stake) * CASE
                                                                                                      WHEN virtualrate > actualrate
                                                                                                      THEN virtualrate
                                                                                                      ELSE actualrate
                                                                                                  END
                          END) AS RealTurnover
from #rawdata b
where 
 ruben = 1
       AND statusID IN(111, 112, 113)

group by  cast(transdate as Date), 
	DATEPART(hh,transdate) 
--order by WinlossP desc
order by cast(transdate as Date), DATEPART(hh,transdate)  asc

/*
--over under betchoice
select --d.transdate, liveindicator, transid, username,
	bettype, case when betteam='h' then 'Over' else 'Under' end Betchoice, 
	--hdp1,-- hdp2, livehomescore, livehomescore,
	--odds,
	sum(abs(stake * actualrate)) Stake,
	sum((winlost-actual_stake)*actualrate) WinlossP,
	sum(-((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm 
			- (CASE
					WHEN tpositiontaking = 1
					THEN 0
					ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
				END) * ISNULL(epositiontaking, 0)) * actualrate)) AS RealIncome ,
	-sum((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm ) * actualrate) AS RealIncome1 
from #rawdata d 
where --
--d.matchid = 35371213
 ruben = 1
AND statusID IN(111, 112, 113)
and bettype in (3,8)
and liveindicator=1
group by bettype, case when betteam='h' then 'Over' else 'Under'  end
order by  WinlossP desc


-- Handicap betchoice

select --d.transdate, liveindicator, transid, username,
	bettype, case when betteam='h' then 'Home' else 'Away' end Betchoice, 
	--hdp2 - hdp1 handicap, livehomescore, livehomescore,
	--odds,
	sum(abs(stake * actualrate)) Stake,
	sum((winlost-actual_stake)*actualrate) WinlossP,
	sum(-((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm 
			- (CASE
					WHEN tpositiontaking = 1
					THEN 0
					ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
				END) * ISNULL(epositiontaking, 0)) * actualrate)) AS RealIncome ,
	-sum((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm ) * actualrate) AS RealIncome1 
from #rawdata d 
where --
--d.matchid = 35371213
 ruben = 1
AND statusID IN(111, 112, 113)
and bettype in (1,7)
and liveindicator=1
group by bettype, case when betteam='h' then 'Home' else 'Away' end 
order by  WinlossP desc


--punter: overall
select --d.transdate, liveindicator, transid, username,
	count(1) betcount,
	sum(abs(stake * actualrate)) Stake,
	sum((winlost-actual_stake)*actualrate) WinlossP,
	sum(abs(stake * actualrate))/count(1) AVG_Stake,
	sum(abs(stake * actualrate))/count(distinct m.matchID) AVG_StakePerMatch,
	sum(-((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm 
			- (CASE
					WHEN tpositiontaking = 1
					THEN 0
					ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
				END) * ISNULL(epositiontaking, 0)) * actualrate)) AS RealIncome
from #rawdata b join #matches m on m.matchid = b.matchid
where --
b.custid = 41445686
and ruben = 1
AND statusID IN(111, 112, 113)
--and bettype in (1,7)
--and liveindicator=1

--customer betchoice

select --d.transdate, liveindicator, transid, username,
	b.matchid, liveindicator, datediff(mi,m.ko, transdate) minFromKO, 
	m.home, m.awayteam, finalhomescore,finalawayscore, hthomescore, htawayscore, 
	bettype, 
	case when bettype in (1,7) and betteam='h' then 'Home' 
		when bettype in (1,7) and betteam='a'then 'Away'
		when bettype in (3,8) and betteam='h' then 'Over'
		when bettype in (3,8) and betteam='a' then 'Under'
		else betteam end Betchoice, 
	--betteam, 
	case when bettype in (3,8) then hdp1
	else hdp2-hdp1 end HDP, 
	livehomescore, livehomescore,
	odds,
	count(1) betcount,
	sum(abs(stake * actualrate)) Stake,
	sum((winlost-actual_stake)*actualrate) WinlossP,
	sum(-((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm 
			- (CASE
					WHEN tpositiontaking = 1
					THEN 0
					ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
				END) * ISNULL(epositiontaking, 0)) * actualrate)) AS RealIncome ,
	-sum((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm ) * actualrate) AS RealIncome1 
from #rawdata b join #matches m on m.matchid = b.matchid
where --
b.custid = 41445686
and ruben = 1
AND statusID IN(111, 112, 113)
--and bettype in (1,7)
--and liveindicator=1
group by b.matchid, liveindicator, datediff(mi,m.ko, transdate) , 
	m.home, m.awayteam, finalhomescore,finalawayscore, hthomescore, htawayscore, 
	bettype, case when bettype in (1,7) and betteam='h' then 'Home' 
		when bettype in (1,7) and betteam='a'then 'Away'
		when bettype in (3,8) and betteam='h' then 'Over'
		when bettype in (3,8) and betteam='a' then 'Under'
		else betteam end , 	 
	case when bettype in (3,8) 
	then hdp1
	else hdp2-hdp1 end ,
	livehomescore, livehomescore,
	odds
order by  b.matchid, bettype, hdp  desc,Betchoice

--punter: favorite betchoice
select 
	bettype, 
	case when bettype in (1,7) and betteam='h' then 'Home' 
		when bettype in (1,7) and betteam='a'then 'Away'
		when bettype in (3,8) and betteam='h' then 'Over'
		when bettype in (3,8) and betteam='a' then 'Under'
		else betteam end Betchoice, 
	--betteam, 
	--case when bettype in (3,8) then hdp1
	--else hdp2-hdp1 end HDP, 
	--livehomescore, livehomescore,
	--odds,
	count(1) betcount,
	sum(abs(stake * actualrate)) Stake,
	sum((winlost-actual_stake)*actualrate) WinlossP,
	sum(-((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm 
			- (CASE
					WHEN tpositiontaking = 1
					THEN 0
					ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
				END) * ISNULL(epositiontaking, 0)) * actualrate)) AS RealIncome ,
	-sum((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm ) * actualrate) AS RealIncome1 
from #rawdata b join #matches m on m.matchid = b.matchid
where --
b.custid = 41445686
and ruben = 1
AND statusID IN(111, 112, 113)
--and bettype in (1,7)
--and liveindicator=1
group by
	bettype, case when bettype in (1,7) and betteam='h' then 'Home' 
		when bettype in (1,7) and betteam='a'then 'Away'
		when bettype in (3,8) and betteam='h' then 'Over'
		when bettype in (3,8) and betteam='a' then 'Under'
		else betteam end  	 
	--case when bettype in (3,8) 
	--then hdp1
	--else hdp2-hdp1 end
order by  Stake  desc
*/

/*
-- score distribution
select (finalhomescore+finalawayscore) totalScore, count(1) NoOfMatch
from #matches
group by (finalhomescore+finalawayscore)
order by totalScore

--match: betchoice detail
select  b.matchid, datediff(mi,m.ko, transdate) minFromKO,  m.home, m.awayteam, finalawayscore, finalhomescore, htawayscore, 
	bettype, odds, b.livehomescore,b.liveawayscore,
	case when bettype in (1,7) and betteam='h' then 'Home' 
		when bettype in (1,7) and betteam='a'then 'Away'
		when bettype in (3,8) and betteam='h' then 'Over'
		when bettype in (3,8) and betteam='a' then 'Under'
		else betteam end betchoice, 
	case when bettype in (3,8) then hdp1
	else hdp2-hdp1 end HDP, 
	count(1) betcount,
	sum(abs(stake * actualrate)) Stake,
	sum((winlost-actual_stake)*actualrate) WinlossP,
	sum(-((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm 
			- (CASE
					WHEN tpositiontaking = 1
					THEN 0
					ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
				END) * ISNULL(epositiontaking, 0)) * actualrate)) AS RealIncome 
	 from #rawdata b join #matches m on m.matchid = b.matchid
	 where bettype=3
	 and b.matchid= 34624258
	 group by  b.matchid, datediff(mi,m.ko, transdate) ,  m.home, m.awayteam, finalawayscore, finalhomescore, htawayscore, 
	bettype, odds,b.livehomescore,b.liveawayscore,
	case when bettype in (1,7) and betteam='h' then 'Home' 
		when bettype in (1,7) and betteam='a'then 'Away'
		when bettype in (3,8) and betteam='h' then 'Over'
		when bettype in (3,8) and betteam='a' then 'Under'
		else betteam end , 
	betteam, 
	case when bettype in (3,8) then hdp1
	else hdp2-hdp1 end 
	
	order by matchid, minFromKO, betchoice, livehomescore-liveawayscore,  HDP ,odds
*/

