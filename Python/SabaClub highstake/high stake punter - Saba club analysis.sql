
use bodb_Account
go
--select @rptDate 
DECLARE @FromDate AS DATE,
		@ToDate AS DATE

select @FromDate = '2022/02/01'
	, @ToDate ='2022/02/21'


DECLARE @datestart SMALLDATETIME = @FromDate
	
CREATE TABLE #data
(
	custid int,	
	MemberTurnover money,
	MemberTurnoverORG money,
	MemberWinloss money,
	MemberWinlossORG money,
	HouseTO money,
	HouseTOORG money,
	HouseIncome money,
	HouseIncomeORG money,
	
	[Betcount] money

)

WHILE (@datestart<@ToDate)
BEGIN
	print @datestart
	
	insert #data(CUSTID,MemberTurnover,MemberTurnoverORG, MemberWinloss,MemberWinlossORG,
		HouseTO,HouseTOORG,HouseIncome,HouseIncomeORG,[Betcount])
	--overall
	select 
		CUSTID,
		SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake * c.Rate END)  [MemberTurnover]
		,SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake  END)  MemberTurnoverORG
		  -- Member Winloss
		,SUM(b.WinlossP * c.Rate) [MemberWinloss]
		,SUM(b.WinlossP) MemberWinlossORG
		-- Company Real Turnover
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate
			END) [CompanyRealTurnover]
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END)  
			END) [CompanyRealTurnoverORG]

		-- Company Real Income
		  ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * c.Rate ) [CompanyRealIncome]
		   ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm)  ) [CompanyRealIncomeORG]
		   
			-- Betcount
			,SUM(CASE WHEN b.BetType = 500 THEN 0 ELSE b.BetCount END) [Betcount]
			---- Company Real Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			--	  (CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate *
			--	  (CASE WHEN b.TicketStatus = 3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--	   END) ) [CompanyRealTurnover_NoDraw]
			---- Company Virtual Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * c.Rate *
			--	  (CASE WHEN b.TicketStatus=3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--		END) ) [CompanyVirtualTurnover_NoDraw]
	from FactCustWinloss b (nolock)
	 LEFT JOIN bodb_Account.dbo.tbl_Currency_Daily c WITH (NOLOCK) ON b.rptDate = c.ExchangeDate AND b.CurrencyID = c.Currency
	where rptdate = @datestart
	and CurrencyID<>20
	and TicketStatus <>14
	and SportType=200 
	and b.SiteID=1
	
	group by custid

	SELECT @datestart=DATEADD(dd, 1 ,@datestart)	
END

select  c.custid , c.username, 
	sum(betcount) betcount, 
	sum([MemberTurnover]) [MemberTurnover],
	sum([MemberTurnoverORG]) [MemberTurnoverORG],
	sum([MemberWinloss]) [MemberWinloss],
	sum([MemberWinlossORG]) [MemberWinlossORG],
	sum([MemberTurnover])/sum(betcount) AVG_Stake,
	sum(HouseTO) HouseTO,
	sum(HouseTOORG) HouseTOORG,
	sum(HouseIncome) HouseIncome,
	sum(HouseIncomeORG) HouseIncomeORG
	
into [bodb_DT].dbo.[SabaClub_Dec2020_Jan2021]
from #data d
join Customer c (nolock) on c.custid=d.custid
group by c.custid , c.username
 
 select * from [bodb_DT].dbo.[SabaClub_Dec2020_Jan2021] 




select  c.custid , c.username, 
	sum(betcount) betcount, 
	sum([MemberTurnover]) [MemberTurnover],
	sum([MemberTurnoverORG]) [MemberTurnoverORG],
	sum([MemberWinloss]) [MemberWinloss],
	sum([MemberWinlossORG]) [MemberWinlossORG],
	sum([MemberTurnover])/sum(betcount) AVG_Stake,
	sum(HouseTO) HouseTO,
	sum(HouseTOORG) HouseTOORG,
	sum(HouseIncome) HouseIncome,
	sum(HouseIncomeORG) HouseIncomeORG
	
into [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021]
from #data d
join Customer c (nolock) on c.custid=d.custid
group by c.custid , c.username
having sum([MemberTurnover])/sum(betcount)>=1100


select c.CustomerClass,*
from [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021] d
join Customer c (nolock) on c.custid=d.custid
where betcount>5 and [MemberTurnoverORG]/betcount>=370

select sum(case when c.closed = 1 then 1 else 0 end) closedStatus,
	sum(case when c.Closed = 0 AND ISNULL(c.reject, 0) = 1 then 1 else 0 end )  suspendedStatus ,
	sum(case when c.Enabled = 0   then 1 else 0 end )  EnabledStatus ,
	count(1) totalCust
from [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021] d
join bodb02.dbo.custinfo c (nolock) on c.custid=d.custid
where betcount>5 and [MemberTurnoverORG]/betcount>=370
--and (
--	(c.Closed = 0 AND ISNULL(c.reject, 0) = 1)
--	or 
--	c.closed=1
--	)
	 

