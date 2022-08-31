-- select * from bodb_Account.dbo.Customer c(nolock) where c.username= 'MS88RMB01686541'--'266hk888'

use bodb02

go

/*	Created by: Dan
	Task: get betting choice of basketball tickets
		support main bettypes
	
	DB: DBACC/bodb02	
	Output: 
		statistic about match,bettype,betchoice, handicap
Revisions:

*/

/*

drop table #SportBetType
drop table #Match
drop table #tmp_Data

*/

declare 
		@date SMALLDATETIME = '2020/05/29',  
		@sporttype int = 2  
		, @custid int = 0--41917751
		, @matchid int = 37572163 

    --SET NOCOUNT ON;

BEGIN --#SportBetType
      
    CREATE TABLE #SportBetType(BetType INT);
    INSERT INTO #SportBetType
            SELECT s.BetType
            FROM bodb02.dbo.f_SportBetTypeMatrix_Sel(1, 1, 0, 2, '', '', 0) s
            WHERE SubProduct NOT IN('MG-SuperLive', 'BT-Sold', 'BT-Bought', 'BT-Comm', 'BT-Winloss', 'Bet Builder')
            AND EventType IN(1, 2);
END;
   
    
BEGIN -- #Match
	SELECT DISTINCT 
            m.MatchId, 
            m.MatchCode, 
            m.type,
			m.leagueid, l.leaguename, h.teamname home, a.teamname awayteam,m.kickofftime kickofftime ,GlobalShowTime,
			finalhomescore,
			finalawayscore
	into #Match
    FROM
    (
        SELECT MatchId, 
                LeagueId, 
                MatchCode, 
				homeid,
				awayid,
				finalhomescore,
				finalawayscore,
				kickofftime,
				GlobalShowTime,
                'match' AS type
        FROM dbo.match WITH(NOLOCK)
        WHERE --EventDate = @date 			AND 
		sporttype = @sporttype
		and (@matchid=0 or matchID = @matchid)
    --       UNION ALL
    --       SELECT orid, 
    --               LeagueId, 
    --               MatchCode,                 
				--teamid homeid,
				--0 awayid,
				--o.kickofftime,null GlobalShowTime,
				-- 'outright' AS type
    --       FROM outright o WITH(NOLOCK)
    --       WHERE EventDate = @date
    ) m
    INNER JOIN bodb02.dbo.league l WITH(NOLOCK) ON m.LeagueId = l.LeagueId
	LEFT JOIN bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
	LEFT JOIN bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
    WHERE l.sporttype = @sporttype
		--and isnull(l.LeagueGroupID,0) in (42,74);
END;


	--select * from #Match


    --BEGIN -- Extra PT
    --    CREATE TABLE #ExtraPT_Sel
    --                 (SuperID   INT, 
    --                  Sporttype INT, 
    --                  ExtraPT   DECIMAL(9, 8)
    --                 );
    --    INSERT INTO #ExtraPT_Sel
    --           (SuperID, 
    --            Sporttype, 
    --            ExtraPT
    --           )
    --           SELECT SuperId, 
    --                  Sporttype, 
    --                  SUM(ExtraPT) AS ExtraPT
    --           FROM bodb02.dbo.Acc_GroupExtraPTSetting a WITH(NOLOCK)
    --           WHERE @date BETWEEN FromDate AND Todate
    --                 AND a.ProductId = 1
    --                 AND a.SubProduct NOT IN('MG-SuperLive', 'BT-Sold', 'BT-Bought', 'BT-Comm', 'BT-Winloss', 'Bet Builder')
    --           GROUP BY SuperId, 
    --                    Sporttype;
    --END;

