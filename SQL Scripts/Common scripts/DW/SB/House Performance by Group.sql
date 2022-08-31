-- run on DBDW2/bodb_Account
use bodb_Account
go
DECLARE @rptDate AS date = cast( (getdate() -1) as date) --yesterday

--select @rptDate 

DECLARE @FromDate AS DATE,
		@ToDate AS DATE

select @FromDate = DATEADD(month, DATEDIFF(month, 0, @rptDate), 0) -- StartOfMonth	
	, @ToDate =DATEADD(d, -1, DATEADD(m, DATEDIFF(m, 0, @rptDate) + 1, 0)) --end of month

select @rptDate, @FromDate, @ToDate

SELECT *
INTO #sportsSection
FROM (VALUES ('All', 1, 0)
             ,('Soccer', 2, 1)			 
			 ,('Basketball', 3, 2 )
			 ,('Esport', 4, 43 )
			 ,('Tennis', 5, 5 )
			 ,('OtherSports', 6, -3)
			 ,('Parlay', 7, -2)			 
       ) t1 (SectionName, SectionNumber, sporttype )

DECLARE @i int =1
DECLARE @Sporttype int, 
	@SectionName VARCHAR(50)

CREATE TABLE #tmpGroup_MTD_SB
(
	site VARCHAR(500),
	HouseTO decimal(19,4),
	HouseIncome decimal(19,4)
)

CREATE TABLE #tmpGroup_Yesterday_SB
(
	site VARCHAR(500),
	HouseTO decimal(19,4),
	HouseIncome decimal(19,4)
)


WHILE @i<= 7 --total of sections
BEGIN	
	select top 1 @SectionName=SectionName, @Sporttype=sporttype
	from #sportsSection
	where SectionNumber=@i
	select @i, @SectionName--, @Sporttype
	
	---------------------	
	truncate table #tmpGroup_MTD_SB
	truncate table #tmpGroup_Yesterday_SB
	----------------------------------------------------------	
	--Section 2: House performance

	--SB
	--ALL GROUPS - HOUSE VIEW 
	
	insert into #tmpGroup_MTD_SB
	(
		[Site],HouseTO,HouseIncome
	)
	SELECT CASE 
				WHEN S.isDeposit=0 and S.site not in ('789Y','CN88') THEN 'MBC'
				WHEN S.site= '789Y' THEN '789Y'			
				WHEN S.isDeposit=1 THEN 'Licensee'
				WHEN S.site= 'CN88' THEN 'CN88'		
			END	
			as	[Site], 
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
		AND (
			(@Sporttype=0)	--All sports
			or (@SportType= -2 AND bettype in (9,29)) -- parlay
			or (@SportType= -3  AND SportType not in (1,2,5,43)	and bettype not in (9,29)) -- Othersports
			or (@SportType not in (0,-2,-3) AND t.SportType=@Sporttype AND bettype not in (9,29)) -- single top sport
			)
	group by CASE 
				WHEN S.isDeposit=0 and S.site not in ('789Y','CN88') THEN 'MBC'
				WHEN S.site= '789Y' THEN '789Y'			
				WHEN S.isDeposit=1 THEN 'Licensee'
				WHEN S.site= 'CN88' THEN 'CN88'	
			END	

	
	insert into #tmpGroup_Yesterday_SB
	(
	[Site],HouseTO,HouseIncome
	)
	select CASE 
				WHEN S.isDeposit=0 and S.site not in ('789Y','CN88') THEN 'MBC'
				WHEN S.site= '789Y' THEN '789Y'			
				WHEN S.isDeposit=1 THEN 'Licensee'
				WHEN S.site= 'CN88' THEN 'CN88'		
			END	
			as	[Site], 
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
		AND (
			(@Sporttype=0)	--All sports
			or (@SportType= -2 AND bettype in (9,29)) -- parlay
			or (@SportType= -3  AND SportType not in (1,2,5,43)	and bettype not in (9,29)) -- Othersports
			or (@SportType not in (0,-2,-3) AND t.SportType=@Sporttype AND bettype not in (9,29)) -- single top sport
			)
	group by CASE 
				WHEN S.isDeposit=0 and S.site not in ('789Y','CN88') THEN 'MBC'
				WHEN S.site= '789Y' THEN '789Y'			
				WHEN S.isDeposit=1 THEN 'Licensee'
				WHEN S.site= 'CN88' THEN 'CN88'	
			END	

	
	SELECT t.Site,
		t.[TO], t.Margin, 
		t.TO2, t.Margin2	

	FROM (
		SELECT 		 
			t1.Site,		
			sum(isnull(t2.HouseTO,0)) as [TO],	
			case when sum(isnull(t2.HouseTO,0)) = 0 then 0 else sum(t2.HouseIncome)/sum(t2.HouseTO) end Margin,
			sum(isnull(t1.HouseTO,0)) AS [TO2],
			case when sum(isnull(t1.HouseTO,0)) = 0 then 0 else sum(t1.HouseIncome)/sum(t1.HouseTO) end Margin2,
			CASE 
				WHEN t1.Site = 'MBC' then 1
				WHEN t1.Site = '789Y' then 2
				WHEN t1.Site = 'Licensee' then 3						
				WHEN t1.Site = 'CN88' then 5			
			end OrderBy
		FROM  
			#tmpGroup_MTD_SB t1
			LEFT JOIN #tmpGroup_Yesterday_SB t2 on t1.Site=t2.Site
		group by t1.Site
	
		UNION ALL

		SELECT 	
			'ALL(w/o CN88)'	Licensee,						
			sum(isnull(t2.HouseTO,0)) as [TO],	
			case when sum(isnull(t2.HouseTO,0)) = 0 then 0 else sum(t2.HouseIncome)/sum(t2.HouseTO) end Margin,
			sum(isnull(t1.HouseTO,0)) AS [TO2],
			case when sum(isnull(t1.HouseTO,0)) = 0 then 0 else sum(t1.HouseIncome)/sum(t1.HouseTO) end Margin2,
			4 OrderBy
		FROM  
			#tmpGroup_MTD_SB t1
			LEFT JOIN #tmpGroup_Yesterday_SB t2 on t1.Site=t2.Site
		where t1.site <> 'CN88'	
	) T
	ORDER BY OrderBy

	-------------------------------------------------------	

	set @i=@i+1
END

drop table #sportsSection
drop table #tmpGroup_Yesterday_SB
drop table #tmpGroup_MTD_SB