select c.creationdate cr,*
from [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021] d
join Customer c (nolock) on c.custid=d.custid
where betcount>5 and [MemberTurnoverORG]/betcount>=370
order by creationdate desc


select case when creationdate< '2020/11/01' then '<2020/11/01'
		when creationdate>= '2020/11/01' and creationdate< '2020/12/01'then '<2020/12/01'
		when creationdate>= '2020/12/01' and creationdate< '2021/01/01'then '<2021/01/01'
		when creationdate>= '2021/01/01' and creationdate< '2021/02/01'then '<2021/02/01'
		end  RangeDate, count(d.custid) NoOfPunter
from [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021] d
join Customer c (nolock) on c.custid=d.custid
where betcount>5 and [MemberTurnoverORG]/betcount>=370
group by case when creationdate< '2020/11/01' then '<2020/11/01'
		when creationdate>= '2020/11/01' and creationdate< '2020/12/01'then '<2020/12/01'
		when creationdate>= '2020/12/01' and creationdate< '2021/01/01'then '<2021/01/01'
		when creationdate>= '2021/01/01' and creationdate< '2021/02/01'then '<2021/02/01'
		end  
 


select CustomerClass, 
	count(distinct d.custid) ActiveMember,
	sum(betcount) betcount, 
	sum([MemberTurnover]) [MemberTurnover],
	sum([MemberWinloss]) [MemberWinloss],
	sum([MemberTurnover])/sum(betcount) AVG_Stake,
	sum(HouseTO) HouseTO,
	sum(HouseIncome) HouseIncome 
	 
from [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021] d
join Customer c (nolock) on c.custid=d.custid
where betcount>5 and [MemberTurnoverORG]/betcount>=370
group by CustomerClass
order by CustomerClass


select site, 
	count(distinct d.custid) ActiveMember,
	sum(betcount) betcount, 
	sum([MemberTurnover]) [MemberTurnover],
	sum([MemberWinloss]) [MemberWinloss],
	sum([MemberTurnover])/sum(betcount) AVG_Stake,
	sum(HouseTO) HouseTO,
	sum(HouseIncome) HouseIncome 
from [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021] d
join Customer c (nolock) on c.custid=d.custid
where betcount>5 and [MemberTurnoverORG]/betcount>=370
group by site
order by [MemberTurnover] desc

select  s.isDeposit , 
	count(distinct d.custid) ActiveMember,
	sum(betcount) betcount, 
	sum([MemberTurnover]) [MemberTurnover],
	sum([MemberWinloss]) [MemberWinloss],
	sum([MemberTurnover])/sum(betcount) AVG_Stake,
	sum(HouseTO) HouseTO,
	sum(HouseIncome) HouseIncome 
from [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021] d
join Customer c (nolock) on c.custid=d.custid
join tbl_Site s (nolock) on s.site = c.site
where betcount>5 and [MemberTurnoverORG]/betcount>=370
group by s.isDeposit
order by [MemberTurnover] desc



select  a.username Agent , 
	m.username Master,
	s.username Super,
	a.Site,
	count(distinct d.custid) ActiveMember,
	sum(betcount) betcount, 
	sum([MemberTurnover]) [MemberTurnover],
	sum([MemberWinloss]) [MemberWinloss],
	sum([MemberTurnover])/sum(betcount) AVG_Stake,
	sum(HouseTO) HouseTO,
	sum(HouseIncome) HouseIncome 
from [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021] d
join Customer c (nolock) on c.custid=d.custid
join Customer a (nolock) on c.recommend=a.custid
join Customer m (nolock) on c.mrecommend=m.custid
join Customer s (nolock) on c.srecommend=s.custid
where betcount>5 and [MemberTurnoverORG]/betcount>=370
group by a.username  , 
	m.username ,
	s.username ,
	a.Site
order by HouseTO desc

select  ex.CurrencyName, ex.CurrencyCode,
	count(distinct d.custid) ActiveMember,
	sum(betcount) betcount, 
	sum([MemberTurnover]) [MemberTurnover],
	sum([MemberWinloss]) [MemberWinloss],
	sum([MemberTurnover])/sum(betcount) AVG_Stake,
	sum(HouseTO) HouseTO,
	sum(HouseIncome) HouseIncome 
	 
from [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021] d
join Customer c (nolock) on c.custid=d.custid
join tbl_Currency ex on ex.Currency = c.currency
group by  ex.CurrencyName, ex.CurrencyCode
order by [MemberTurnover] desc


select  d.custid,
	c.username,
	count(distinct a.AssoCustID) NoOfAssociation,
	sum(betcount) betcount, 
	sum([MemberTurnover]) [MemberTurnover],
	sum([MemberWinloss]) [MemberWinloss],
	sum([MemberTurnover])/sum(betcount) AVG_Stake,
	sum(HouseTO) HouseTO,
	sum(HouseIncome) HouseIncome 
