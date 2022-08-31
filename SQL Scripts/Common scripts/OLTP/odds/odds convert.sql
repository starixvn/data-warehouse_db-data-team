--DBDW2
select * 
from bodb_Account.dbo.DimOddsType (NOLOCK)

--drop table #BettypeMultipleOdd
select  * 
into #BettypeMultipleOdd
from bodb_Account..Bettype (NOLOCK)
where SupportMultipleOdds=1


--select * from #BettypeMultipleOdd
;with CTE_Ticket AS (
	select top 100 
		--bt.SupportMultipleOdds,
		case 
			when OddsType in (0, -1, 6, 7) then NULL  
			when isnull(SupportMultipleOdds,0)=0 and OddsType=1 and odds<=2 then odds -1   
			when isnull(SupportMultipleOdds,0)=0 and OddsType=1 and odds> 2 then -1/(odds -1)
			when isnull(SupportMultipleOdds,0)=1 and OddsType in (1,2) and odds <=1 then odds 
			when isnull(SupportMultipleOdds,0)=1 and OddsType in (1,2) and odds> 1 then -1/(odds)
			when isnull(SupportMultipleOdds,0)=1 and OddsType in (3,5) then -1/(odds)
			else odds
		end Odds_ML, 
		case when isnull(SupportMultipleOdds,0)=0 and OddsType=1 then odds -1   
			 when OddsType in (0, -1, 6, 7) then NULL  
		else 
			case when odds < 0 then -1/odds 
			else odds end 
		end Odds_HK,
		odds,oddstype,b.bettype,oddsspread,betteam, status
		stake, actual_stake, (winlost-actual_stake) WinlossP, winlost, transid 
	from bodb_staging.dbo.bettrans b (nolock)
		left join #BettypeMultipleOdd bt on bt.typeid = b.bettype
	where matchid>0 
	and bettype=1
	--and OddsType=2
)

select 
		CASE 
				WHEN b.BetType IN(1,3,7,8) AND oddstype NOT in (6,7) AND (Odds_ML + oddsspread) > 1
						THEN CAST(1 - (oddsspread - (1 - Odds_ML)) AS DECIMAL(8,2))
				WHEN BetType IN(1,3,7,8) AND oddstype NOT in (6,7) AND (Odds_ML + oddsspread) <= 1
						THEN  CAST(- (oddsspread + Odds_ML) AS DECIMAL(8,2))
		END  Odds_OppositeChoice_ML,
		* 
from CTE_Ticket b

