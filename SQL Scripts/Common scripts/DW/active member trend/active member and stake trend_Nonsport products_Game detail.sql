--select * 
--from tbl_Site s
--where s.site='789y'

--check oneRNG product and cardclub trend by game
DECLARE @datestart SMALLDATETIME ,
	@dateend SMALLDATETIME 

SELECT	@datestart ='2020/05/04',@dateend='2020/05/04'--'2020/03/17'

IF OBJECT_ID('tempdb..#GameDetail') IS NOT NULL DROP TABLE #GameDetail;   


CREATE TABLE #GameDetail
(
	rptDate date,
	Site varchar(100),		
	Product varchar(100),
	Bettype varchar(100),
	CustID int,
	--ActiveMember int,
	--ProductID int,
	Stake money,
	Totalbet money,
	WinlossP money,
	HouseTO money,
	HouseIncome money
)

WHILE (@datestart<=@dateend)
BEGIN	
	insert into #GameDetail (rptDate, Site, Product, Bettype, CustID, Stake, Totalbet, WinlossP, HouseTO, HouseIncome)
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
		pb.ProductName Product, 
		bt.typenamee Bettype,
		b.custid,
		--count(distinct b.CustID) ActiveMember,		
		sum(b.Stake*e.Rate) Stake,
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
	--left join (select distinct productid from NonSportSetting) nsp on nsp.ProductID=pb.ProductID
	join Bettype bt on bt.typeid=b.BetType
	where 
		rptdate = @datestart		
		AND TicketStatus NOT IN (14)    -- exclude refund
		AND CurrencyID <> 20		
		and pb.ProductID in (34,42,8,28)	
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
		pb.ProductName , 
		bt.typenamee ,
		b.custid
		
	print @datestart
	SELECT @datestart=DATEADD(dd, 1 ,@datestart)	
END

select * 
from #GameDetail
order by rptdate