from [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021] d
left join bodb_Account.dbo.Customer c (nolock) on c.CustID = d.custid
left join bodb_Account.dbo.CTS_Association a (nolock) on a.CustID = d.custid
group by   d.custid,c.username
order by NoOfAssociation  



select  d.custid,
	c.username,
	count(distinct a.AssoCustID) SMAAssociation,
	sum(betcount) betcount, 
	sum([MemberTurnover]) [MemberTurnover],
	sum([MemberWinloss]) [MemberWinloss],
	sum([MemberTurnover])/sum(betcount) AVG_Stake,
	sum(HouseTO) HouseTO,
	sum(HouseIncome) HouseIncome 
from [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021] d
left join bodb_Account.dbo.Customer c (nolock) on c.CustID = d.custid
left join bodb_Account.dbo.CTS_Association a (nolock) on a.CustID = d.custid
--left join bodb_Account.dbo.Customer ag (nolock) on ag.CustID = c.[recommend] 
where betcount>5 and [MemberTurnoverORG]/betcount>=370
	and (	c.[recommend] =a.[AssoCustID]
		or c.[mrecommend] =a.[AssoCustID]
		or c.[srecommend] =a.[AssoCustID])
group by   d.custid,c.username
order by [MemberTurnover] desc


select * from customer
where custid=45875925


select count(distinct a.AssoCustID) from bodb_Account.dbo.CTS_Association a (nolock)
where custid=37980959

 -------------------------------------------------------------------------------------------------------------------------
 -- get daily performance
 DECLARE @FromDate AS DATE,
		@ToDate AS DATE

select @FromDate = '2022/02/01'
	, @ToDate ='2022/02/21'


DECLARE @datestart SMALLDATETIME = @FromDate
	
CREATE TABLE #SabaPerf
(
	rptdate date,	
	MemberTurnover money,
	MemberTurnoverORG money,
	MemberWinloss money,
	MemberWinlossORG money,
	HouseTO money,
	HouseTOORG money,
	HouseIncome money,
	HouseIncomeORG money,
	
	[Betcount] money

)

WHILE (@datestart<@ToDate)
BEGIN
	print @datestart
	
	insert #SabaPerf(rptdate,MemberTurnover,MemberTurnoverORG, MemberWinloss,MemberWinlossORG,
		HouseTO,HouseTOORG,HouseIncome,HouseIncomeORG,[Betcount])
	--overall
	select 
		rptdate,
		SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake * c.Rate END)  [MemberTurnover]
		,SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake  END)  MemberTurnoverORG
		  -- Member Winloss
		,SUM(b.WinlossP * c.Rate) [MemberWinloss]
		,SUM(b.WinlossP) MemberWinlossORG
		-- Company Real Turnover
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate
			END) [CompanyRealTurnover]
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END)  
			END) [CompanyRealTurnoverORG]

		-- Company Real Income
		  ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * c.Rate ) [CompanyRealIncome]
		   ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm)  ) [CompanyRealIncomeORG]
		   
			-- Betcount
			,SUM(CASE WHEN b.BetType = 500 THEN 0 ELSE b.BetCount END) [Betcount]
			---- Company Real Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			--	  (CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate *
			--	  (CASE WHEN b.TicketStatus = 3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--	   END) ) [CompanyRealTurnover_NoDraw]
			---- Company Virtual Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * c.Rate *
			--	  (CASE WHEN b.TicketStatus=3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--		END) ) [CompanyVirtualTurnover_NoDraw]
	from FactCustWinloss b (NOLOCK)
	 LEFT JOIN bodb_Account.dbo.tbl_Currency_Daily c WITH (NOLOCK) ON b.rptDate = c.ExchangeDate AND b.CurrencyID = c.Currency
	where rptdate = @datestart
	and CurrencyID<>20
	and TicketStatus <>14
	and SportType=200 
	and b.SiteID=1
	and CustID in (select custid from bodb_DT..HighStake_SabaClub_Dec2020_Jan2021 where betcount>5 and [MemberTurnoverORG]/betcount>=370 )
	group by rptdate

	SELECT @datestart=DATEADD(dd, 1 ,@datestart)	
END



select * from #SabaPerf
order by rptdate
--drop table #SabaPerf


 -- get game performance
 DECLARE @FromDate AS DATE,
		@ToDate AS DATE

select @FromDate = '2020/12/01'
	, @ToDate ='2021/02/01'


DECLARE @datestart SMALLDATETIME = @FromDate
	
CREATE TABLE #game 
(
	bettype int,	
	MemberTurnover money,
	MemberTurnoverORG money,
	MemberWinloss money,
	MemberWinlossORG money,
	HouseTO money,
	HouseTOORG money,
	HouseIncome money,
	HouseIncomeORG money,
	
	[Betcount] money

)

