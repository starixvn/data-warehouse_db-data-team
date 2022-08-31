-- run on DBDW2/bodb_Account

/*	Created by: Dan
	Task: top Licensee by TO and group performance for Saba soccer 
			use for Lettalk report adhoc
	DB: DBWH/bodb_Account	

Revisions:

*/
use bodb_Account
go
DECLARE @rptDate AS date = cast( (getdate() -1) as date) --yesterday

--select @rptDate 
DECLARE @FromDate AS DATE,
		@ToDate AS DATE

select @FromDate = DATEADD(month, DATEDIFF(month, 0, @rptDate), 0) -- StartOfMonth	
	, @ToDate =DATEADD(d, -1, DATEADD(m, DATEDIFF(m, 0, @rptDate) + 1, 0)) --end of month


select * 
into #matchVirtual
from (
	select  m.eventdate, m.matchid
		from bodb_Account.dbo.match m(nolock) 
		left join bodb02.dbo.League l (nolock) on m.leagueid=l.leagueid
		left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
		left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
	where 
		m.sporttype=1
		and eventdate between @FromDate and @ToDate
		--and (l.leaguename like 'Virtual%' 
		--	or l.leaguename like 'SABA Virtual%')
		and isnull(l.LeagueGroupID,0) = 42
	
	UNION 

	select  m.eventdate, m.matchid
	from bodb_Archive.dbo.match m(nolock) 
	left join bodb02.dbo.League l (nolock) on m.leagueid=l.leagueid
	left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
	left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
	where 
		l.sporttype=1
		and eventdate between @FromDate and @ToDate
		--and (l.leaguename like 'Virtual%' 
		--	or l.leaguename like 'SABA Virtual%')
		and isnull(l.LeagueGroupID,0) = 42
	)t

-- select * from #matchVirtual where finalhomescore is not null

select @rptDate, @FromDate, @ToDate


CREATE TABLE #tmpSite_MTD_SB
(
	site VARCHAR(100),
	isDeposit bit,
	sporttype INT,
	HouseTO decimal(19,4),
	HouseIncome decimal(19,4)
)

CREATE TABLE #tmpSite_Yesterday_SB
(
	site VARCHAR(100),
	isDeposit bit,
	sporttype INT,
	HouseTO decimal(19,4),
	HouseIncome decimal(19,4)
)

CREATE TABLE #tmpLicensee_MTD_SB
(
	SiteID INT,
	site VARCHAR(100),
	sporttype INT,
	LicTO decimal(19,4),
	LicWinloss decimal(19,4),
	RankTO int
)

CREATE TABLE #tmpLicensee_Yesterday_SB
(
	SiteID INT,
	site VARCHAR(100),
	sporttype INT,
	LicTO decimal(19,4),
	LicWinloss decimal(19,4)
)

---------------------	
truncate table #tmpSite_MTD_SB
truncate table #tmpSite_Yesterday_SB
truncate table #tmpLicensee_Yesterday_SB
truncate table #tmpLicensee_MTD_SB
----------------------------------------------------------	
--Section 1: Yesterday
--ALL GROUPS - HOUSE VIEW 
	
insert into #tmpSite_MTD_SB
(
	[Site],isDeposit, sporttype, HouseTO,HouseIncome
)
SELECT 
	s.site	[Site], 
	s.isDeposit,
	case when bettype in (9,29) then -2 else t.SportType end sporttype,
	SUM(CASE WHEN TicketStatus=3 THEN 0 
		WHEN TicketStatus in (12,13) THEN 0.5 
		ELSE 1
	end 
		*  (CASE WHEN t.TurnoverIBC=0 THEN 0 ELSE t.TurnoverIBC - t.ExtraTO END) *
				(CASE WHEN t.VarianceVR > 0 THEN (t.VarianceVR + 1) ELSE 1 END)  
			
		* e.Rate) HouseTO,
	SUM(-(t.WinlossIBC - t.ExtraWL + t.CommissionS - t.ExtraComm) * e.Rate) HouseIncome	