BEGIN -- #Data
	CREATE TABLE #tmp_Data
					(
				winlostdate date,
					custID INT,
					matchID int,
					bettype         INT, 
					liveindicator   BIT,
					betchoice varchar(100),
					betteam varchar(100), 
					handicap smallmoney, 
					livescore varchar(100),
					QuarterX smallint,
					Stake			MONEY,
					MemberWinLoss   MONEY, 
					--SMAWinLoss      MONEY, 
					--ExtraPT         MONEY, 
					--Commission      MONEY, 
					RealIncome      MONEY, 
					VirtualIncome   MONEY, 
					VarianceIncome  MONEY, 
					RealTurnover    MONEY, 
					VirtualTurnover MONEY,
					Betcount int,
					minTransdate datetime
					);
     
END;
    
INSERT INTO #tmp_Data
		(
		winlostdate,
		custid, 
		matchID,
		bettype, 
		liveindicator,

		betchoice,
		betteam,
		handicap,
		livescore,
		QuarterX ,
		Stake,         
		MemberWinLoss ,
	--            SMAWinLoss, 
	--            ExtraPT, 
	--            Commission, 
		RealIncome, 
		VirtualIncome, 
		VarianceIncome, 
		RealTurnover, 
		VirtualTurnover,
		betcount,
		minTransdate
		)
		SELECT					
			winlostdate,
			b.custid, 
			b.matchID,
			bettype, 				
			liveindicator,
					
			case when bettype in (3,8) and betteam='h' then 'Over'
				when bettype in (3,8) and betteam='a' then 'Under' 
				when bettype in (610,401,402,403,404,615,616) and betteam='o' then 'Over'
				when bettype in (610,401,402,403,404,615,616) and betteam='u' then 'Under' 
				when bettype in (1,7, 124,125, 609) and betteam='h' then 'Home'
				when bettype in (1,7, 124,125, 609) and betteam='a' then 'Away'   
				when bettype in (5,15) and betteam='1' then 'Home' 
				when bettype in (5,15) and betteam='2' then 'Away' 
				when bettype in (5,15) and betteam='x' then 'Draw' 
				when bettype in (2,12) and betteam='h' then 'Odd'
				when bettype in (2,12) and betteam='a' then 'Even'  
				when bettype in (6,126,131,132)  then betteam  --total goal
				--when bettype in (4,30,152,158,165,166,392,399,405,413,414,416,494,495,703)  then  betteam   --correct score -- format text for excel berode paste
				else 'Not support now'
			end betchoice,
				betteam,
				(hdp1 - hdp2) Handicap,
				cast(livehomescore as varchar(20)) + ' - ' + cast(liveawayscore as varchar(20)) livescore,
				case when bettype in (609,610,611,612,613,614,615,616,617) then betid%800 
				else 0 end QuarterX,
				--betfrom,
				SUM(ABS(Stake)* actualrate) Stake,
				SUM((winlost - actual_stake) * actualrate) MemberWinLoss,
				-SUM( case when b.recommend in (5707545,52466) then 0 
				else
				(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm - (CASE
																							WHEN tpositiontaking = 1
																							THEN 0
																							ELSE winlost - actual_stake + b.scomm / (1 - b.tpositiontaking)
																						END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * actualrate 
				end) AS RealIncome, 
				-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost - CASE
																					WHEN tpositiontaking = 1
																					THEN 0
																					ELSE(winlost - actual_stake) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)
																				END) * virtualrate + (scomm - (CASE
																												WHEN tpositiontaking = 1
																												THEN 0
																												ELSE b.scomm / (1 - b.tpositiontaking)
																											END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * actualrate * CASE
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
					END) AS VirtualTurnover, 


			COUNT(1) betcount,
			MIN(transdate) minTransdate	
		FROM bettrans AS b WITH(NOLOCK)
				INNER JOIN #Match m ON b.MatchId = m.MatchId
			--LEFT JO	IN #ExtraPT_Sel e ON e.SuperID = b.srecommend AND e.Sporttype = 0
		WHERE   b.ruben = 1
				AND b.statusID IN(111, 112, 113)
				AND bettype not in (901,902,903,904,911,912,913,914) --exclude bettrade, cashout dummy ticket
				and currency<>20
					 
				and (@custid=0 or b.custid = @custid)
		GROUP BY
			winlostdate,
			b.custid, 
			b.matchID,
			bettype, 				
			liveindicator,
			case when bettype in (3,8) and betteam='h' then 'Over'
				when bettype in (3,8) and betteam='a' then 'Under' 
				when bettype in (610,401,402,403,404,615,616) and betteam='o' then 'Over'
				when bettype in (610,401,402,403,404,615,616) and betteam='u' then 'Under' 
				when bettype in (1,7, 124,125, 609, 612) and betteam='h' then 'Home'
				when bettype in (1,7, 124,125, 609, 612) and betteam='a' then 'Away'   
				when bettype in (5,15) and betteam='1' then 'Home' 
				when bettype in (5,15) and betteam='2' then 'Away' 
				when bettype in (5,15) and betteam='x' then 'Draw' 
				when bettype in (2,12) and betteam='h' then 'Odd'
				when bettype in (2,12) and betteam='a' then 'Even'  
				when bettype in (6,126,131,132)  then betteam  --total goal
				when bettype in (4,30,152,158,165,166,392,399,405,413,414,416,494,495,703)  then  betteam   --correct score -- format for excel
				else 'Not support now'
			end ,
				betteam,
				(hdp1 - hdp2) ,
				cast(livehomescore as varchar(20)) + ' - ' + cast(liveawayscore as varchar(20)),
				case when bettype in (609,610,611,612,613,614,615,616,617) then betid%800 
				else 0 end
		OPTION(RECOMPILE);

--match data
		SELECT
		m.matchid,
		m.leaguename, m.home, m.awayteam,                
		m.finalhomescore,
		m.finalawayscore,
		sum(stake) stake,
		sum(betcount)  betcount,
			SUM(MemberWinLoss) MemberWinLoss, 
			--SUM(SMAWinLoss) AS SMAWinLoss, 
			--SUM(ExtraPT) AS ExtraPT, 
			--SUM(Commission) Commission, 
			SUM(RealIncome) AS RealIncome, 
			SUM(VirtualIncome) VirtualIncome, 
			SUM(VarianceIncome) VarianceIncome, 
			SUM(RealTurnover) AS RealTurnover, 
			SUM(VirtualTurnover) AS VirtualTurnover, 
			case when SUM(RealTurnover) = 0 then 0 else SUM(RealIncome) /SUM(RealTurnover) end Margin
		FROM #tmp_Data AS b WITH(NOLOCK)
		--INNER JOIN bettype AS sb ON sb.typeid = b.BetType
		join #Match m on m.matchid = b.matchID
		--WHERE @IsLive > 1 OR b.liveindicator = @IsLive
		GROUP BY m.matchid,
		m.leaguename, m.home, m.awayteam	,
		m.finalhomescore,
		m.finalawayscore				
		order by  RealIncome       

     --All data
		SELECT			
			SUM(Betcount) Betcount, 
			SUM(b.Stake) MemberTO,
				--SUM(MemberWinLoss) MemberWinLoss, 
		--            SUM(SMAWinLoss) AS SMAWinLoss, 
		--            SUM(ExtraPT) AS ExtraPT, 
		--            SUM(Commission) Commission, 
			SUM(RealIncome) AS RealIncome, 
			SUM(VirtualIncome) VirtualIncome, 
			SUM(VarianceIncome) VarianceIncome, 
			SUM(RealTurnover) AS RealTurnover, 
			SUM(VirtualTurnover) AS VirtualTurnover, 
			case when SUM(RealTurnover) = 0 then 0 else SUM(RealIncome) /SUM(RealTurnover) end Margin
		FROM #tmp_Data AS b WITH(NOLOCK)
			--INNER JOIN bettype AS sb ON sb.typeid = b.BetType
			join #Match m on m.matchid = b.matchID


-- bettype and live data   
	SELECT					
		b.bettype, bt.typenamee BettypeName, b.liveindicator     ,          				
			SUM(MemberWinLoss) MemberWinLoss, 
			--SUM(SMAWinLoss) AS SMAWinLoss, 
			--SUM(ExtraPT) AS ExtraPT, 
			--SUM(Commission) Commission, 
			SUM(RealIncome) AS RealIncome, 
			SUM(VirtualIncome) VirtualIncome, 
			SUM(VarianceIncome) VarianceIncome, 
			SUM(RealTurnover) AS RealTurnover, 
			SUM(VirtualTurnover) AS VirtualTurnover, 
			case when SUM(RealTurnover) = 0 then 0 else SUM(RealIncome) /SUM(RealTurnover) end Margin
	FROM #tmp_Data AS b WITH(NOLOCK)
		--INNER JOIN bettype AS sb ON sb.typeid = b.BetType
		join #Match m on m.matchid = b.matchID
		left join bettype bt (nolock) on bt.typeid= b.bettype
               
	GROUP BY 
		b.bettype, bt.typenamee, b.liveindicator 
	order by RealIncome	  


--FIRST HANDICAP
select 
		--betchoice,livescore, 
		handicap, 
		MIN(minTransdate) minTransdate,

		sum(stake) stake,   
		sum(memberwinloss) memberwinloss,
		sum(RealTurnover) RealTurnover,   
		sum(RealIncome) RealIncome
from  #tmp_Data
where bettype in (1) and liveindicator=0
group by 
	 --betchoice,livescore,
	handicap
order by  minTransdate desc

--handicap data
select bettype,
		--betchoice,livescore, handicap, 
		case when bettype in (1,7,609) and (handicap>0 and betchoice = 'Home') then 'Favorite' 
		when bettype in (1,7,609) and (handicap>0 and betchoice = 'Away') then 'Underdog' 
		when bettype in (1,7,609) and (handicap<0 and betchoice = 'Away') then 'Favorite' 
		when bettype in (1,7,609) and (handicap<0 and betchoice = 'Home') then 'Underdog' 
		when bettype in (1,7,609) and (handicap=0 and betchoice = 'Home') then 'No HDP-Home' 
		when bettype in (1,7,609) and (handicap=0 and betchoice = 'Away') then 'No HDP-Away'
		else '' end Team,

		sum(stake) stake,   
		sum(memberwinloss) memberwinloss,
		sum(RealTurnover) RealTurnover,   
		sum(RealIncome) RealIncome
from  #tmp_Data
where bettype in (1,7,609)
group by bettype,
	-- betchoice,livescore,handicap,
	case when bettype in (1,7,609) and (handicap>0 and betchoice = 'Home') then 'Favorite' 
		when bettype in (1,7,609) and (handicap>0 and betchoice = 'Away') then 'Underdog' 
		when bettype in (1,7,609) and (handicap<0 and betchoice = 'Away') then 'Favorite' 
		when bettype in (1,7,609) and (handicap<0 and betchoice = 'Home') then 'Underdog' 
		when bettype in (1,7,609) and (handicap=0 and betchoice = 'Home') then 'No HDP-Home' 
		when bettype in (1,7,609) and (handicap=0 and betchoice = 'Away') then 'No HDP-Away'
		else '' end
order by bettype, memberwinloss desc



--OU data

select bettype,betchoice,livescore, t.QuarterX,
	sum(stake) stake,   sum(memberwinloss) memberwinloss,
	sum(t.Betcount)  Betcount
from  #tmp_Data t join dbo.Customer c (nolock)  on t.custid=c.custid
where bettype in (3,8,610)
--and site='haifa'
group by bettype, betchoice,livescore,t.QuarterX--, mi
order by bettype,memberwinloss desc


/*
drop table #SportBetType
drop table #Match
drop table #tmp_Data
*/