WHILE (@datestart<@ToDate)
BEGIN
	print @datestart
	
	insert #game(bettype,MemberTurnover,MemberTurnoverORG, MemberWinloss,MemberWinlossORG,
		HouseTO,HouseTOORG,HouseIncome,HouseIncomeORG,[Betcount])
	--overall
	select 
		bettype,
		SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake * c.Rate END)  [MemberTurnover]
		,SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake  END)  MemberTurnoverORG
		  -- Member Winloss
		,SUM(b.WinlossP * c.Rate) [MemberWinloss]
		,SUM(b.WinlossP) MemberWinlossORG
		-- Company Real Turnover
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate
			END) [CompanyRealTurnover]
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END)  
			END) [CompanyRealTurnoverORG]

		-- Company Real Income
		  ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * c.Rate ) [CompanyRealIncome]
		   ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm)  ) [CompanyRealIncomeORG]
		   
			-- Betcount
			,SUM(CASE WHEN b.BetType = 500 THEN 0 ELSE b.BetCount END) [Betcount]
			---- Company Real Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			--	  (CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate *
			--	  (CASE WHEN b.TicketStatus = 3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--	   END) ) [CompanyRealTurnover_NoDraw]
			---- Company Virtual Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * c.Rate *
			--	  (CASE WHEN b.TicketStatus=3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--		END) ) [CompanyVirtualTurnover_NoDraw]
	from FactCustWinloss b (NOLOCK)
	 LEFT JOIN bodb_Account.dbo.tbl_Currency_Daily c WITH (NOLOCK) ON b.rptDate = c.ExchangeDate AND b.CurrencyID = c.Currency
	where rptdate = @datestart
	and CurrencyID<>20
	and TicketStatus <>14
	and SportType=200 
	and b.SiteID=1
	and CustID in (select custid from bodb_DT..HighStake_SabaClub_Dec2020_Jan2021 where betcount>5 and [MemberTurnoverORG]/betcount>=370 )
	group by bettype

	SELECT @datestart=DATEADD(dd, 1 ,@datestart)	
END

select  bettype, bt.typenamee Game,
	sum(betcount) betcount, 
	sum([MemberTurnover]) [MemberTurnover],
	sum([MemberTurnoverORG]) [MemberTurnoverORG],
	sum([MemberWinloss]) [MemberWinloss],
	sum([MemberWinlossORG]) [MemberWinlossORG],
	sum([MemberTurnover])/sum(betcount) AVG_Stake,
	sum(HouseTO) HouseTO,
	sum(HouseTOORG) HouseTOORG,
	sum(HouseIncome) HouseIncome,
	sum(HouseIncomeORG) HouseIncomeORG
 
from #game d 
join Bettype bt on bt.typeid=d.bettype
group by  bettype, bt.typenamee 
order by HouseTO desc

----------------------------------------------------------------------------------------------------------------------------

 -- get others product performance
 DECLARE @FromDate AS DATE,
		@ToDate AS DATE

select @FromDate = '2020/12/01'
	, @ToDate ='2021/02/01'


DECLARE @datestart SMALLDATETIME = @FromDate


--drop table #product
CREATE TABLE #product 
(
	custid int,
	rptdate date,
	ProductID int, 	
	 
	MemberTurnover money,
	MemberTurnoverORG money,
	MemberWinloss money,
	MemberWinlossORG money,
	HouseTO money,
	HouseTOORG money,
	HouseIncome money,
	HouseIncomeORG money,
	
	[Betcount] money

)

WHILE (@datestart<@ToDate)
BEGIN
	print @datestart
	
	insert #product(custid,rptdate,ProductID, MemberTurnover,MemberTurnoverORG, MemberWinloss,MemberWinlossORG,
		HouseTO,HouseTOORG,HouseIncome,HouseIncomeORG,[Betcount])
	--overall
	select 
		custid,
		rptdate,
		 CASE 
			WHEN bettype IN (9, 29)
				THEN - 2 --Parlay
			ELSE ISNULL(b.SportType, 0) --0 is for Unknown Sports
			END * 100000 
		+ 
		CASE WHEN ( CASE WHEN bettype IN (9, 29)
						THEN - 2 --Parlay
				  ELSE ISNULL(b.SportType, 0) --0 is for Unknown Sports
					END ) >= 0
			 THEN [bettype]
		ELSE - [bettype]
		END AS [SportBettypeProductID],
		 

		SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake * c.Rate END)  [MemberTurnover]
		,SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake  END)  MemberTurnoverORG
		  -- Member Winloss
		,SUM(b.WinlossP * c.Rate) [MemberWinloss]
		,SUM(b.WinlossP) MemberWinlossORG
		-- Company Real Turnover
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate
			END) [CompanyRealTurnover]
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END)  
			END) [CompanyRealTurnoverORG]

		-- Company Real Income
		  ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * c.Rate ) [CompanyRealIncome]
		   ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm)  ) [CompanyRealIncomeORG]
		   
			-- Betcount
			,SUM(CASE WHEN b.BetType = 500 THEN 0 ELSE b.BetCount END) [Betcount]
			---- Company Real Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			--	  (CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate *
			--	  (CASE WHEN b.TicketStatus = 3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--	   END) ) [CompanyRealTurnover_NoDraw]
			---- Company Virtual Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * c.Rate *
			--	  (CASE WHEN b.TicketStatus=3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--		END) ) [CompanyVirtualTurnover_NoDraw]
	from FactCustWinloss b (NOLOCK)
	 LEFT JOIN bodb_Account.dbo.tbl_Currency_Daily c WITH (NOLOCK) ON b.rptDate = c.ExchangeDate AND b.CurrencyID = c.Currency
	where rptdate = @datestart
	and CurrencyID<>20
	and TicketStatus <>14
	
	and b.SiteID=1
	and CustID in (select custid from bodb_DT..HighStake_SabaClub_Dec2020_Jan2021 where betcount>5 and [MemberTurnoverORG]/betcount>=370 )
	group by  custid, rptdate,
		CASE 
			WHEN bettype IN (9, 29)
				THEN - 2 --Parlay
			ELSE ISNULL(b.SportType, 0) --0 is for Unknown Sports
			END * 100000 
		+ 
		CASE WHEN ( CASE WHEN bettype IN (9, 29)
						THEN - 2 --Parlay
				  ELSE ISNULL(b.SportType, 0) --0 is for Unknown Sports
					END ) >= 0
			 THEN [bettype]
		ELSE - [bettype]
		END 
		 

	SELECT @datestart=DATEADD(dd, 1 ,@datestart)	
