use bodb_Account
go
--select @rptDate 
DECLARE @FromDate AS DATE,
		@ToDate AS DATE,
		@sporttype int=1

select @FromDate = '2020/01/01'
	, @ToDate ='2020/02/01'

/*
--  drop table #match
select * 
into #match
from (
	select  m.eventdate, m.matchid, l.leagueid, h.teamname home, a.teamname away
		from bodb_Account.dbo.match m(nolock) 
		left join bodb02.dbo.League l (nolock) on m.leagueid=l.leagueid
		left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
		left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
	where 
		m.sporttype=1
		and eventdate between @FromDate and @ToDate
		--and (l.leaguename like 'Virtual%' 
		--	or l.leaguename like 'SABA Virtual%')
		--and isnull(l.LeagueGroupID,0) = 42
	
	UNION 

	select  m.eventdate, m.matchid, l.leagueid, h.teamname home, a.teamname away
	from bodb_Archive.dbo.match m(nolock) 
	left join bodb02.dbo.League l (nolock) on m.leagueid=l.leagueid
	left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
	left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
	where 
		l.sporttype=1
		and eventdate between @FromDate and @ToDate
		--and (l.leaguename like 'Virtual%' 
		--	or l.leaguename like 'SABA Virtual%')
		--and isnull(l.LeagueGroupID,0) = 42
	)t

select * from #match
*/

select * 
into #rawData
from 
	FactSportbookHourly (nolock)
where rptdate >= @FromDate and rptdate <= @ToDate
and CurrencyID<>20
and TicketStatus <>14
--and matchid in (select matchid from #match)
and bettype in (select bettype from Product_Bettype where ProductID = 1) --SB
and SportType=@sporttype and bettype not in (9,29)

--overall
select b.[Hour] HourBet,
	--count(Distinct custid) activeMember,
	SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake * c.Rate END)  [MemberTurnover]
	  -- Member Winloss
      ,SUM(b.WinlossP * c.Rate) [MemberWinloss]
	  -- Company Real Turnover
	  ,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate
			END) [CompanyRealTurnover]
			-- Company Real Income
	  ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * c.Rate ) [CompanyRealIncome]
	   -- Commission
	   ,-SUM(b.CommissionS * c.Rate) [Commission]
	   -- Company Virtual Turnover 
	   ,SUM(CASE WHEN b.bettype IN (71,73) THEN  0
				 ELSE (CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * c.Rate
			END) [CompanyVirtualTurnover]
	   -- Company Virtual Winloss
	   ,SUM(
	         -((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
					 + (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)) * c.Rate 
			) [CompanyVirtualWinloss]
		-- Variance Income
		,SUM((b.WinlossIBC - b.ExtraWL
								+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * c.Rate) [VarianceIncome]
        -- Variance Turnover
		,SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * c.Rate) [VarianceTurnover]
		-- Betcount
		,SUM(CASE WHEN b.BetType = 500 THEN 0 ELSE b.BetCount END) [Betcount]
		-- Company Real Turnover_No Draw
		,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			  (CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate *
			  (CASE WHEN b.TicketStatus = 3 THEN 0 
					WHEN b.TicketStatus in (12,13) THEN 0.5 
					ELSE 1 
			   END) ) [CompanyRealTurnover_NoDraw]
		-- Company Virtual Turnover_No Draw
		,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * c.Rate *
			  (CASE WHEN b.TicketStatus=3 THEN 0 
					WHEN b.TicketStatus in (12,13) THEN 0.5 
					ELSE 1 
				END) ) [CompanyVirtualTurnover_NoDraw]
from #rawData b
 LEFT JOIN bodb_Account.dbo.tbl_Currency_Daily c WITH (NOLOCK) ON b.rptDate = c.ExchangeDate AND b.CurrencyID = c.Currency
group by b.[Hour] 
order by b.[Hour] 