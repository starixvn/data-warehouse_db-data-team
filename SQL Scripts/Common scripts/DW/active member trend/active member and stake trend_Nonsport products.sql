--select * 
--from tbl_Site s
--where s.site='789y'

--check nonsport product and esport trend
DECLARE @datestart SMALLDATETIME ,
	@dateend SMALLDATETIME 

SELECT	@datestart ='2020/04/22',@dateend='2020/05/04'--'2020/03/17'


IF OBJECT_ID('tempdb..#CustWinloss') IS NOT NULL DROP TABLE #CustWinloss;   
IF OBJECT_ID('tempdb..#matchVirtual') IS NOT NULL DROP TABLE #matchVirtual; 


CREATE TABLE #CustWinloss
(
	rptDate date,
	Site varchar(100),		
	Product varchar(100),
	ActiveMember int,
	--ProductID int,
	Stake money,
	Totalbet money,
	WinlossP money,
	HouseTO money,
	HouseIncome money
)


CREATE TABLE #matchVirtual
(
	eventdate date,
	matchid int,
	Matchtype smallint
)

WHILE (@datestart<=@dateend)
BEGIN	
	truncate table #matchVirtual

	insert into #matchVirtual (eventdate, matchid, Matchtype)
	select  m.eventdate, m.matchid, 1
	from bodb_Account.dbo.match m(nolock) 
	left join bodb02.dbo.League l (nolock) on m.leagueid=l.leagueid
	left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
	left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
	where 
		m.sporttype=1
		and eventdate= @datestart
		--and (l.leaguename like 'Virtual%' 
		--	or l.leaguename like 'SABA Virtual%')
		and l.LeagueGroupID = 42
	UNION 
	select  m.eventdate, m.matchid, 1
	from bodb_Archive.dbo.match m(nolock) 
	left join bodb02.dbo.League l (nolock) on m.leagueid=l.leagueid
	left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
	left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
	where 
		l.sporttype=1
		and eventdate= @datestart
		--and (l.leaguename like 'Virtual%' 
		--	or l.leaguename like 'SABA Virtual%')
		and l.LeagueGroupID = 42

	insert into #matchVirtual (eventdate, matchid, Matchtype)
	select  m.eventdate, m.matchid, 2
	from bodb_Account.dbo.match m(nolock) 
	left join bodb02.dbo.League l (nolock) on m.leagueid=l.leagueid
	left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
	left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
	where 
		m.sporttype=1
		and eventdate= @datestart
		--and l.leaguename like 'Esoccer%'
		and l.LeagueGroupID = 41
	UNION 
	select  m.eventdate, m.matchid, 2
	from bodb_Archive.dbo.match m(nolock) 
	left join bodb02.dbo.League l (nolock) on m.leagueid=l.leagueid
	left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
	left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
	where 
		l.sporttype=1
		and eventdate= @datestart
		--and l.leaguename like 'Esoccer%'
		and l.LeagueGroupID = 41

	insert into #matchVirtual (eventdate, matchid, Matchtype)
	select  m.eventdate, m.matchid, 3
	from bodb_Account.dbo.match m(nolock) 
	left join bodb02.dbo.League l (nolock) on m.leagueid=l.leagueid
	left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
	left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
	where 
		m.sporttype=2
		and eventdate= @datestart
		--and (l.leaguename like 'Virtual%' 
		--	or l.leaguename like 'SABA Virtual%')
		and l.LeagueGroupID = 42
	UNION 
	select  m.eventdate, m.matchid, 3
	from bodb_Archive.dbo.match m(nolock) 
	left join bodb02.dbo.League l (nolock) on m.leagueid=l.leagueid
	left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
	left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
	where 
		l.sporttype=2
		and eventdate= @datestart
		--and (l.leaguename like 'Virtual%' 
		--	or l.leaguename like 'SABA Virtual%')
		and l.LeagueGroupID = 42

	--calculate each nonsport product
	insert into #CustWinloss (rptDate, Site, Product, ActiveMember, Stake, Totalbet, WinlossP, HouseTO, HouseIncome)
	select 
		rptdate,
		CASE 
				WHEN s.isDeposit=1 THEN 'Cash'
				WHEN s.site= '789Y' THEN '789Y'
				WHEN s.site in ( 'XYZBET', 'BEST-ODDS') THEN 'XYZ & Bestodds'
				WHEN s.site= '611111' THEN '611 (China)'
				WHEN s.site= '733333' THEN '733 (Malaysia)'
				WHEN s.site= '755555' THEN '755 (Thailand)'
				WHEN s.site IN ('INDO','IBCIndo') THEN 'Indo'
				WHEN s.isDeposit=0 and s.site not in ('789Y','XYZBET', 'BEST-ODDS', '611111','733333','755555','INDO','IBCIndo','CN88') THEN 'Other MBC'		
				WHEN s.site= 'CN88' THEN 'CN88'		
			END	SITE,
		case
			when nsp.ProductID is not null then pb.ProductName
			when pb.ProductID =1 and b.SportType = 43 and b.bettype not in (9,29) then 'ESport'
			when pb.ProductID =1 and b.SportType = 55 and b.bettype not in (9,29) then 'Finance'
			when pb.ProductID =1 and b.SportType = 1 and b.bettype not in (9,29) and ((mv.matchid is not null and mv.Matchtype=1) or vl.leagueid is not null ) then 'Saba Soccer'
			when pb.ProductID =1 and b.SportType = 1 and b.bettype not in (9,29) and mv.matchid is not null and mv.Matchtype=2 then 'Soccer-ESoccer'
			when pb.ProductID =1 and b.SportType = 2 and b.bettype not in (9,29) and ((mv.matchid is not null and mv.Matchtype=3) or vl.leagueid is not null ) then 'Saba Basketball'
			else 'Others'
		end Product, 
		count(distinct b.CustID) ActiveMember,		
		sum(b.Stake*e.Rate) MemberTO,
		sum(b.ActualStake*e.Rate) TotalBet,
		sum(WinlossP*e.rate) MemberWinloss,
		-- [Company Real Turnover]
		SUM(
		(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
		(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * e.Rate  
			--*(CASE WHEN b.TicketStatus = 3 THEN 0 
			--		WHEN b.TicketStatus in (12,13) THEN 0.5 
			--		ELSE 1 
			--   END)
			   ) HouseTurnover,
		-- [Company Real Income]
		SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * e.Rate) HouseIncome
	from FactCustWinloss b (nolock)
	inner join tbl_site s (NOLOCK) on s.siteid = b.SiteID
	inner join tbl_Currency_Daily e with(nolock) on b.RptDate = e.ExchangeDate and e.Currency=b.CurrencyID
	join Product_Bettype pb on pb.Bettype = b.BetType
	left join (select distinct productid from NonSportSetting) nsp on nsp.ProductID=pb.ProductID
	left join #matchVirtual mV on mV.matchid=b.matchid
	left join (select leagueid from bodb02.dbo.League (NOLOCK)
			where LeagueGroupID=42) vl on b.LeagueID=vl.leagueid  --league virtual of saba --outright case
	where 
		rptdate = @datestart		
		AND TicketStatus NOT IN (14)    -- exclude refund
		AND CurrencyID <> 20			
	group by 
		rptdate,		
		CASE 
				WHEN s.isDeposit=1 THEN 'Cash'
				WHEN s.site= '789Y' THEN '789Y'
				WHEN s.site in ( 'XYZBET', 'BEST-ODDS') THEN 'XYZ & Bestodds'
				WHEN s.site= '611111' THEN '611 (China)'
				WHEN s.site= '733333' THEN '733 (Malaysia)'
				WHEN s.site= '755555' THEN '755 (Thailand)'
				WHEN s.site IN ('INDO','IBCIndo') THEN 'Indo'
				WHEN s.isDeposit=0 and s.site not in ('789Y','XYZBET', 'BEST-ODDS', '611111','733333','755555','INDO','IBCIndo','CN88') THEN 'Other MBC'		
				WHEN s.site= 'CN88' THEN 'CN88'		
			END ,
		case
			when nsp.ProductID is not null then pb.ProductName
			when pb.ProductID =1 and b.SportType = 43 and b.bettype not in (9,29) then 'ESport'
			when pb.ProductID =1 and b.SportType = 55 and b.bettype not in (9,29) then 'Finance'
			when pb.ProductID =1 and b.SportType = 1 and b.bettype not in (9,29) and ((mv.matchid is not null and mv.Matchtype=1) or vl.leagueid is not null ) then 'Saba Soccer'
			when pb.ProductID =1 and b.SportType = 1 and b.bettype not in (9,29) and mv.matchid is not null and mv.Matchtype=2 then 'Soccer-ESoccer'
			when pb.ProductID =1 and b.SportType = 2 and b.bettype not in (9,29) and ((mv.matchid is not null and mv.Matchtype=3) or vl.leagueid is not null ) then 'Saba Basketball'
			else 'Others'
		end 
	
	insert into #CustWinloss (rptDate, Site, Product, ActiveMember, Stake, Totalbet, WinlossP, HouseTO, HouseIncome)
	select 
		rptdate,
		'All sites' Site,
		case
			when nsp.ProductID is not null then pb.ProductName
			when pb.ProductID =1 and b.SportType = 43 and b.bettype not in (9,29) then 'ESport'
			when pb.ProductID =1 and b.SportType = 55 and b.bettype not in (9,29) then 'Finance'
			when pb.ProductID =1 and b.SportType = 1 and b.bettype not in (9,29) and ((mv.matchid is not null and mv.Matchtype=1) or vl.leagueid is not null ) then 'Saba Soccer'
			when pb.ProductID =1 and b.SportType = 1 and b.bettype not in (9,29) and mv.matchid is not null and mv.Matchtype=2 then 'Soccer-ESoccer'
			when pb.ProductID =1 and b.SportType = 2 and b.bettype not in (9,29) and ((mv.matchid is not null and mv.Matchtype=3) or vl.leagueid is not null ) then 'Saba Basketball'
			else 'Others'
		end Product, 
		count(distinct b.CustID) ActiveMember,		
		sum(b.Stake*e.Rate) MemberTO,
		sum(b.ActualStake*e.Rate) TotalBet,
		sum(WinlossP*e.rate) MemberWinloss,
		-- [Company Real Turnover]
		SUM(
		(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
		(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * e.Rate  
			--* CASE WHEN b.TicketStatus = 3 THEN 0 
			--		WHEN b.TicketStatus in (12,13) THEN 0.5 
			--		ELSE 1 
			 --  END)
			 ) HouseTurnover,
		-- [Company Real Income]
		SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * e.Rate) HouseIncome
	from FactCustWinloss b (nolock)
	inner join tbl_site s (NOLOCK) on s.siteid = b.SiteID
	inner join tbl_Currency_Daily e with(nolock) on b.RptDate = e.ExchangeDate and e.Currency=b.CurrencyID
	join Product_Bettype pb on pb.Bettype = b.BetType
	left join (select distinct productid from NonSportSetting) nsp on nsp.ProductID=pb.ProductID
	left join #matchVirtual mV on mV.matchid=b.matchid
	left join (select leagueid from bodb02.dbo.League (NOLOCK)
			where LeagueGroupID=42) vl on b.LeagueID=vl.leagueid  --league virtual of saba --outright case
	where 
		rptdate = @datestart		
		AND TicketStatus NOT IN (14)    -- exclude refund
		AND CurrencyID <> 20			
	group by 
		rptdate,		
		case
			when nsp.ProductID is not null then pb.ProductName
			when pb.ProductID =1 and b.SportType = 43 and b.bettype not in (9,29) then 'ESport'
			when pb.ProductID =1 and b.SportType = 55 and b.bettype not in (9,29) then 'Finance'
			when pb.ProductID =1 and b.SportType = 1 and b.bettype not in (9,29) and ((mv.matchid is not null and mv.Matchtype=1) or vl.leagueid is not null ) then 'Saba Soccer'
			when pb.ProductID =1 and b.SportType = 1 and b.bettype not in (9,29) and mv.matchid is not null and mv.Matchtype=2 then 'Soccer-ESoccer'
			when pb.ProductID =1 and b.SportType = 2 and b.bettype not in (9,29) and ((mv.matchid is not null and mv.Matchtype=3) or vl.leagueid is not null ) then 'Saba Basketball'
			else 'Others'
		end

	--calculate all nonsport products
	insert into #CustWinloss (rptDate, Site, Product, ActiveMember, Stake, Totalbet, WinlossP, HouseTO, HouseIncome)
	select 
		rptdate,
		CASE 
				WHEN s.isDeposit=1 THEN 'Cash'
				WHEN s.site= '789Y' THEN '789Y'
				WHEN s.site in ( 'XYZBET', 'BEST-ODDS') THEN 'XYZ & Bestodds'
				WHEN s.site= '611111' THEN '611 (China)'
				WHEN s.site= '733333' THEN '733 (Malaysia)'
				WHEN s.site= '755555' THEN '755 (Thailand)'
				WHEN s.site IN ('INDO','IBCIndo') THEN 'Indo'
				WHEN s.isDeposit=0 and s.site not in ('789Y','XYZBET', 'BEST-ODDS', '611111','733333','755555','INDO','IBCIndo','CN88') THEN 'Other MBC'		
				WHEN s.site= 'CN88' THEN 'CN88'		
			END Site,
		case
			when nsp.ProductID is not null then 'All Nonsport products'
			--when pb.ProductID =1 and b.SportType = 43 and b.bettype not in (9,29) then 'ESport'
			--when pb.ProductID =1 and b.SportType = 55 and b.bettype not in (9,29) then 'Finance'
			else 'Others'
		end Product, 
		count(distinct b.CustID) ActiveMember,		
		sum(b.Stake*e.Rate) MemberTO,
		sum(b.ActualStake*e.Rate) TotalBet,
		sum(WinlossP*e.rate) MemberWinloss,
		-- [Company Real Turnover]
		SUM(
		(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
		(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * e.Rate  
			--*(CASE WHEN b.TicketStatus = 3 THEN 0 
			--		WHEN b.TicketStatus in (12,13) THEN 0.5 
			--		ELSE 1 
			--   END)
			   ) HouseTurnover,
		-- [Company Real Income]
		SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * e.Rate) HouseIncome
	from FactCustWinloss b (nolock)
	inner join tbl_site s (NOLOCK) on s.siteid = b.SiteID
	inner join tbl_Currency_Daily e with(nolock) on b.RptDate = e.ExchangeDate and e.Currency=b.CurrencyID
	join Product_Bettype pb on pb.Bettype = b.BetType
	left join (select distinct productid from NonSportSetting) nsp on nsp.ProductID=pb.ProductID
	where 
		rptdate = @datestart		
		AND TicketStatus NOT IN (14)    -- exclude refund
		AND CurrencyID <> 20		
		and nsp.ProductID is not null
	group by 
		rptdate,		
		CASE 
				WHEN s.isDeposit=1 THEN 'Cash'
				WHEN s.site= '789Y' THEN '789Y'
				WHEN s.site in ( 'XYZBET', 'BEST-ODDS') THEN 'XYZ & Bestodds'
				WHEN s.site= '611111' THEN '611 (China)'
				WHEN s.site= '733333' THEN '733 (Malaysia)'
				WHEN s.site= '755555' THEN '755 (Thailand)'
				WHEN s.site IN ('INDO','IBCIndo') THEN 'Indo'
				WHEN s.isDeposit=0 and s.site not in ('789Y','XYZBET', 'BEST-ODDS', '611111','733333','755555','INDO','IBCIndo','CN88') THEN 'Other MBC'		
				WHEN s.site= 'CN88' THEN 'CN88'		
			END,
		case
			when nsp.ProductID is not null then 'All Nonsport products'
			--when pb.ProductID =1 and b.SportType = 43 and b.bettype not in (9,29) then 'ESport'
			--when pb.ProductID =1 and b.SportType = 55 and b.bettype not in (9,29) then 'Finance'
			else 'Others'
		end

	insert into #CustWinloss (rptDate, Site, Product, ActiveMember, Stake, Totalbet, WinlossP, HouseTO, HouseIncome)
	select 
		rptdate,
		'All sites' Site,
		case
			when nsp.ProductID is not null then 'All Nonsport products'
			--when pb.ProductID =1 and b.SportType = 43 and b.bettype not in (9,29) then 'ESport'
			--when pb.ProductID =1 and b.SportType = 55 and b.bettype not in (9,29) then 'Finance'
			else 'Others'
		end Product, 
		count(distinct b.CustID) ActiveMember,		
		sum(b.Stake*e.Rate) MemberTO,
		sum(b.ActualStake*e.Rate) TotalBet,
		sum(WinlossP*e.rate) MemberWinloss,
		-- [Company Real Turnover]
		SUM(
		(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
		(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * e.Rate  
			--*(CASE WHEN b.TicketStatus = 3 THEN 0 
			--		WHEN b.TicketStatus in (12,13) THEN 0.5 
			--		ELSE 1 
			--   END)
			   ) HouseTurnover,
		-- [Company Real Income]
		SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * e.Rate) HouseIncome
	from FactCustWinloss b (nolock)
	inner join tbl_site s (NOLOCK) on s.siteid = b.SiteID
	inner join tbl_Currency_Daily e with(nolock) on b.RptDate = e.ExchangeDate and e.Currency=b.CurrencyID
	join Product_Bettype pb on pb.Bettype = b.BetType
	left join (select distinct productid from NonSportSetting) nsp on nsp.ProductID=pb.ProductID
	where 
		rptdate = @datestart		
		AND TicketStatus NOT IN (14)    -- exclude refund
		AND CurrencyID <> 20	
		and nsp.ProductID is not null		
	group by 
		rptdate,	
		case
			when nsp.ProductID is not null then 'All Nonsport products'
			--when pb.ProductID =1 and b.SportType = 43 and b.bettype not in (9,29) then 'ESport'
			--when pb.ProductID =1 and b.SportType = 55 and b.bettype not in (9,29) then 'Finance'
			else 'Others'
		end 

	print @datestart
	SELECT @datestart=DATEADD(dd, 1 ,@datestart)	
END


--select distinct productid, ProductName  from Product_Bettype
--where ProductID<>1

select * 
from #CustWinloss
where Product <> 'Others'
--and Product= 'Saba Soccer'
order by rptdate

--select rptDate, sum(case when product='Sportbook' then Activemember else 0 end) Sportbook_ActiveMember,
--	sum(case when product='oneRNG' then Activemember else 0 end) Nonsport_ActiveMember
--from #CustWinloss
--group by rptDate