END

--jackpot and prize bettype
select * from #product d
join bodb_OLAP..All_Products_DimSportBettypeMatrix p on p.CombinationID = d.ProductID
where bettype in (
select bettype  from BettypeGroup
where BettypeGroupID in (6,10) 
)

--remove jackpot and prize bettype
delete d
from #product d
join bodb_OLAP..All_Products_DimSportBettypeMatrix p on p.CombinationID = d.ProductID
where bettype in (
select bettype  from BettypeGroup
where BettypeGroupID in (6,10) 
)



select  d.custid, username, rptdate, 
		sum(betcount) betcount,
		sum(HouseTO) HouseTO,
		sum(HouseTOORG) HouseTOORG ,
		sum(case when p.ProductID <=1 then HouseTO else 0 end) SportbookHouseTO,
		sum(case when p.ProductID <=1 then HouseTOORG else 0 end) SportbookHouseTOORG,
		sum(case when p.ProductID >=2 and p.ProductID <>42 then HouseTO else 0 end) OtherNonsportTO,
		sum(case when p.ProductID >=2 and p.ProductID <>42 then HouseTOORG else 0 end) OtherNonsportTOORG,
		sum(case when p.ProductID = 42 then HouseTO else 0 end) SabaClubHouseTO,
		sum(case when p.ProductID = 42 then HouseTOORG else 0 end) SabaClubTOORG
	from #product d
	join bodb_OLAP..All_Products_DimSportBettypeMatrix p on p.CombinationID = d.ProductID
	join Customer c (nolock) on c.custid = d.custid
	group by  d.custid, username, rptdate

select * from #product
where HouseTOORG=0




select *, 
	SabaClubTOORG/HouseTOORG [SabaClubHouseTO%], 
	SportbookHouseTOORG/HouseTOORG [SportbookHouseTO%], 
	OtherNonsportTOORG/HouseTOORG [OtherNonsportTO%],
	DATEDIFF(d, SabaClub_FirstActiveDays, '2021/01/31') NumberOfDayFromFirstActive,
	DATEDIFF(d, SabaClub_LastActiveDays, '2021/01/31') NumberOfDayInactive
