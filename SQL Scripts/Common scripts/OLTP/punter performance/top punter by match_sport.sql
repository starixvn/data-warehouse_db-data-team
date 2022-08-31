/*	Created by: Dan
	Task: get top punters of a match or performance of a specific punter
		
		folow SP Acc_Rpt_CompanyWinLoss_Soccer_BetType
	DB: DBACC/bodb02	
	Output: 
Revisions:

*/


declare @date SMALLDATETIME = '2020/06/02', 
       -- @EndDate   SMALLDATETIME,       
        @IsLive    INT           = 2, --@IsLive: 2 - ALL. 0 - Non-Live. 1 - Live
		@sporttype int = 1  
		, @site varchar(100) =''--'789y' -- '': all site, <>'': specific site , such as '755555'
		, @Type int = 2 -- 0: all; 1: normal soccer (no Saba); 2: Saba
		, @matchid int =  0 -- 0: all matches, <>0: specific matchid 
		, @custID int = 42837064 --0: all customers, <>0: specific customer 

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
			and (@matchid=0 or matchid=@matchid)

            UNION ALL

            SELECT orid, 
                    LeagueId, 
                    MatchCode,                 
					teamid homeid,
					0 awayid,
					o.kickofftime,null GlobalShowTime,
					 'outright' AS type
            FROM outright o WITH(NOLOCK)
            WHERE EventDate = @date
			and (@matchid=0)
        ) m
        INNER JOIN league l WITH(NOLOCK) ON m.LeagueId = l.LeagueId
		left join bodb02.dbo.Team h (nolock) on h.teamid=m.homeid
		left join bodb02.dbo.Team a (nolock) on a.teamid=m.awayid
        WHERE l.sporttype = @sporttype
		and (@Type=0
			or (@Type=1 and isnull(l.LeagueGroupID,0) not in (42,74))
			or (@Type=2 and isnull(l.LeagueGroupID,0) in (42,74))
			);
			;
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
					--srecommend      INT, 
					  custID int,
					  site varchar(50),
					  matchID int,
                      bettype         INT, 
                      --liveindicator   BIT,
					  --betfrom varchar(5)	,
					  
					  Stake MONEY,
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
               (custid,
				site, 
                matchID,
				bettype, 
    --            liveindicator,  
				--betfrom,    
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
					b.custid, 
					ag.site, 
					b.matchID,
                      bettype, 
                     -- liveindicator,
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
					 and (@custID=0 or b.custid=@custID)
               GROUP BY
					b.custid,
					 ag.site, 
						b.matchID,
                      bettype 
                      --liveindicator,
					  --betfrom
				OPTION(RECOMPILE);

	--select * from #Match


	--all punters
		SELECT
			-- top 1000
			b.custid, c.Username,
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
			join bodb02.dbo.Customer c (nolock) on c.custid = b.custID    
			left join DBWH.bodb_Account.dbo.tbl_site s on s.site=b.site
		GROUP BY b.custid, c.Username, b.site,
			 CASE
			    WHEN s.Site = 'CN88'
			    THEN 'CN88'
				WHEN s.isdeposit=0
			    THEN 'Credit'
			    WHEN s.isdeposit=1 
			    THEN 'Deposit'			    
			END
		ORDER BY MemberWinLoss desc
  


	drop table #SportBetType
	drop table #Agent
	drop table #Match
	drop table #tmp_Data
