



/*	Created by: Dan
	Task: get betchoice of a match 
		support main bettype 1,3,7,8
		folow SP Acc_Rpt_CompanyWinLoss_Soccer_BetType
	DB: DBACC/bodb02	
	Output: 
Revisions:

*/


declare @date SMALLDATETIME = '2020/05/18', 
       -- @EndDate   SMALLDATETIME,       
        @IsLive    INT           = 2, --@IsLive: 2 - ALL. 0 - Non-Live. 1 - Live
		@sporttype int = 1  
		, @site varchar(100) =''--'789y' -- '': all site, <>'': specific site , such as '755555'
		, @matchid int = 35971132 -- specific matchid 

    --SET NOCOUNT ON;
    BEGIN --#SportBetType
      
        CREATE TABLE #SportBetType(BetType INT);
        INSERT INTO #SportBetType
               SELECT s.BetType
               FROM dbo.f_SportBetTypeMatrix_Sel(1, 1, 0, 2, '', '', 0) s
               WHERE SubProduct NOT IN('MG-SuperLive', 'BT-Sold', 'BT-Bought', 'BT-Comm', 'BT-Winloss', 'Bet Builder')
               AND EventType IN(1, 2);
    END;
   
    BEGIN -- #Agent
        CREATE TABLE #Agent
        (CustId INT
         PRIMARY KEY, 
         Site   VARCHAR(50)
        );
        --IF @Site = 'CN88'
            BEGIN
                INSERT INTO #Agent
                       SELECT c.CustId, 
                              c.Site
                       FROM customer AS c WITH(NOLOCK)
                            INNER JOIN CS_CustSuper cn88 WITH(NOLOCK) ON c.srecommend = cn88.CustId
                       WHERE c.RoleID = 2;
        END;
           -- ELSE
            --IF @Site = 'Deposit'
                BEGIN
                    INSERT INTO #Agent
                           SELECT c.CustId, 
                                  c.Site
                           FROM customer AS c WITH(NOLOCK)
                                INNER JOIN Dep_CustSuper AS dep WITH(NOLOCK) ON c.srecommend = dep.CustId
                           WHERE c.RoleID = 2
                                 AND c.CustId NOT IN(52466, 5707545);
                    INSERT INTO #Agent
                           SELECT 5707545, 
                                  'BEST-ODDS';
            END;
            --    ELSE
                BEGIN
                    INSERT INTO #Agent
                           SELECT c.CustId, 
                                  c.Site
                           FROM customer AS c WITH(NOLOCK)
                                LEFT JOIN Dep_CustSuper AS dep WITH(NOLOCK) ON c.srecommend = dep.CustId
                                LEFT JOIN CS_CustSuper cn88 WITH(NOLOCK) ON c.srecommend = cn88.CustId
                           WHERE c.RoleID = 2
                                 AND c.CustId NOT IN(52466, 5707545)
                                AND dep.CustId IS NULL
                                AND cn88.CustId IS NULL;
                    INSERT INTO #Agent
                           SELECT 52466, 
                                  'XYZBET';--8RM;
            END;
    END;
    BEGIN -- #Match
	    SELECT DISTINCT 
                m.MatchId, 
                m.MatchCode, 
                m.type,
				m.leagueid, l.leaguename, h.teamname home, a.teamname awayteam,m.kickofftime kickofftime ,GlobalShowTime
		into #Match
        FROM
        (
            SELECT MatchId, 
                    LeagueId, 
                    MatchCode, 
					homeid,
					awayid,
					kickofftime,
					GlobalShowTime,
                    'match' AS type
            FROM Match WITH(NOLOCK)
            WHERE EventDate = @date
			and sporttype = @sporttype
			and matchID = @matchid
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
        INNER JOIN league l WITH(NOLOCK) ON m.LeagueId = l.LeagueId
		left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
		left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
        WHERE l.sporttype = @sporttype;
    END;
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
					  site varchar(50),
					  matchID int,
                      bettype         INT, 
                      liveindicator   BIT,
					  --betfrom varchar(5)	,
					  status		varchar(20),
					  betchoice varchar(100),
					  betteam varchar(100), 
					  handicap smallmoney, 
					  livescore varchar(100),

					  Stake			MONEY,
                      MemberWinLoss   MONEY, 
                      SMAWinLoss      MONEY, 
                      ExtraPT         MONEY, 
                      Commission      MONEY, 
                      RealIncome      MONEY, 
                      VirtualIncome   MONEY, 
                      VarianceIncome  MONEY, 
                      RealTurnover    MONEY, 
                      VirtualTurnover MONEY,
					  Betcount int
                     );
     
    END;
    
        INSERT INTO #tmp_Data
               (
				site, 
                matchID,
				bettype, 
                liveindicator,  
				--betfrom,   
				status ,
				betchoice,
				betteam,
				handicap,
				livescore,

				Stake,         
                MemberWinLoss, 
                SMAWinLoss, 
                ExtraPT, 
                Commission, 
                RealIncome, 
                VirtualIncome, 
                VarianceIncome, 
                RealTurnover, 
                VirtualTurnover,
				betcount
               )
               SELECT					
					ag.site, 
					b.matchID,
                    bettype, 				
                    liveindicator,
					status,
					case when bettype in (3,8) and betteam='h' then 'Over'
						 when bettype in (3,8) and betteam='a' then 'Under' 
						 when bettype in (1,7, 124,125) and betteam='h' then 'Home'
						 when bettype in (1,7, 124,125) and betteam='a' then 'Away'  
						 when bettype in (5,15) and betteam='1' then 'Home' 
						 when bettype in (5,15) and betteam='2' then 'Away' 
						 when bettype in (5,15) and betteam='x' then 'Draw' 
						 when bettype in (2,12) and betteam='h' then 'Odd'
						 when bettype in (2,12) and betteam='a' then 'Even'  
						 when bettype in (6,126,131,132)  then betteam  --total goal
						 when bettype in (4,30,152,158,165,166,392,399,405,413,414,416,494,495,703)  then  betteam   --correct score -- format for excel
						 else 'Not support now'
					 end betchoice,
					 betteam,
					 (hdp1 - hdp2) Handicap,
					 cast(livehomescore as varchar(20)) + ' - ' + cast(liveawayscore as varchar(20)) livescore,

                     --betfrom,
					 SUM(ABS(Stake)* actualrate) Stake,
                      SUM((winlost - actual_stake) * actualrate) MemberWinLoss, 
                     SUM((awinlost + mwinlost + swinlost) * actualrate) AS SMAWinLoss, 
                      -SUM((CASE
                               WHEN b.tpositiontaking = 1
                               THEN 0
                               ELSE(winlost - actual_stake) + b.scomm / (1 - b.tpositiontaking)
                           END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0) * actualrate) AS ExtraPT, 
                      SUM(scomm * actualrate) Commission, 
                      -SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm - (CASE
                                                                                                  WHEN tpositiontaking = 1
                                                                                                  THEN 0
                                                                                                  ELSE winlost - actual_stake + b.scomm / (1 - b.tpositiontaking)
                                                                                              END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * actualrate) AS RealIncome, 
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
						COUNT(1) betcount
               FROM bettrans AS b WITH(NOLOCK)
					INNER JOIN #Agent AS ag ON b.recommend = ag.custid
                    INNER JOIN #Match m ON b.MatchId = m.MatchId
                    --LEFT JOIN #ExtraPT_Sel e ON e.SuperID = b.srecommend AND e.Sporttype = 0
               WHERE b.winlostdate = @date
                     --AND m.type = CASE
                     --                 WHEN b.BetType = 10
                     --                 THEN 'outright'
                     --                 ELSE 'match'
                     --             END
                     AND b.ruben = 1
                     AND b.statusID IN(111, 112, 113)
					 and ( @site = '' or ag.site= @site)
					 and bettype in (1,3,7,8)
               GROUP BY
					ag.site, 
					b.matchID,
                    bettype, 				
                    liveindicator,
					status,
					case when bettype in (3,8) and betteam='h' then 'Over'
						 when bettype in (3,8) and betteam='a' then 'Under' 
						 when bettype in (1,7, 124,125) and betteam='h' then 'Home'
						 when bettype in (1,7, 124,125) and betteam='a' then 'Away'  
						 when bettype in (5,15) and betteam='1' then 'Home' 
						 when bettype in (5,15) and betteam='2' then 'Away' 
						 when bettype in (5,15) and betteam='x' then 'Draw' 
						 when bettype in (2,12) and betteam='h' then 'Odd'
						 when bettype in (2,12) and betteam='a' then 'Even' 
						 when bettype in (6,126,131,132)  then betteam  --total goal
						 when bettype in (4,30,152,158,165,166,392,399,405,413,414,416,494,495,703)  then betteam   --correct score -- format for excel
						 else 'Not support now'						
					 end ,
					 betteam,
					 (hdp1 - hdp2) ,
					 cast(livehomescore as varchar(20)) + ' - ' + cast(liveawayscore as varchar(20))
				OPTION(RECOMPILE);


	--betchoice
		SELECT
			b.bettype,
			bt.typenamee bettypeName,
			liveindicator,
			b.betchoice,
			b.handicap,
			LiveScore,
			b.site,
			 CASE
			    WHEN s.Site = 'CN88'
			    THEN 'CN88'
				WHEN s.isdeposit=0
			    THEN 'Credit'
			    WHEN s.isdeposit=1 
			    THEN 'Deposit'			    
			END AS SiteType, 
            sum(stake) stake,
			sum(betcount)  betcount,
            SUM(MemberWinLoss) MemberWinLoss, 
            SUM(SMAWinLoss) AS SMAWinLoss, 
            SUM(ExtraPT) AS ExtraPT, 
            SUM(Commission) Commission, 
            SUM(RealIncome) AS RealIncome, 
            SUM(VirtualIncome) VirtualIncome, 
            SUM(VarianceIncome) VarianceIncome, 
            SUM(RealTurnover) AS RealTurnover, 
            SUM(VirtualTurnover) AS VirtualTurnover, 
				case when SUM(RealTurnover) = 0 then 0 else SUM(RealIncome) /SUM(RealTurnover) end Margin
        FROM #tmp_Data AS b WITH(NOLOCK)   
			left join DBWH.bodb_Account.dbo.tbl_site s on s.site=b.site
			left join bodb02.dbo.bettype bt on bt.typeid=b.bettype
		--where bettype=6
		GROUP BY b.bettype,
			bt.typenamee ,
			liveindicator,
			b.betchoice,
			b.handicap,
			LiveScore,
			b.site,
			 CASE
			    WHEN s.Site = 'CN88'
			    THEN 'CN88'
				WHEN s.isdeposit=0
			    THEN 'Credit'
			    WHEN s.isdeposit=1 
			    THEN 'Deposit'			    
			END
		ORDER BY MemberWinLoss desc
  
	/*
	drop table #SportBetType
	drop table #Agent
	drop table #Match
	drop table #tmp_Data
	*/