into [bodb_DT].dbo.HighStake_SabaClub_MLModel
from 
(
	
	select  d.custid, c.username,  ci.Closed,
		sum(betcount) betcount,
		sum(HouseTO) HouseTO,
		sum(HouseTOORG) HouseTOORG ,
		MIN(rptdate)  FirstActiveDays,
		MAX(rptdate)  LastActiveDays,
		COUNT(DISTINCT  rptdate  )  ActiveDays,
		SUM(MemberTurnoverORG)/SUM(betcount) AVGStakeORG, 

		sum(case when p.ProductID <=1 then HouseTO else 0 end) SportbookHouseTO,
		sum(case when p.ProductID <=1 then HouseTOORG else 0 end) SportbookHouseTOORG,
		case when sum(case when p.ProductID <=1 then betcount else 0 end) = 0 then 0
		else sum(case when p.ProductID <=1 then MemberTurnoverORG else 0 end)/sum(case when p.ProductID <=1 then betcount else 0 end) 
		end SportbookAVGStakeORG,

		sum(case when p.ProductID >=2 and p.ProductID <>42 then HouseTO else 0 end) OtherNonsportTO,
		sum(case when p.ProductID >=2 and p.ProductID <>42 then HouseTOORG else 0 end) OtherNonsportTOORG,
		case when sum(case when p.ProductID >=2 and p.ProductID <>42 then betcount else 0 end)=0 then 0
		else sum(case when p.ProductID >=2 and p.ProductID <>42 then MemberTurnoverORG else 0 end)/sum(case when p.ProductID >=2 and p.ProductID <>42 then betcount else 0 end) 
		end OtherNonsportAVGStakeORG,

		sum(case when p.ProductID = 42 then HouseTO else 0 end) SabaClubHouseTO,
		sum(case when p.ProductID = 42 then HouseTOORG else 0 end) SabaClubTOORG,
		case when sum(case when p.ProductID = 42 then betcount else 0 end) =0  then 0
		else sum(case when p.ProductID = 42 then MemberTurnoverORG else 0 end)/sum(case when p.ProductID = 42 then betcount else 0 end) 
		end SabaClubAVGStakeORG,

		MIN(case when p.ProductID = 42 then rptdate else null end) SabaClub_FirstActiveDays,
		MAX(case when p.ProductID = 42 then rptdate else null end) SabaClub_LastActiveDays,
		COUNT(DISTINCT case when p.ProductID = 42 then rptdate else null end) SabaClub_ActiveDays
	from #product d
	join bodb_OLAP..All_Products_DimSportBettypeMatrix p on p.CombinationID = d.ProductID
	join Customer c (nolock) on c.custid = d.custid
	join bodb02.dbo.custinfo ci (nolock) on ci.custid = d.custid

	group by  d.custid, c.username,ci.Closed
) t
 

 ---- get hour

 
 -- get others product performance
 DECLARE @FromDate AS DATE,
		@ToDate AS DATE

select @FromDate = '2020/12/01'
	, @ToDate ='2021/02/01'


DECLARE @datestart SMALLDATETIME = @FromDate


--drop table #HourSabaClub
CREATE TABLE #HourSabaClub 
(
	custid int,
	rptdate date,
	[BettingHour] tinyint,
	 
	MemberTurnover money,
	MemberTurnoverORG money,
	MemberWinloss money,
	MemberWinlossORG money,
	HouseTO money,
	HouseTOORG money,
	HouseIncome money,
	HouseIncomeORG money,
	
	[Betcount] money

)

WHILE (@datestart<@ToDate)
BEGIN
	print @datestart
	
	insert #HourSabaClub(custid,rptdate,[BettingHour], MemberTurnover,MemberTurnoverORG, MemberWinloss,MemberWinlossORG,
		HouseTO,HouseTOORG,HouseIncome,HouseIncomeORG,[Betcount])
	--overall
	select 
		custid,
		rptdate,
		b.Hour [BettingHour],
		 

		SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake * c.Rate END)  [MemberTurnover]
		,SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake  END)  MemberTurnoverORG
		  -- Member Winloss
		,SUM(b.WinlossP * c.Rate) [MemberWinloss]
		,SUM(b.WinlossP) MemberWinlossORG
		-- Company Real Turnover
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							1 * c.Rate
			END) [CompanyRealTurnover]
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END)   
			END) [CompanyRealTurnoverORG]

		-- Company Real Income
		  ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * c.Rate ) [CompanyRealIncome]
		   ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm)  ) [CompanyRealIncomeORG]
		   
			-- Betcount
			,SUM(CASE WHEN b.BetType = 500 THEN 0 ELSE b.BetCount END) [Betcount]
			---- Company Real Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			--	  (CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate *
			--	  (CASE WHEN b.TicketStatus = 3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--	   END) ) [CompanyRealTurnover_NoDraw]
			---- Company Virtual Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * c.Rate *
			--	  (CASE WHEN b.TicketStatus=3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--		END) ) [CompanyVirtualTurnover_NoDraw]
	from FactCustNonSportHourly b (NOLOCK)
	 LEFT JOIN bodb_Account.dbo.tbl_Currency_Daily c WITH (NOLOCK) ON b.rptDate = c.ExchangeDate AND b.CurrencyID = c.Currency
	where rptdate = @datestart
	and CurrencyID<>20
	and TicketStatus <>14
	
	and SportType=200 
	and b.SiteID=1
	and CustID in (select custid from bodb_DT..HighStake_SabaClub_Dec2020_Jan2021 where betcount>5 and [MemberTurnoverORG]/betcount>=370 )
	group by  custid,
		rptdate,
		b.Hour  
		 

	SELECT @datestart=DATEADD(dd, 1 ,@datestart)	
END

select  rptdate, c.custid, c.username, [BettingHour],
		sum(betcount) betcount,
		sum(MemberTurnover) MemberTurnover,
		sum(MemberTurnoverORG) MemberTurnoverORG ,
		sum(MemberWinloss) MemberWinloss,
		sum(MemberWinlossORG) MemberWinlossORG ,

		sum(HouseTO) HouseTO,
		sum(HouseTOORG) HouseTOORG ,
		sum(HouseIncome) HouseIncome,
		sum(HouseIncomeORG) HouseIncomeORG  