from FactSiteWinloss t with(nolock)
	inner join tbl_Site s with(nolock) on t.SiteID = s.siteid
	inner join tbl_Currency_Daily e with(nolock) on t.RptDate = e.ExchangeDate and e.Currency=t.CurrencyID
WHERE 	
	t.RptDate between @FromDate and @ToDate
	AND t.TicketStatus NOT IN (14)    -- exclude refund
	AND t.CurrencyID <> 20	
	AND t.BetType in (select bettype from Product_Bettype where ProductID = 1) --SB	
	AND matchid in (select matchid from #matchVirtual)
group by 
	s.site	, s.isDeposit,
	case when bettype in (9,29) then -2 else t.SportType end 

	
insert into #tmpSite_Yesterday_SB
(
	[Site], isDeposit, sporttype, HouseTO, HouseIncome
)
select s.site [Site], 
	s.isDeposit,
	case when bettype in (9,29) then -2 else t.SportType end sporttype,
	sum(CASE WHEN TicketStatus=3 THEN 0 
			WHEN TicketStatus in (12,13) THEN 0.5 
			ELSE 1
		end 
			*  (CASE WHEN t.TurnoverIBC=0 THEN 0 ELSE t.TurnoverIBC - t.ExtraTO END) *
					(CASE WHEN t.VarianceVR > 0 THEN (t.VarianceVR + 1) ELSE 1 END)  
			
			* e.Rate) HouseTO,
	SUM(-(t.WinlossIBC - t.ExtraWL + t.CommissionS - t.ExtraComm) * e.Rate) HouseIncome	
from FactSiteWinloss t with(nolock)
	inner join tbl_Site s with(nolock) on t.SiteID = s.siteid
	inner join tbl_Currency_Daily e with(nolock) on t.RptDate = e.ExchangeDate and e.Currency=t.CurrencyID
WHERE 	
	t.RptDate = @rptDate
	AND t.TicketStatus NOT IN (14)    -- exclude refund
	AND t.CurrencyID <> 20	
	AND t.BetType in (select bettype from Product_Bettype where ProductID = 1) --SB
	AND matchid in (select matchid from #matchVirtual)
group by 
	s.site	, s.isDeposit,
	case when bettype in (9,29) then -2 else t.SportType end 


--licencee data
INSERT INTO #tmpLicensee_MTD_SB
	(SiteID,site, sporttype, LicTO, LicWinloss, RankTO)
	select 
		t.SiteID,
		s.site, 
		case when bettype in (9,29) then -2 else t.SportType end sporttype,	
		sum(CASE WHEN TicketStatus=3 THEN 0 
				WHEN TicketStatus in (12,13) THEN 0.5 
				ELSE 1
				end *  t.MemberTurnover*e.Rate) LicTO,
		-sum(MemberWinloss*e.rate) LicWinloss,
		RANK() OVER (
			order by 
				sum(CASE WHEN TicketStatus=3 THEN 0 
				WHEN TicketStatus in (12,13) THEN 0.5 
				ELSE 1
				end *  t.MemberTurnover*e.Rate) desc, 
				t.siteid
		) RankTO
	
	from FactLADailyWinloss t with(nolock)
		inner join tbl_Site s with(nolock) on t.SiteID = s.siteid
		inner join tbl_Currency_Daily e with(nolock) on t.RptDate = e.ExchangeDate and e.Currency=t.CurrencyID
	WHERE s.isDeposit = 1
		AND t.RptDate between @FromDate and @ToDate
		AND t.TicketStatus NOT IN (14)    -- exclude refund
		AND t.CurrencyID <> 20	
		AND ProductID= 10001 --SB
		AND matchid in (select matchid from #matchVirtual)
	group by 
		t.SiteID,
		s.site ,
		case when bettype in (9,29) then -2 else t.SportType end 
	order by LicTO desc

INSERT INTO #tmpLicensee_Yesterday_SB
	(SiteID,site, sporttype, LicTO, LicWinloss)
	select 
		t.SiteID,
		s.site, 
		case when bettype in (9,29) then -2 else t.SportType end sporttype,	
		sum(CASE WHEN TicketStatus=3 THEN 0 
				WHEN TicketStatus in (12,13) THEN 0.5 
				ELSE 1
				end *  t.MemberTurnover*e.Rate) LicTO,
		-sum(MemberWinloss*e.rate) LicWinloss
	
	from FactLADailyWinloss t with(nolock)
		inner join tbl_Site s with(nolock) on t.SiteID = s.siteid
		inner join tbl_Currency_Daily e with(nolock) on t.RptDate = e.ExchangeDate and e.Currency=t.CurrencyID
	WHERE s.isDeposit = 1
		AND t.RptDate = @rptDate
		AND t.TicketStatus NOT IN (14)    -- exclude refund
		AND t.CurrencyID <> 20	
		AND ProductID= 10001 --SB
		AND matchid in (select matchid from #matchVirtual)
	group by 
		t.SiteID,
		s.site ,
		case when bettype in (9,29) then -2 else t.SportType end
	order by LicTO desc

-- GROUP PERFORMANCE 	
;WITH YesterdayData_CTE (site,HouseTO, HouseWinloss, Margin, OrderBy)
AS
(
	SELECT t.Site,
		t.HouseTO,
		t.HouseIncome,
		CASE WHEN t.HouseTO = 0 then 0 else t.HouseIncome/t.HouseTO end Margin,
		OrderBy
	FROM (
		SELECT CASE 
					WHEN t1.isDeposit=1 THEN 'Licensee'
					WHEN t1.site= '789Y' THEN '789Y'
					WHEN t1.site in ( 'XYZBET', 'BEST-ODDS') THEN 'XYZ & Bestodds'
					WHEN t1.site= '611111' THEN '611 (China)'
					WHEN t1.site= '733333' THEN '733 (Malaysia)'
					WHEN t1.site= '755555' THEN '755 (Thailand)'
					WHEN t1.site= 'INDO' THEN 'Indo'
					WHEN t1.isDeposit=0 and t1.site not in ('789Y','XYZBET', 'BEST-ODDS', '611111','733333','755555','INDO','CN88') THEN 'Other MBC'		
					WHEN t1.site= 'CN88' THEN 'CN88'		
				END	SITE,				
			CASE 
				WHEN t1.isDeposit=1 THEN 1
				WHEN t1.site= '789Y' THEN 2
				WHEN t1.site in ( 'XYZBET', 'BEST-ODDS') THEN 3
				WHEN t1.site= '611111' THEN 4
				WHEN t1.site= '733333' THEN 5
				WHEN t1.site= '755555' THEN 6
				WHEN t1.site= 'INDO' THEN 7
				WHEN t1.isDeposit=0 and t1.site not in ('789Y','XYZBET', 'BEST-ODDS', '611111','733333','755555','INDO','CN88') THEN 8		
				WHEN t1.site= 'CN88' THEN 10								
			END OrderBy,
			sum(isnull(t1.HouseTO,0)) HouseTO,
			sum(isnull(t1.HouseIncome,0)) HouseIncome
		FROM  
			#tmpSite_Yesterday_SB t1
		GROUP BY  CASE 
					WHEN t1.isDeposit=1 THEN 'Licensee'
					WHEN t1.site= '789Y' THEN '789Y'
					WHEN t1.site in ( 'XYZBET', 'BEST-ODDS') THEN 'XYZ & Bestodds'
					WHEN t1.site= '611111' THEN '611 (China)'
					WHEN t1.site= '733333' THEN '733 (Malaysia)'
					WHEN t1.site= '755555' THEN '755 (Thailand)'
					WHEN t1.site= 'INDO' THEN 'Indo'
					WHEN t1.isDeposit=0 and t1.site not in ('789Y','XYZBET', 'BEST-ODDS', '611111','733333','755555','INDO','CN88') THEN 'Other MBC'		
					WHEN t1.site= 'CN88' THEN 'CN88'		
				END,
			CASE 
				WHEN t1.isDeposit=1 THEN 1
				WHEN t1.site= '789Y' THEN 2
				WHEN t1.site in ( 'XYZBET', 'BEST-ODDS') THEN 3
				WHEN t1.site= '611111' THEN 4
				WHEN t1.site= '733333' THEN 5
				WHEN t1.site= '755555' THEN 6
				WHEN t1.site= 'INDO' THEN 7
				WHEN t1.isDeposit=0 and t1.site not in ('789Y','XYZBET', 'BEST-ODDS', '611111','733333','755555','INDO','CN88') THEN 8		
				WHEN t1.site= 'CN88' THEN 10								
			END
	
		UNION ALL

		SELECT 	
			'ALL(w/o CN88)'	Licensee,
			9 OrderBy,
			sum(isnull(t1.HouseTO,0)) HouseTO,
			sum(isnull(t1.HouseIncome,0)) HouseIncome
		FROM  
			#tmpSite_Yesterday_SB t1
		where t1.site <> 'CN88'	
	) t
)
,MTD_CTE (site,HouseTO, HouseWinloss, Margin,OrderBy)
AS
(
	SELECT t.Site,
		t.HouseTO,
		t.HouseIncome,
		CASE WHEN t.HouseTO = 0 then 0 else t.HouseIncome/t.HouseTO end Margin,
		OrderBy
	FROM (
		SELECT CASE 
					WHEN t1.isDeposit=1 THEN 'Licensee'
					WHEN t1.site= '789Y' THEN '789Y'
					WHEN t1.site in ( 'XYZBET', 'BEST-ODDS') THEN 'XYZ & Bestodds'
					WHEN t1.site= '611111' THEN '611 (China)'
					WHEN t1.site= '733333' THEN '733 (Malaysia)'
					WHEN t1.site= '755555' THEN '755 (Thailand)'
					WHEN t1.site= 'INDO' THEN 'Indo'
					WHEN t1.isDeposit=0 and t1.site not in ('789Y','XYZBET', 'BEST-ODDS', '611111','733333','755555','INDO','CN88') THEN 'Other MBC'		
					WHEN t1.site= 'CN88' THEN 'CN88'		
				END	SITE,				
			CASE 
				WHEN t1.isDeposit=1 THEN 1
				WHEN t1.site= '789Y' THEN 2
				WHEN t1.site in ( 'XYZBET', 'BEST-ODDS') THEN 3
				WHEN t1.site= '611111' THEN 4
				WHEN t1.site= '733333' THEN 5
				WHEN t1.site= '755555' THEN 6
				WHEN t1.site= 'INDO' THEN 7
				WHEN t1.isDeposit=0 and t1.site not in ('789Y','XYZBET', 'BEST-ODDS', '611111','733333','755555','INDO','CN88') THEN 8		
				WHEN t1.site= 'CN88' THEN 10								
			END OrderBy,
			sum(isnull(t1.HouseTO,0)) HouseTO,
			sum(isnull(t1.HouseIncome,0)) HouseIncome
		FROM  
			#tmpSite_MTD_SB t1
		GROUP BY  CASE 
					WHEN t1.isDeposit=1 THEN 'Licensee'
					WHEN t1.site= '789Y' THEN '789Y'
					WHEN t1.site in ( 'XYZBET', 'BEST-ODDS') THEN 'XYZ & Bestodds'
					WHEN t1.site= '611111' THEN '611 (China)'
					WHEN t1.site= '733333' THEN '733 (Malaysia)'
					WHEN t1.site= '755555' THEN '755 (Thailand)'
					WHEN t1.site= 'INDO' THEN 'Indo'
					WHEN t1.isDeposit=0 and t1.site not in ('789Y','XYZBET', 'BEST-ODDS', '611111','733333','755555','INDO','CN88') THEN 'Other MBC'		
					WHEN t1.site= 'CN88' THEN 'CN88'		
				END,
			CASE 
				WHEN t1.isDeposit=1 THEN 1
				WHEN t1.site= '789Y' THEN 2
				WHEN t1.site in ( 'XYZBET', 'BEST-ODDS') THEN 3
				WHEN t1.site= '611111' THEN 4
				WHEN t1.site= '733333' THEN 5
				WHEN t1.site= '755555' THEN 6
				WHEN t1.site= 'INDO' THEN 7
				WHEN t1.isDeposit=0 and t1.site not in ('789Y','XYZBET', 'BEST-ODDS', '611111','733333','755555','INDO','CN88') THEN 8		
				WHEN t1.site= 'CN88' THEN 10								
			END
	
		UNION ALL

		SELECT 	
			'ALL(w/o CN88)'	Licensee,
			9 OrderBy,
			sum(isnull(t1.HouseTO,0)) HouseTO,
			sum(isnull(t1.HouseIncome,0)) HouseIncome
		FROM  
			#tmpSite_MTD_SB t1
		where t1.site <> 'CN88'	
	) t
)


select t1.site, 
	t2.HouseTO, t2.HouseWinloss, t2.Margin , --yesterday
	t1.HouseTO, t1.HouseWinloss, t1.Margin  --MTD
from MTD_CTE t1 left join YesterdayData_CTE t2 on t1.site=t2.Site
ORDER BY t1.OrderBy

--LICENSEE
SELECT 
	CASE WHEN T.RankTO <= 50 THEN t.site 
		WHEN t.site = 'All Licensees' THEN 'All Licensees'
			ELSE 'Other Licensees'
			end  as Licensee,
	SUM(t.LicTO_Yesterday) LicTO_Yesterday,
	CASE WHEN sum(t.LicTO_Yesterday) = 0 then 0 else sum(t.LicWinloss_Yesterday)/sum(t.LicTO_Yesterday) end Margin_Yesterday,
	SUM(t.LicTO_MTD) LicTO_MTD,
	CASE WHEN sum(t.LicTO_MTD) = 0 then 0 else sum(t.LicWinloss_MTD)/sum(t.LicTO_MTD) end Margin_MTD
FROM (
	SELECT 
		t1.site SITE,
		RANK() OVER (
			order by 
				sum(t1.LicTO) desc, 
				sum(t2.LicTO) desc
		) RankTO,
		sum(isnull(t1.LicTO,0)) LicTO_MTD,
		sum(isnull(t1.LicWinloss,0)) LicWinloss_MTD,
		sum(isnull(t2.LicTO,0)) LicTO_Yesterday,
		sum(isnull(t2.LicWinloss,0)) LicWinloss_Yesterday
		
	FROM  
		#tmpLicensee_MTD_SB t1
		right join #tmpLicensee_Yesterday_SB t2 on t1.site=t2.site and t1.sporttype=t2.sporttype
	group by t1.site 

	UNION ALL
	SELECT 	
		'All Licensees'	Licensee,			
		MAX(t1.RankTO)+1 AS RankTO ,
		sum(isnull(t1.LicTO,0)) LicTO_MTD,
		sum(isnull(t1.LicWinloss,0)) LicWinloss_MTD,
		sum(isnull(t2.LicTO,0)) LicTO_Yesterday,
		sum(isnull(t2.LicWinloss,0)) LicWinloss_Yesterday
	FROM  
		#tmpLicensee_MTD_SB t1
		right join #tmpLicensee_Yesterday_SB t2 on t1.site=t2.site and t1.sporttype=t2.sporttype
) T
group by CASE WHEN T.RankTO <= 50 THEN t.site 
		WHEN t.site = 'All Licensees' THEN 'All Licensees'
			ELSE 'Other Licensees'
			end 
ORDER BY min(RankTO)

-------------------------------------------------------	

/*
drop table #matchVirtual
drop table #tmpSite_MTD_SB
drop table #tmpSite_Yesterday_SB
drop table #tmpLicensee_MTD_SB
drop table #tmpLicensee_Yesterday_SB
*/