from #HourSabaClub d 
join Customer c (nolock) on c.custid = d.custid
group by  rptdate, c.custid, c.username,[BettingHour]


-----------------
--get CTS_Association account
select  d.custid,
	c.username,
	a.AssoCustID
into #AssoCust
from [bodb_DT].dbo.[HighStake_SabaClub_Dec2020_Jan2021] d
left join bodb_Account.dbo.Customer c (nolock) on c.CustID = d.custid
join bodb_Account.dbo.CTS_Association a (nolock) on a.CustID = d.custid
--group by   d.custid,c.username,
order by   d.custid,c.username


-- get others product performance
 DECLARE @FromDate AS DATE,
		@ToDate AS DATE

select @FromDate = '2020/12/01'
	, @ToDate ='2021/02/01'


DECLARE @datestart SMALLDATETIME = @FromDate


--drop table #product_AssoCust
CREATE TABLE #product_AssoCust
(
	custid int,
	rptdate date,
	ProductID int, 	
	 
	MemberTurnover money,
	MemberTurnoverORG money,
	MemberWinloss money,
	MemberWinlossORG money,
	HouseTO money,
	HouseTOORG money,
	HouseIncome money,
	HouseIncomeORG money,
	
	[Betcount] money

)

WHILE (@datestart<@ToDate)
BEGIN
	print @datestart
	
	insert #product_AssoCust(custid,rptdate,ProductID, MemberTurnover,MemberTurnoverORG, MemberWinloss,MemberWinlossORG,
		HouseTO,HouseTOORG,HouseIncome,HouseIncomeORG,[Betcount])
	--overall
	select 
		custid,
		rptdate,
		 CASE 
			WHEN bettype IN (9, 29)
				THEN - 2 --Parlay
			ELSE ISNULL(b.SportType, 0) --0 is for Unknown Sports
			END * 100000 
		+ 
		CASE WHEN ( CASE WHEN bettype IN (9, 29)
						THEN - 2 --Parlay
				  ELSE ISNULL(b.SportType, 0) --0 is for Unknown Sports
					END ) >= 0
			 THEN [bettype]
		ELSE - [bettype]
		END AS [SportBettypeProductID],
		 

		SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake * c.Rate END)  [MemberTurnover]
		,SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake  END)  MemberTurnoverORG
		  -- Member Winloss
		,SUM(b.WinlossP * c.Rate) [MemberWinloss]
		,SUM(b.WinlossP) MemberWinlossORG
		-- Company Real Turnover
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate
			END) [CompanyRealTurnover]
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END)  
			END) [CompanyRealTurnoverORG]

		-- Company Real Income
		  ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * c.Rate ) [CompanyRealIncome]
		   ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm)  ) [CompanyRealIncomeORG]
		   
			-- Betcount
			,SUM(CASE WHEN b.BetType = 500 THEN 0 ELSE b.BetCount END) [Betcount]
			---- Company Real Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			--	  (CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate *
			--	  (CASE WHEN b.TicketStatus = 3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--	   END) ) [CompanyRealTurnover_NoDraw]
			---- Company Virtual Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * c.Rate *
			--	  (CASE WHEN b.TicketStatus=3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--		END) ) [CompanyVirtualTurnover_NoDraw]
	from FactCustWinloss b (NOLOCK)
	 LEFT JOIN bodb_Account.dbo.tbl_Currency_Daily c WITH (NOLOCK) ON b.rptDate = c.ExchangeDate AND b.CurrencyID = c.Currency
	where rptdate = @datestart
	and CurrencyID<>20
	and TicketStatus <>14
 
	and CustID in (select custid from #AssoCust )
	group by  custid, rptdate,
		CASE 
			WHEN bettype IN (9, 29)
				THEN - 2 --Parlay
			ELSE ISNULL(b.SportType, 0) --0 is for Unknown Sports
			END * 100000 
		+ 
		CASE WHEN ( CASE WHEN bettype IN (9, 29)
						THEN - 2 --Parlay
				  ELSE ISNULL(b.SportType, 0) --0 is for Unknown Sports
					END ) >= 0
			 THEN [bettype]
		ELSE - [bettype]
		END 
		 

	SELECT @datestart=DATEADD(dd, 1 ,@datestart)	
END

--jackpot and prize bettype
select * from #product_AssoCust d
join bodb_OLAP..All_Products_DimSportBettypeMatrix p on p.CombinationID = d.ProductID
where bettype in (
select bettype  from BettypeGroup
where BettypeGroupID in (6,10) 
)

--remove jackpot and prize bettype
delete d
from #product_AssoCust d
join bodb_OLAP..All_Products_DimSportBettypeMatrix p on p.CombinationID = d.ProductID
where bettype in (
select bettype  from BettypeGroup
where BettypeGroupID in (6,10) 
)


select  d.custid, username, rptdate, 
		sum(betcount) betcount,
		sum(HouseTO) HouseTO,
		sum(HouseTOORG) HouseTOORG ,
		sum(case when p.ProductID <=1 then HouseTO else 0 end) SportbookHouseTO,
		sum(case when p.ProductID <=1 then HouseTOORG else 0 end) SportbookHouseTOORG,
		sum(case when p.ProductID >=2 and p.ProductID <>42 then HouseTO else 0 end) OtherNonsportTO,
		sum(case when p.ProductID >=2 and p.ProductID <>42 then HouseTOORG else 0 end) OtherNonsportTOORG,
		sum(case when p.ProductID = 42 then HouseTO else 0 end) SabaClubHouseTO,
		sum(case when p.ProductID = 42 then HouseTOORG else 0 end) SabaClubTOORG
	from #product_AssoCust d
	join bodb_OLAP..All_Products_DimSportBettypeMatrix p on p.CombinationID = d.ProductID
	join Customer c (nolock) on c.custid = d.custid
	group by  d.custid, username, rptdate
-----------------

-- get normal stake vs high stake
 DECLARE @FromDate AS DATE,
		@ToDate AS DATE

select @FromDate = '2022/02/01'
	, @ToDate ='2022/02/21'


DECLARE @datestart SMALLDATETIME = @FromDate

--drop table #SabaPerf
--drop table #HighStake
CREATE TABLE #SabaPerf
(
	rptdate date,	
	isHighStake bit,
	MemberTurnover money,
	MemberTurnoverORG money,
	MemberWinloss money,
	MemberWinlossORG money,
	HouseTO money,
	HouseTOORG money,
	HouseIncome money,
	HouseIncomeORG money,
	
	[Betcount] money

)

CREATE TABLE #HighStake
(
	custid int,	
	isHighStake bit,
	betcount int,	 
	MemberTurnoverORG money,
	avgStake money 
)


WHILE (@datestart<@ToDate)
BEGIN
	print @datestart
	truncate table #HighStake
	 
	insert into #HighStake
	select 
		custid,
		case when SUM(b.stake) /sum(betcount)>=370 -- and  sum(betcount)>5 
		then 1 
		else 0 end isHighStake,

		sum(betcount) betcount,
		SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake  END)  MemberTurnoverORG,
		 SUM(b.stake) /sum(betcount) avgStake
		
	from FactCustWinloss b (NOLOCK) 
	where rptdate = @datestart
	and CurrencyID<>20
	and TicketStatus <>14
	and SportType=200 
	and b.SiteID=1
 
	group by custid
	
	 

	insert #SabaPerf(rptdate,isHighStake, MemberTurnover,MemberTurnoverORG, MemberWinloss,MemberWinlossORG,
		HouseTO,HouseTOORG,HouseIncome,HouseIncomeORG,[Betcount])
	--overall
	select 
		rptdate,
		isHighStake,

		SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake * c.Rate END)  [MemberTurnover]
		,SUM(CASE WHEN b.bettype = 71 THEN 0 ELSE b.stake  END)  MemberTurnoverORG
		  -- Member Winloss
		,SUM(b.WinlossP * c.Rate) [MemberWinloss]
		,SUM(b.WinlossP) MemberWinlossORG
		-- Company Real Turnover
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate
			END) [CompanyRealTurnover]
		,SUM(CASE WHEN b.bettype IN (71,73) THEN  0 
				ELSE (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
							(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END)  
			END) [CompanyRealTurnoverORG]

		-- Company Real Income
		  ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * c.Rate ) [CompanyRealIncome]
		   ,SUM( -(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm)  ) [CompanyRealIncomeORG]
		   
			-- Betcount
			,SUM(CASE WHEN b.BetType = 500 THEN 0 ELSE b.BetCount END) [Betcount]
			---- Company Real Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			--	  (CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * c.Rate *
			--	  (CASE WHEN b.TicketStatus = 3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--	   END) ) [CompanyRealTurnover_NoDraw]
			---- Company Virtual Turnover_No Draw
			--,SUM( (CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * c.Rate *
			--	  (CASE WHEN b.TicketStatus=3 THEN 0 
			--			WHEN b.TicketStatus in (12,13) THEN 0.5 
			--			ELSE 1 
			--		END) ) [CompanyVirtualTurnover_NoDraw]
	from FactCustWinloss b (NOLOCK)
	 LEFT JOIN bodb_Account.dbo.tbl_Currency_Daily c WITH (NOLOCK) ON b.rptDate = c.ExchangeDate AND b.CurrencyID = c.Currency
	 LEFT JOIN #HighStake e on e.custid=b.custid
	where rptdate = @datestart
	and CurrencyID<>20
	and TicketStatus <>14
	and SportType=200 
	and b.SiteID=1
	--and CustID in (select custid from bodb_DT..HighStake_SabaClub_Dec2020_Jan2021 where betcount>5 and [MemberTurnoverORG]/betcount>=370 )
	group by rptdate,isHighStake
	option(recompile)

	SELECT @datestart=DATEADD(dd, 1 ,@datestart)	
END



select * from #SabaPerf
order by rptdate