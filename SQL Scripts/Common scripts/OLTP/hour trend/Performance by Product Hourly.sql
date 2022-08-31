USE [bodb02]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON;
/*
Created by Tom

Task: Explore data by hourly

Param's Explanation:
	@_Date: Winlostdate
	@ProductID: Product ID (SELECT ProductID,	ProductName,	Description FROM bodb02.dbo.Products )
		0: Get ALL
		-1	MG-SuperLive
		-2	Bettrade 
		-3	Bet Builder
		1   SportsBook
		2   Racing
*/
DECLARE @_Date SMALLDATETIME= '20200510'

DECLARE @ProductID INT = 27

DECLARE @MoveBetDate SMALLDATETIME
DECLARE @BalanceUpDate SMALLDATETIME

SELECT 
	@BalanceUpDate = MIN(EventDate),
	@MoveBetDate = MAX(Eventdate)
 From bodb02.dbo.match14 m WITH (NOLOCK);

SELECT 
	@_Date ToDate,
	@BalanceUpDate  BalanceUpDate,
	@MoveBetDate MoveBetDate 

IF OBJECT_ID('tempdb..#tmpMatch') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatch
	END
   CREATE TABLE #tmpMatch(
	   MatchID     INT
	 , kickofftime DATETIME
	 , LeagueID    INT
	 , HomeID       INT
	 , AwayID       INT
	)

IF @_Date >@MoveBetDate 
	INSERT INTO #tmpMatch(MatchID, kickofftime,LeagueID, HomeID, AwayID )
	SELECT m.MatchID, kickofftime,m.LeagueID, m.HomeID, m.AwayID
	FROM bodb02.dbo.match m WITH(NOLOCK)
	WHERE m.eventdate = @_Date

IF @_Date BETWEEN @BalanceUpDate AND @MoveBetDate
	INSERT INTO #tmpMatch(MatchID, kickofftime,LeagueID, HomeID, AwayID )
	SELECT m.MatchID, kickofftime,m.LeagueID, m.HomeID, m.AwayID
	FROM bodb02.dbo.match14 m WITH(NOLOCK)
	WHERE m.eventdate = @_Date

IF @_Date < @BalanceUpDate
	INSERT INTO #tmpMatch(MatchID, kickofftime,LeagueID, HomeID, AwayID )
	SELECT m.MatchID,  kickofftime,m.LeagueID, m.HomeID, m.AwayID
	FROM bodb_archive.dbo.match_bk m WITH(NOLOCK)
	where m.eventdate = @_Date

IF OBJECT_ID('tempdb..#tmpProduct') IS NOT NULL
	BEGIN
		DROP TABLE #tmpProduct
	END
	
CREATE TABLE #tmpProduct(
   ProductID     INT
 , ProductName    VARCHAR(500)
 , Bettype       INT
)
	
INSERT INTO #tmpProduct
SELECT ProductID,ProductName,Bettype FROM DBWH.bodb_Account.dbo.Product_Bettype
WHERE (ProductID = @ProductID OR @ProductID = 0);

IF OBJECT_ID('tempdb..#SportBettype') IS NOT NULL
	BEGIN
		DROP TABLE #SportBettype
	END
CREATE TABLE #SportBettype(
   ProductID     INT
 , Bettype       INT
 , EventType     INT
 , SubProduct    VARCHAR(500)
 , RefTable      TINYINT
 , CasinoType    TINYINT);
INSERT INTO #SportBettype(ProductID
				  , Bettype
				  , EventType
				  , SubProduct
				  , RefTable
				  , CasinoType)
	SELECT ProductID
		, Bettype
		, EventType
		, SubProduct
		, RefTable
		, CasinoType
	FROM dbo.f_SportBettypeMatrix_Sel
		(0, 0, 0, 2, '', '', 1)
	WHERE bettype NOT IN(911, 912)
	AND bettype  IN (SELECT DISTINCT bettype  FROM #tmpProduct)

IF OBJECT_ID('tempdb..#Site') IS NOT NULL
	BEGIN
		DROP TABLE #Site
	END
	
CREATE TABLE #Site (Recommend int PRIMARY KEY, SiteID int)

IF OBJECT_ID('tempdb..#FactCustWinloss') IS NOT NULL
	BEGIN
		DROP TABLE #FactCustWinloss
	END
	
CREATE TABLE #FactCustWinloss(
	DataSource Varchar(100) NULL,
	[RptDate] DATE NOT NULL,
	[TransDate] DATETIME NOT NULL,
	[SiteID] [int] NULL,
	[SportType] [int] NULL,
	[BetType] [int] NULL,
	[TicketStatus] [int] NULL,
	[LiveStatus] [int] NULL,
	[LeagueID] [int] NULL,
	[MatchID] [int] NULL,
	[SuperID] [int] NULL,
	[MasterID] [int] NULL,
	[AgentID] [int] NULL,
	[CustID] [int] NULL,
	ActualRate FLOAT NULL,
	VarianceVR [decimal](19, 6) NULL,
	[Stake] [decimal](19, 4) NULL,
	[ActualStake] [decimal](19, 4) NOT NULL,
	[WinlossIBC] [decimal](19, 4) NOT NULL,
	[WinlossS] [decimal](19, 4) NOT NULL,
	[WinlossM] [decimal](19, 4) NOT NULL,
	[WinlossA] [decimal](19, 4) NOT NULL,
	[WinlossP] [decimal](19, 4) NOT NULL,
	[TurnoverIBC] [decimal](19, 4) NOT NULL,
	[TurnoverS] [decimal](19, 4) NOT NULL,
	[TurnoverM] [decimal](19, 4) NOT NULL,
	[TurnoverA] [decimal](19, 4) NOT NULL,
	[CommissionS] [decimal](19, 4) NOT NULL,
	[CommissionM] [decimal](19, 4) NOT NULL,
	[CommissionA] [decimal](19, 4) NOT NULL,
	[CommissionP] [decimal](19, 4) NOT NULL,
	[ExtraWL] [decimal](19, 6) NOT NULL,
	[ExtraTO] [decimal](19, 6) NOT NULL,
	[ExtraComm] [decimal](19, 8) NOT NULL,
	[BetCount] [int] NOT NULL
)

IF OBJECT_ID('tempdb..#SiteType') IS NOT NULL
	BEGIN
		DROP TABLE #SiteType
	END
	
CREATE TABLE #SiteType (SiteID INT,IsDeposit INT,SiteName VARCHAR(100)  )

INSERT INTO #SiteType
SELECT
	SiteID, IsDeposit, Site 
FROM
	bodb02.dbo.Site si WITH (NOLOCK) 

INSERT INTO #Site
SELECT
	recommend, MIN(SiteID) AS SiteID 
FROM
	bodb02.dbo.vw_Customer cu WITH (NOLOCK)
	LEFT JOIN bodb02.dbo.Site si WITH (NOLOCK)
		ON cu.site = si.site
WHERE
	roleid = 2
GROUP BY recommend
	
--Bettrans
IF @_Date>@MoveBetDate
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype WHERE RefTable IN(0,3))
			INSERT INTO #FactCustWinloss
			(DataSource
			,[RptDate]
			,[TransDate]
			,SiteID		
			,SportType	
			,[BetType]
			,TicketStatus
			,LiveStatus
			,LeagueID
			,MatchID
			,CustID
			,actualrate
			,VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,Stake
			,ActualStake
			,WinlossIBC
			,WinlossS
			,WinlossM
			,WinlossA
			,WinlossP
			,TurnoverIBC
			,TurnoverS
			,TurnoverM
			,TurnoverA
			,CommissionS
			,CommissionM
			,CommissionA
			,CommissionP
			,ExtraWL
			,ExtraTO
			,ExtraComm
			,BetCount)
			SELECT 
			/************************************************************DIMENSION**********************************************************************************/
				'Bettrans' DataSource
				,mc.winlostdate [RptDate]
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END AS SiteID		
				,CASE 
						WHEN mc.bettype IN (9,29) AND mc.liveawayscore = 3 THEN - 2 -- Combined Sport
						WHEN mc.bettype IN (9,29) AND mc.liveawayscore = 1 THEN 1 --Soccer
						WHEN  mc.bettype = 10 THEN ISNULL(l.sporttype,-1)
						ELSE ISNULL(CAST(m.sporttype AS INT),-1)
				END	 SportType	
				,mc.bettype [BetType]
				,CASE WHEN ABS(mc.modds) = 0.25
							AND mc.statusid IN (112,113) THEN mc.statusid+2 ELSE mc.statusid END AS TicketStatus
				,CASE WHEN mc.bettype IN (9,29) THEN mc.livehomescore ELSE CAST(mc.liveindicator AS tinyint) END LiveStatus --0: Nonlive | 1:Live | 2: Mixed		
				,CASE WHEN  spm.EventType =1 THEN ISNULL(m.LeagueID,-1) 
					WHEN mc.bettype = 10 THEN ISNULL(o.LeagueID,-1) 
					WHEN spm.EventType =3 THEN ISNULL(vsr.LeagueID,-1) 
					ELSE -1 END LeagueID	
				,mc.MatchID  AS MatchID 
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6)) AS VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,SUM(CASE WHEN bt.BetType IS NOT NULL THEN  abs(stake) ELSE stake END) Stake
			,SUM(Actual_Stake) ActualStake
			,SUM(CASE WHEN mc.bettype IN (2199, 2399, 2999, 4300) THEN 0 --Progressive Jackpot
				ELSE  (mc.winlost - mc.actual_stake) + swinlost + mwinlost + awinlost END ) WinlossIBC
			,SUM(swinlost) WinlossS
			,SUM(mwinlost) WinlossM
			,SUM(awinlost) WinlossA
			,SUM(winlost-actual_stake) WinlossP
			,SUM(abs(stake)* (1-tpositiontaking)) TurnoverIBC
			,SUM(abs(stake)* spositiontaking) TurnoverS
			,SUM(abs(stake) * mpositiontaking) TurnoverM
			,SUM(abs(stake) * apositiontaking) TurnoverA
			,SUM(scomm) CommissionS
			,SUM(acomm) CommissionM
			,SUM(comm) CommissionA
			,SUM(playercomm) CommissionP
			,SUM(CASE 
					WHEN mc.bettype IN (2199, 2399, 2999, 4300) THEN 0 --Progressive Jackpot
					WHEN tpositiontaking = 1  THEN 0 
					  ELSE (winlost - actual_stake) * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				 END) ExtraWL
			,SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE abs(stake)* CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				END) ExtraTO	
			,CAST(SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE scomm * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8)) / (1 - tpositiontaking) END
			) AS [decimal](19, 6)) ExtraComm
			----
			,SUM(CASE
						WHEN mc.bettype IN (500,904) THEN 0 
		 				WHEN td.[VendorID] IN (14) THEN 0 
		 				WHEN mc.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4300) THEN 0 
						ELSE 1 END) AS BetCount
			
			FROM bodb02.dbo.bettrans AS mc WITH (NOLOCK)		
			LEFT JOIN (Select distinct bettype FROM bodb02.dbo.SportBettypeMatrix WITH (NOLOCK)
						WHERE ProductID = 1 and SubProduct = '') bt on bt.BetType =mc.bettype
			LEFT JOIN #Site s WITH (NOLOCK) ON mc.Recommend = s.Recommend
			LEFT JOIN bodb02.dbo.TradeCust AS td WITH (NOLOCK) ON mc.custid = td.custid	
			LEFT JOIN #SportBettype spm ON spm.RefTable IN( 0,3) AND spm.Bettype = mc.Bettype
			LEFT JOIN bodb02.dbo.match m WITH (NOLOCK) ON mc.matchid = m.matchid AND mc.bettype <>10 AND spm.EventType =1
			LEFT JOIN bodb02.dbo.outright  o WITH (NOLOCK) ON mc.matchid = o.orid AND mc.bettype =10
			LEFT JOIN bodb02.dbo.League  l WITH (NOLOCK) ON l.leagueid = o.leagueid		
			LEFT JOIN bodb02.dbo.VSRaceInfo  vsr WITH (NOLOCK) ON mc.matchid = vsr.EventID AND spm.EventType =3

			WHERE mc.winlostdate = @_Date	
				AND mc.statusID IN (111,112,113)
				AND mc.Currency NOT IN (20,27,28)		
				AND mc.ruben = 1 				
				AND spm.Bettype IS NOT NULL --EXISTS(SELECT TOP 1 1 FROM #SportBettype spm where spm.RefTable IN( 0,3) AND spm.Bettype = mc.Bettype)
			GROUP BY mc.winlostdate	
				,[TransDate]			
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END
				,CASE 
						WHEN mc.bettype IN (9,29) AND mc.liveawayscore = 3 THEN - 2 -- Combined Sport
						WHEN mc.bettype IN (9,29) AND mc.liveawayscore = 1 THEN 1 --Soccer
						WHEN  mc.bettype = 10 THEN ISNULL(l.sporttype,-1)
						ELSE ISNULL(CAST(m.sporttype AS INT),-1)
				END	
				,mc.bettype
				,CASE WHEN ABS(mc.modds) = 0.25
							AND mc.statusid IN (112,113) THEN mc.statusid+2  ELSE mc.statusid END
				,CASE WHEN mc.bettype IN (9,29) THEN mc.livehomescore ELSE CAST(mc.liveindicator AS tinyint) END --0: Nonlive | 1:Live | 2: Mixed	
				,CASE WHEN  spm.EventType =1 THEN ISNULL(m.LeagueID,-1) 
					WHEN mc.bettype = 10 THEN ISNULL(o.LeagueID,-1) 
					WHEN spm.EventType =3 THEN ISNULL(vsr.LeagueID,-1) 
					ELSE -1 END 
				,mc.MatchID
				,mc.srecommend
				,mc.mrecommend
				,mc.recommend
				,mc.CustID
				,mc.actualrate			
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6))	
			OPTION (MAXDOP 10)
				
		   --2. Bettrans RNG
		 IF EXISTS(SELECT TOP 1 1 FROM #SportBettype WHERE RefTable =1)
			INSERT INTO #FactCustWinloss
			(DataSource
			,[RptDate]
			,[TransDate]
			,SiteID		
			,SportType	
			,[BetType]
			,TicketStatus
			,LiveStatus
			,LeagueID
			,MatchID 
			,CustID
			,actualrate
			,VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,Stake
			,ActualStake
			,WinlossIBC
			,WinlossS
			,WinlossM
			,WinlossA
			,WinlossP
			,TurnoverIBC
			,TurnoverS
			,TurnoverM
			,TurnoverA
			,CommissionS
			,CommissionM
			,CommissionA
			,CommissionP
			,ExtraWL
			,ExtraTO
			,ExtraComm
			,BetCount)
			SELECT 
			/************************************************************DIMENSION**********************************************************************************/
				'Bettrans' DataSource
				,mc.winlostdate [RptDate]
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END AS SiteID		
				,mc.productID	 SportType	
				,mc.GameID [BetType]
				,mc.statusid TicketStatus
				,0 LiveStatus --0: Nonlive | 1:Live | 2: Mixed		
				,0 LeagueID	
				,0 MatchID
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6)) AS VarianceVR	
				
			/************************************************************MEASURE**********************************************************************************/
			,SUM((stake)) Stake
			,SUM(Actual_Stake) ActualStake
			,SUM(CASE WHEN mc.gameId IN(2198, 2398, 2998)
						THEN ContributionRate * BetStake + awinlost + mwinlost + swinlost
					WHEN mc.gameId IN (2199, 2399, 2999, 4300) THEN 0 --Progressive Jackpot
					ELSE (mc.winlost - mc.actual_stake) + swinlost + mwinlost + awinlost  END) WinlossIBC
			,SUM(swinlost) WinlossS
			,SUM(mwinlost) WinlossM
			,SUM(awinlost) WinlossA
			,SUM(winlost-actual_stake) WinlossP
			,SUM(abs(stake)* (1-tpositiontaking)) TurnoverIBC
			,SUM(abs(stake)* spositiontaking) TurnoverS
			,SUM(abs(stake) * mpositiontaking) TurnoverM
			,SUM(abs(stake) * apositiontaking) TurnoverA
			,SUM(scomm) CommissionS
			,SUM(acomm) CommissionM
			,SUM(comm) CommissionA
			,SUM(playercomm) CommissionP
			,SUM(CASE WHEN tpositiontaking = 1  THEN 0 		
					WHEN mc.gameId IN (2199, 2399, 2999, 4300) THEN 0 --Progressive Jackpot
					 WHEN mc.gameId IN(2198, 2398, 2998) THEN ContributionRate * BetStake* CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
					  ELSE (winlost - actual_stake) * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				 END) ExtraWL
			,SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE abs(stake)* CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				END) ExtraTO	
			,CAST(SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE scomm * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8)) / (1 - tpositiontaking) END
			) AS [decimal](19, 6)) ExtraComm
			----
			,SUM(CASE WHEN mc.GameID IN (500,904) THEN 0
				WHEN mc.GameID IN (2198, 2398, 2998, 2199, 2399, 2999, 4300) THEN 0 ELSE 1 END) AS BetCount
			
			FROM bodb02.dbo.bettransRnG AS mc WITH (NOLOCK)
			LEFT JOIN #Site s WITH (NOLOCK) ON mc.Recommend = s.Recommend
			WHERE mc.winlostdate = @_Date	
				AND mc.statusID IN (111,112,113)
				AND mc.Currency NOT IN (20,27,28)				
				AND EXISTS(SELECT TOP 1 1 FROM #SportBettype spm where spm.RefTable IN( 1) AND spm.Bettype = mc.gameID)
			GROUP BY mc.winlostdate
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END		
				,mc.productID	
				,mc.GameID
				,mc.statusid				
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6))
			OPTION (MAXDOP 10)
		   
		   --3. Bettrans LC
		 IF EXISTS(SELECT TOP 1 1 FROM #SportBettype WHERE RefTable =2)
			INSERT INTO #FactCustWinloss
			(DataSource
			,[RptDate]
			,[TransDate]
			,SiteID		
			,SportType	
			,[BetType]
			,TicketStatus
			,LiveStatus
			,LeagueID
			,MatchID 
			,CustID
			,actualrate
			,VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,Stake
			,ActualStake
			,WinlossIBC
			,WinlossS
			,WinlossM
			,WinlossA
			,WinlossP
			,TurnoverIBC
			,TurnoverS
			,TurnoverM
			,TurnoverA
			,CommissionS
			,CommissionM
			,CommissionA
			,CommissionP
			,ExtraWL
			,ExtraTO
			,ExtraComm
			,BetCount)
			SELECT 
			/************************************************************DIMENSION**********************************************************************************/
				'Bettrans' DataSource
				,mc.winlostdate [RptDate]
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END AS SiteID		
				,mc.productID	 SportType	
				,mc.GameID [BetType]
				,mc.statusid TicketStatus
				,0 LiveStatus --0: Nonlive | 1:Live | 2: Mixed		
				,0 LeagueID	
				,0 MatchID 
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6)) AS VarianceVR	
				
			/************************************************************MEASURE**********************************************************************************/
			,SUM((stake)) Stake
			,SUM(Actual_Stake) ActualStake
			,SUM((mc.winlost - mc.actual_stake) + swinlost + mwinlost + awinlost ) WinlossIBC
			,SUM(swinlost) WinlossS
			,SUM(mwinlost) WinlossM
			,SUM(awinlost) WinlossA
			,SUM(winlost-actual_stake) WinlossP
			,SUM(abs(stake)* (1-tpositiontaking)) TurnoverIBC
			,SUM(abs(stake)* spositiontaking) TurnoverS
			,SUM(abs(stake) * mpositiontaking) TurnoverM
			,SUM(abs(stake) * apositiontaking) TurnoverA
			,SUM(scomm) CommissionS
			,SUM(acomm) CommissionM
			,SUM(comm) CommissionA
			,SUM(playercomm) CommissionP
			,SUM(CASE WHEN tpositiontaking = 1  THEN 0 
					  ELSE (winlost - actual_stake) * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				 END) ExtraWL
			,SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE abs(stake)* CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				END) ExtraTO	
			,CAST(SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE scomm * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8)) / (1 - tpositiontaking) END
			) AS [decimal](19, 6)) ExtraComm
			----
			,SUM(CASE WHEN mc.GameID IN (500,904) THEN 0
				WHEN mc.GameID IN (2198, 2398, 2998, 2199, 2399, 2999, 4300) THEN 0 ELSE 1 END) AS BetCount
			
			FROM bodb02.dbo.bettransLC AS mc WITH (NOLOCK)
			LEFT JOIN #Site s WITH (NOLOCK) ON mc.Recommend = s.Recommend
			WHERE mc.winlostdate = @_Date	
				AND mc.statusID IN (111,112,113)
				AND mc.Currency NOT IN (20,27,28)				
				AND EXISTS(SELECT TOP 1 1 FROM #SportBettype spm where spm.RefTable IN( 2) AND spm.Bettype = mc.gameID)
			GROUP BY mc.winlostdate
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END		
				,mc.productID	
				,mc.GameID
				,mc.statusid				
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6))
			OPTION (MAXDOP 10)
	END	--Bettrans

--Bettrans14
IF @_Date BETWEEN @BalanceUpDate AND @MoveBetDate
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype WHERE RefTable IN(0,3))
			INSERT INTO #FactCustWinloss
			(DataSource
			,[RptDate]
			,[TransDate]
			,SiteID		
			,SportType	
			,[BetType]
			,TicketStatus
			,LiveStatus
			,LeagueID
			,MatchID
			,CustID
			,actualrate
			,VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,Stake
			,ActualStake
			,WinlossIBC
			,WinlossS
			,WinlossM
			,WinlossA
			,WinlossP
			,TurnoverIBC
			,TurnoverS
			,TurnoverM
			,TurnoverA
			,CommissionS
			,CommissionM
			,CommissionA
			,CommissionP
			,ExtraWL
			,ExtraTO
			,ExtraComm
			,BetCount)
			SELECT 
			/************************************************************DIMENSION**********************************************************************************/
				'Bettrans' DataSource
				,mc.winlostdate [RptDate]
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END AS SiteID		
				,CASE 
						WHEN mc.bettype IN (9,29) AND mc.liveawayscore = 3 THEN - 2 -- Combined Sport
						WHEN mc.bettype IN (9,29) AND mc.liveawayscore = 1 THEN 1 --Soccer
						WHEN  mc.bettype = 10 THEN ISNULL(l.sporttype,-1)
						ELSE ISNULL(CAST(m.sporttype AS INT),-1)
				END	 SportType	
				,mc.bettype [BetType]
				,CASE WHEN ABS(mc.modds) = 0.25
							AND mc.statusid IN (112,113) THEN mc.statusid+2 ELSE mc.statusid END AS TicketStatus
				,CASE WHEN mc.bettype IN (9,29) THEN mc.livehomescore ELSE CAST(mc.liveindicator AS tinyint) END LiveStatus --0: Nonlive | 1:Live | 2: Mixed		
				,CASE WHEN  spm.EventType =1 THEN ISNULL(m.LeagueID,-1) 
					WHEN mc.bettype = 10 THEN ISNULL(o.LeagueID,-1) 
					WHEN spm.EventType =3 THEN ISNULL(vsr.LeagueID,-1) 
					ELSE -1 END  LeagueID	
				,mc.MatchID  AS MatchID 
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6)) AS VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,SUM(CASE WHEN bt.BetType IS NOT NULL THEN  abs(stake) ELSE stake END) Stake
			,SUM(Actual_Stake) ActualStake
			,SUM(CASE WHEN mc.bettype IN (2199, 2399, 2999, 4300) THEN 0 --Progressive Jackpot
				ELSE  (mc.winlost - mc.actual_stake) + swinlost + mwinlost + awinlost END ) WinlossIBC
			,SUM(swinlost) WinlossS
			,SUM(mwinlost) WinlossM
			,SUM(awinlost) WinlossA
			,SUM(winlost-actual_stake) WinlossP
			,SUM(abs(stake)* (1-tpositiontaking)) TurnoverIBC
			,SUM(abs(stake)* spositiontaking) TurnoverS
			,SUM(abs(stake) * mpositiontaking) TurnoverM
			,SUM(abs(stake) * apositiontaking) TurnoverA
			,SUM(scomm) CommissionS
			,SUM(acomm) CommissionM
			,SUM(comm) CommissionA
			,SUM(playercomm) CommissionP
			,SUM(CASE 
					WHEN mc.bettype IN (2199, 2399, 2999, 4300) THEN 0 --Progressive Jackpot
					WHEN tpositiontaking = 1  THEN 0 
					  ELSE (winlost - actual_stake) * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				 END) ExtraWL
			,SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE abs(stake)* CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				END) ExtraTO	
			,CAST(SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE scomm * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8)) / (1 - tpositiontaking) END
			) AS [decimal](19, 6)) ExtraComm
			----
			,SUM(CASE
						WHEN mc.bettype IN (500,904) THEN 0 
		 				WHEN td.[VendorID] IN (14) THEN 0 
		 				WHEN mc.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4300) THEN 0 
						ELSE 1 END) AS BetCount
			
			FROM bodb02.dbo.bettrans14 AS mc WITH (NOLOCK)		
			LEFT JOIN (Select distinct bettype FROM bodb02.dbo.SportBettypeMatrix WITH (NOLOCK)
						WHERE ProductID = 1 and SubProduct = '') bt on bt.BetType =mc.bettype
			LEFT JOIN #Site s WITH (NOLOCK) ON mc.Recommend = s.Recommend
			LEFT JOIN bodb02.dbo.TradeCust AS td WITH (NOLOCK) ON mc.custid = td.custid	
			LEFT JOIN #SportBettype spm ON spm.RefTable IN( 0,3) AND spm.Bettype = mc.Bettype
			LEFT JOIN bodb02.dbo.match14 m WITH (NOLOCK) ON mc.matchid = m.matchid AND mc.bettype <>10 AND spm.EventType =1
			LEFT JOIN bodb02.dbo.outright14  o WITH (NOLOCK) ON mc.matchid = o.orid AND mc.bettype =10
			LEFT JOIN bodb02.dbo.League  l WITH (NOLOCK) ON l.leagueid = o.leagueid		
			LEFT JOIN bodb02.dbo.VSRaceInfo  vsr WITH (NOLOCK) ON mc.matchid = vsr.EventID AND spm.EventType =3

			WHERE mc.winlostdate = @_Date	
				AND mc.statusID IN (111,112,113)
				AND mc.Currency NOT IN (20,27,28)		
				AND mc.ruben = 1 				
				AND spm.Bettype IS NOT  NULL--EXISTS(SELECT TOP 1 1 FROM #SportBettype spm where spm.RefTable IN( 0,3) AND spm.Bettype = mc.Bettype)
			GROUP BY mc.winlostdate	
				,[TransDate]			
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END
				,CASE 
						WHEN mc.bettype IN (9,29) AND mc.liveawayscore = 3 THEN - 2 -- Combined Sport
						WHEN mc.bettype IN (9,29) AND mc.liveawayscore = 1 THEN 1 --Soccer
						WHEN  mc.bettype = 10 THEN ISNULL(l.sporttype,-1)
						ELSE ISNULL(CAST(m.sporttype AS INT),-1)
				END	
				,mc.bettype
				,CASE WHEN ABS(mc.modds) = 0.25
							AND mc.statusid IN (112,113) THEN mc.statusid+2  ELSE mc.statusid END
				,CASE WHEN mc.bettype IN (9,29) THEN mc.livehomescore ELSE CAST(mc.liveindicator AS tinyint) END --0: Nonlive | 1:Live | 2: Mixed	
				,CASE WHEN  spm.EventType =1 THEN ISNULL(m.LeagueID,-1) 
					WHEN mc.bettype = 10 THEN ISNULL(o.LeagueID,-1) 
					WHEN spm.EventType =3 THEN ISNULL(vsr.LeagueID,-1) 
					ELSE -1 END 
				,mc.MatchID
				,mc.srecommend
				,mc.mrecommend
				,mc.recommend
				,mc.CustID
				,mc.actualrate			
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6))	
			OPTION (MAXDOP 10)
				
		   --2. Bettrans RNG
		 IF EXISTS(SELECT TOP 1 1 FROM #SportBettype WHERE RefTable =1)
			INSERT INTO #FactCustWinloss
			(DataSource
			,[RptDate]
			,[TransDate]
			,SiteID		
			,SportType	
			,[BetType]
			,TicketStatus
			,LiveStatus
			,LeagueID
			,MatchID 
			,CustID
			,actualrate
			,VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,Stake
			,ActualStake
			,WinlossIBC
			,WinlossS
			,WinlossM
			,WinlossA
			,WinlossP
			,TurnoverIBC
			,TurnoverS
			,TurnoverM
			,TurnoverA
			,CommissionS
			,CommissionM
			,CommissionA
			,CommissionP
			,ExtraWL
			,ExtraTO
			,ExtraComm
			,BetCount)
			SELECT 
			/************************************************************DIMENSION**********************************************************************************/
				'Bettrans' DataSource
				,mc.winlostdate [RptDate]
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END AS SiteID		
				,mc.productID	 SportType	
				,mc.GameID [BetType]
				,mc.statusid TicketStatus
				,0 LiveStatus --0: Nonlive | 1:Live | 2: Mixed		
				,0 LeagueID	
				,0 MatchID
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6)) AS VarianceVR	
				
			/************************************************************MEASURE**********************************************************************************/
			,SUM((stake)) Stake
			,SUM(Actual_Stake) ActualStake
			,SUM(CASE WHEN mc.gameId IN(2198, 2398, 2998)
						THEN ContributionRate * BetStake + awinlost + mwinlost + swinlost
					WHEN mc.gameId IN (2199, 2399, 2999, 4300) THEN 0 --Progressive Jackpot
					ELSE (mc.winlost - mc.actual_stake) + swinlost + mwinlost + awinlost  END) WinlossIBC
			,SUM(swinlost) WinlossS
			,SUM(mwinlost) WinlossM
			,SUM(awinlost) WinlossA
			,SUM(winlost-actual_stake) WinlossP
			,SUM(abs(stake)* (1-tpositiontaking)) TurnoverIBC
			,SUM(abs(stake)* spositiontaking) TurnoverS
			,SUM(abs(stake) * mpositiontaking) TurnoverM
			,SUM(abs(stake) * apositiontaking) TurnoverA
			,SUM(scomm) CommissionS
			,SUM(acomm) CommissionM
			,SUM(comm) CommissionA
			,SUM(playercomm) CommissionP
			,SUM(CASE WHEN tpositiontaking = 1  THEN 0 		
					WHEN mc.gameId IN (2199, 2399, 2999, 4300) THEN 0 --Progressive Jackpot
					 WHEN mc.gameId IN(2198, 2398, 2998) THEN ContributionRate * BetStake* CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
					  ELSE (winlost - actual_stake) * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				 END) ExtraWL
			,SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE abs(stake)* CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				END) ExtraTO	
			,CAST(SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE scomm * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8)) / (1 - tpositiontaking) END
			) AS [decimal](19, 6)) ExtraComm
			----
			,SUM(CASE WHEN mc.GameID IN (500,904) THEN 0
				WHEN mc.GameID IN (2198, 2398, 2998, 2199, 2399, 2999, 4300) THEN 0 ELSE 1 END) AS BetCount
			
			FROM bodb02.dbo.bettransRnG14 AS mc WITH (NOLOCK)
			LEFT JOIN #Site s WITH (NOLOCK) ON mc.Recommend = s.Recommend
			WHERE mc.winlostdate = @_Date	
				AND mc.statusID IN (111,112,113)
				AND mc.Currency NOT IN (20,27,28)				
				AND EXISTS(SELECT TOP 1 1 FROM #SportBettype spm where spm.RefTable IN( 1) AND spm.Bettype = mc.gameID)
			GROUP BY mc.winlostdate
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END		
				,mc.productID	
				,mc.GameID
				,mc.statusid				
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6))
			OPTION (MAXDOP 10)
		   
		   --3. Bettrans LC
		 IF EXISTS(SELECT TOP 1 1 FROM #SportBettype WHERE RefTable =2)
			INSERT INTO #FactCustWinloss
			(DataSource
			,[RptDate]
			,[TransDate]
			,SiteID		
			,SportType	
			,[BetType]
			,TicketStatus
			,LiveStatus
			,LeagueID
			,MatchID 
			,CustID
			,actualrate
			,VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,Stake
			,ActualStake
			,WinlossIBC
			,WinlossS
			,WinlossM
			,WinlossA
			,WinlossP
			,TurnoverIBC
			,TurnoverS
			,TurnoverM
			,TurnoverA
			,CommissionS
			,CommissionM
			,CommissionA
			,CommissionP
			,ExtraWL
			,ExtraTO
			,ExtraComm
			,BetCount)
			SELECT 
			/************************************************************DIMENSION**********************************************************************************/
				'Bettrans' DataSource
				,mc.winlostdate [RptDate]
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END AS SiteID		
				,mc.productID	 SportType	
				,mc.GameID [BetType]
				,mc.statusid TicketStatus
				,0 LiveStatus --0: Nonlive | 1:Live | 2: Mixed		
				,0 LeagueID	
				,0 MatchID 
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6)) AS VarianceVR	
				
			/************************************************************MEASURE**********************************************************************************/
			,SUM((stake)) Stake
			,SUM(Actual_Stake) ActualStake
			,SUM((mc.winlost - mc.actual_stake) + swinlost + mwinlost + awinlost ) WinlossIBC
			,SUM(swinlost) WinlossS
			,SUM(mwinlost) WinlossM
			,SUM(awinlost) WinlossA
			,SUM(winlost-actual_stake) WinlossP
			,SUM(abs(stake)* (1-tpositiontaking)) TurnoverIBC
			,SUM(abs(stake)* spositiontaking) TurnoverS
			,SUM(abs(stake) * mpositiontaking) TurnoverM
			,SUM(abs(stake) * apositiontaking) TurnoverA
			,SUM(scomm) CommissionS
			,SUM(acomm) CommissionM
			,SUM(comm) CommissionA
			,SUM(playercomm) CommissionP
			,SUM(CASE WHEN tpositiontaking = 1  THEN 0 
					  ELSE (winlost - actual_stake) * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				 END) ExtraWL
			,SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE abs(stake)* CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				END) ExtraTO	
			,CAST(SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE scomm * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8)) / (1 - tpositiontaking) END
			) AS [decimal](19, 6)) ExtraComm
			----
			,SUM(CASE WHEN mc.GameID IN (500,904) THEN 0
				WHEN mc.GameID IN (2198, 2398, 2998, 2199, 2399, 2999, 4300) THEN 0 ELSE 1 END) AS BetCount
			
			FROM bodb02.dbo.bettransLC14 AS mc WITH (NOLOCK)
			LEFT JOIN #Site s WITH (NOLOCK) ON mc.Recommend = s.Recommend
			WHERE mc.winlostdate = @_Date	
				AND mc.statusID IN (111,112,113)
				AND mc.Currency NOT IN (20,27,28)				
				AND EXISTS(SELECT TOP 1 1 FROM #SportBettype spm where spm.RefTable IN( 2) AND spm.Bettype = mc.gameID)
			GROUP BY mc.winlostdate
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END		
				,mc.productID	
				,mc.GameID
				,mc.statusid				
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6))
			OPTION (MAXDOP 10)
	END	--Bettrans14

--Bettrans_bk
IF @_Date < @BalanceUpDate
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype WHERE RefTable IN(0,3))
			INSERT INTO #FactCustWinloss
			(DataSource
			,[RptDate]
			,[TransDate]
			,SiteID		
			,SportType	
			,[BetType]
			,TicketStatus
			,LiveStatus
			,LeagueID
			,MatchID
			,CustID
			,actualrate
			,VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,Stake
			,ActualStake
			,WinlossIBC
			,WinlossS
			,WinlossM
			,WinlossA
			,WinlossP
			,TurnoverIBC
			,TurnoverS
			,TurnoverM
			,TurnoverA
			,CommissionS
			,CommissionM
			,CommissionA
			,CommissionP
			,ExtraWL
			,ExtraTO
			,ExtraComm
			,BetCount)
			SELECT 
			/************************************************************DIMENSION**********************************************************************************/
				'Bettrans' DataSource
				,mc.winlostdate [RptDate]
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END AS SiteID		
				,CASE 
						WHEN mc.bettype IN (9,29) AND mc.liveawayscore = 3 THEN - 2 -- Combined Sport
						WHEN mc.bettype IN (9,29) AND mc.liveawayscore = 1 THEN 1 --Soccer
						WHEN  mc.bettype = 10 THEN ISNULL(l.sporttype,-1)
						ELSE ISNULL(CAST(m.sporttype AS INT),-1)
				END	 SportType	
				,mc.bettype [BetType]
				,CASE WHEN ABS(mc.modds) = 0.25
							AND mc.statusid IN (112,113) THEN mc.statusid+2 ELSE mc.statusid END AS TicketStatus
				,CASE WHEN mc.bettype IN (9,29) THEN mc.livehomescore ELSE CAST(mc.liveindicator AS tinyint) END LiveStatus --0: Nonlive | 1:Live | 2: Mixed		
				,CASE WHEN  spm.EventType =1 THEN ISNULL(m.LeagueID,-1) 
					WHEN mc.bettype = 10 THEN ISNULL(o.LeagueID,-1) 
					WHEN spm.EventType =3 THEN ISNULL(vsr.LeagueID,-1) 
					ELSE -1 END  LeagueID	
				,mc.MatchID  AS MatchID 
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6)) AS VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,SUM(CASE WHEN bt.BetType IS NOT NULL THEN  abs(stake) ELSE stake END) Stake
			,SUM(Actual_Stake) ActualStake
			,SUM(CASE WHEN mc.bettype IN (2199, 2399, 2999, 4300) THEN 0 --Progressive Jackpot
				ELSE  (mc.winlost - mc.actual_stake) + swinlost + mwinlost + awinlost END ) WinlossIBC
			,SUM(swinlost) WinlossS
			,SUM(mwinlost) WinlossM
			,SUM(awinlost) WinlossA
			,SUM(winlost-actual_stake) WinlossP
			,SUM(abs(stake)* (1-tpositiontaking)) TurnoverIBC
			,SUM(abs(stake)* spositiontaking) TurnoverS
			,SUM(abs(stake) * mpositiontaking) TurnoverM
			,SUM(abs(stake) * apositiontaking) TurnoverA
			,SUM(scomm) CommissionS
			,SUM(acomm) CommissionM
			,SUM(comm) CommissionA
			,SUM(playercomm) CommissionP
			,SUM(CASE 
					WHEN mc.bettype IN (2199, 2399, 2999, 4300) THEN 0 --Progressive Jackpot
					WHEN tpositiontaking = 1  THEN 0 
					  ELSE (winlost - actual_stake) * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				 END) ExtraWL
			,SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE abs(stake)* CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				END) ExtraTO	
			,CAST(SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE scomm * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8)) / (1 - tpositiontaking) END
			) AS [decimal](19, 6)) ExtraComm
			----
			,SUM(CASE
						WHEN mc.bettype IN (500,904) THEN 0 
		 				WHEN td.[VendorID] IN (14) THEN 0 
		 				WHEN mc.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4300) THEN 0 
						ELSE 1 END) AS BetCount
			
			FROM bodb_archive.dbo.bettrans_bk AS mc WITH (NOLOCK)		
			LEFT JOIN (Select distinct bettype FROM bodb02.dbo.SportBettypeMatrix WITH (NOLOCK)
						WHERE ProductID = 1 and SubProduct = '') bt on bt.BetType =mc.bettype
			LEFT JOIN #Site s WITH (NOLOCK) ON mc.Recommend = s.Recommend
			LEFT JOIN bodb02.dbo.TradeCust AS td WITH (NOLOCK) ON mc.custid = td.custid	
			LEFT JOIN #SportBettype spm ON spm.RefTable IN( 0,3) AND spm.Bettype = mc.Bettype
			LEFT JOIN bodb_archive.dbo.match_bk m WITH (NOLOCK) ON mc.matchid = m.matchid AND mc.bettype <>10 AND spm.EventType =1
			LEFT JOIN bodb_archive.dbo.outright_bk  o WITH (NOLOCK) ON mc.matchid = o.orid AND mc.bettype =10
			LEFT JOIN bodb02.dbo.League  l WITH (NOLOCK) ON l.leagueid = o.leagueid	
			LEFT JOIN bodb02.dbo.VSRaceInfo  vsr WITH (NOLOCK) ON mc.matchid = vsr.EventID AND spm.EventType =3

			WHERE mc.winlostdate = @_Date	
				AND mc.statusID IN (111,112,113)
				AND mc.Currency NOT IN (20,27,28)		
				AND mc.ruben = 1 				
				AND EXISTS(SELECT TOP 1 1 FROM #SportBettype spm where spm.RefTable IN( 0,3) AND spm.Bettype = mc.Bettype)
			GROUP BY mc.winlostdate	
				,[TransDate]			
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END
				,CASE 
						WHEN mc.bettype IN (9,29) AND mc.liveawayscore = 3 THEN - 2 -- Combined Sport
						WHEN mc.bettype IN (9,29) AND mc.liveawayscore = 1 THEN 1 --Soccer
						WHEN  mc.bettype = 10 THEN ISNULL(l.sporttype,-1)
						ELSE ISNULL(CAST(m.sporttype AS INT),-1)
				END	
				,mc.bettype
				,CASE WHEN ABS(mc.modds) = 0.25
							AND mc.statusid IN (112,113) THEN mc.statusid+2  ELSE mc.statusid END
				,CASE WHEN mc.bettype IN (9,29) THEN mc.livehomescore ELSE CAST(mc.liveindicator AS tinyint) END --0: Nonlive | 1:Live | 2: Mixed	
				,CASE WHEN  spm.EventType =1 THEN ISNULL(m.LeagueID,-1) 
						WHEN mc.bettype = 10 THEN ISNULL(o.LeagueID,-1) 
						WHEN spm.EventType =3 THEN ISNULL(vsr.LeagueID,-1) 
						ELSE -1 END 
				,mc.MatchID
				,mc.srecommend
				,mc.mrecommend
				,mc.recommend
				,mc.CustID
				,mc.actualrate			
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6))	
			OPTION (MAXDOP 10)
				
		   --2. Bettrans RNG
		 IF EXISTS(SELECT TOP 1 1 FROM #SportBettype WHERE RefTable =1)
			INSERT INTO #FactCustWinloss
			(DataSource
			,[RptDate]
			,[TransDate]
			,SiteID		
			,SportType	
			,[BetType]
			,TicketStatus
			,LiveStatus
			,LeagueID
			,MatchID 
			,CustID
			,actualrate
			,VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,Stake
			,ActualStake
			,WinlossIBC
			,WinlossS
			,WinlossM
			,WinlossA
			,WinlossP
			,TurnoverIBC
			,TurnoverS
			,TurnoverM
			,TurnoverA
			,CommissionS
			,CommissionM
			,CommissionA
			,CommissionP
			,ExtraWL
			,ExtraTO
			,ExtraComm
			,BetCount)
			SELECT 
			/************************************************************DIMENSION**********************************************************************************/
				'Bettrans' DataSource
				,mc.winlostdate [RptDate]
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END AS SiteID		
				,mc.productID	 SportType	
				,mc.GameID [BetType]
				,mc.statusid TicketStatus
				,0 LiveStatus --0: Nonlive | 1:Live | 2: Mixed		
				,0 LeagueID	
				,0 MatchID
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6)) AS VarianceVR	
				
			/************************************************************MEASURE**********************************************************************************/
			,SUM((stake)) Stake
			,SUM(Actual_Stake) ActualStake
			,SUM(CASE WHEN mc.gameId IN(2198, 2398, 2998)
						THEN ContributionRate * BetStake + awinlost + mwinlost + swinlost
					WHEN mc.gameId IN (2199, 2399, 2999, 4300) THEN 0 --Progressive Jackpot
					ELSE (mc.winlost - mc.actual_stake) + swinlost + mwinlost + awinlost  END) WinlossIBC
			,SUM(swinlost) WinlossS
			,SUM(mwinlost) WinlossM
			,SUM(awinlost) WinlossA
			,SUM(winlost-actual_stake) WinlossP
			,SUM(abs(stake)* (1-tpositiontaking)) TurnoverIBC
			,SUM(abs(stake)* spositiontaking) TurnoverS
			,SUM(abs(stake) * mpositiontaking) TurnoverM
			,SUM(abs(stake) * apositiontaking) TurnoverA
			,SUM(scomm) CommissionS
			,SUM(acomm) CommissionM
			,SUM(comm) CommissionA
			,SUM(playercomm) CommissionP
			,SUM(CASE WHEN tpositiontaking = 1  THEN 0 		
					WHEN mc.gameId IN (2199, 2399, 2999, 4300) THEN 0 --Progressive Jackpot
					 WHEN mc.gameId IN(2198, 2398, 2998) THEN ContributionRate * BetStake* CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
					  ELSE (winlost - actual_stake) * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				 END) ExtraWL
			,SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE abs(stake)* CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				END) ExtraTO	
			,CAST(SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE scomm * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8)) / (1 - tpositiontaking) END
			) AS [decimal](19, 6)) ExtraComm
			----
			,SUM(CASE WHEN mc.GameID IN (500,904) THEN 0
				WHEN mc.GameID IN (2198, 2398, 2998, 2199, 2399, 2999, 4300) THEN 0 ELSE 1 END) AS BetCount
			
			FROM bodb_archive.dbo.bettransRnG_bk AS mc WITH (NOLOCK)
			LEFT JOIN #Site s WITH (NOLOCK) ON mc.Recommend = s.Recommend
			WHERE mc.winlostdate = @_Date	
				AND mc.statusID IN (111,112,113)
				AND mc.Currency NOT IN (20,27,28)				
				AND EXISTS(SELECT TOP 1 1 FROM #SportBettype spm where spm.RefTable IN( 1) AND spm.Bettype = mc.gameID)
			GROUP BY mc.winlostdate
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END		
				,mc.productID	
				,mc.GameID
				,mc.statusid				
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6))
			OPTION (MAXDOP 10)
		   
		   --3. Bettrans LC
		 IF EXISTS(SELECT TOP 1 1 FROM #SportBettype WHERE RefTable =2)
			INSERT INTO #FactCustWinloss
			(DataSource
			,[RptDate]
			,[TransDate]
			,SiteID		
			,SportType	
			,[BetType]
			,TicketStatus
			,LiveStatus
			,LeagueID
			,MatchID 
			,CustID
			,actualrate
			,VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,Stake
			,ActualStake
			,WinlossIBC
			,WinlossS
			,WinlossM
			,WinlossA
			,WinlossP
			,TurnoverIBC
			,TurnoverS
			,TurnoverM
			,TurnoverA
			,CommissionS
			,CommissionM
			,CommissionA
			,CommissionP
			,ExtraWL
			,ExtraTO
			,ExtraComm
			,BetCount)
			SELECT 
			/************************************************************DIMENSION**********************************************************************************/
				'Bettrans' DataSource
				,mc.winlostdate [RptDate]
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END AS SiteID		
				,mc.productID	 SportType	
				,mc.GameID [BetType]
				,mc.statusid TicketStatus
				,0 LiveStatus --0: Nonlive | 1:Live | 2: Mixed		
				,0 LeagueID	
				,0 MatchID 
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6)) AS VarianceVR	
				
			/************************************************************MEASURE**********************************************************************************/
			,SUM((stake)) Stake
			,SUM(Actual_Stake) ActualStake
			,SUM((mc.winlost - mc.actual_stake) + swinlost + mwinlost + awinlost ) WinlossIBC
			,SUM(swinlost) WinlossS
			,SUM(mwinlost) WinlossM
			,SUM(awinlost) WinlossA
			,SUM(winlost-actual_stake) WinlossP
			,SUM(abs(stake)* (1-tpositiontaking)) TurnoverIBC
			,SUM(abs(stake)* spositiontaking) TurnoverS
			,SUM(abs(stake) * mpositiontaking) TurnoverM
			,SUM(abs(stake) * apositiontaking) TurnoverA
			,SUM(scomm) CommissionS
			,SUM(acomm) CommissionM
			,SUM(comm) CommissionA
			,SUM(playercomm) CommissionP
			,SUM(CASE WHEN tpositiontaking = 1  THEN 0 
					  ELSE (winlost - actual_stake) * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				 END) ExtraWL
			,SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE abs(stake)* CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8))
				END) ExtraTO	
			,CAST(SUM(CASE 
						WHEN tpositiontaking = 1 THEN 0 
						ELSE scomm * CAST(ISNULL(mc.epositiontaking,0) AS [decimal](10, 8)) / (1 - tpositiontaking) END
			) AS [decimal](19, 6)) ExtraComm
			----
			,SUM(CASE WHEN mc.GameID IN (500,904) THEN 0
				WHEN mc.GameID IN (2198, 2398, 2998, 2199, 2399, 2999, 4300) THEN 0 ELSE 1 END) AS BetCount
			
			FROM bodb_archive.dbo.bettransLC_bk AS mc WITH (NOLOCK)
			LEFT JOIN #Site s WITH (NOLOCK) ON mc.Recommend = s.Recommend
			WHERE mc.winlostdate = @_Date	
				AND mc.statusID IN (111,112,113)
				AND mc.Currency NOT IN (20,27,28)				
				AND EXISTS(SELECT TOP 1 1 FROM #SportBettype spm where spm.RefTable IN( 2) AND spm.Bettype = mc.gameID)
			GROUP BY mc.winlostdate
				,[TransDate]
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END		
				,mc.productID	
				,mc.GameID
				,mc.statusid				
				,mc.CustID
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6))
			OPTION (MAXDOP 10)
	END	--Bettrans_bk

PRINT 'Start Processing compare by product'

IF OBJECT_ID('tempdb..#tmpReportProduct') IS NOT NULL
	BEGIN
		DROP TABLE #tmpReportProduct
	END	

CREATE TABLE #tmpReportProduct(
	GroupType	VARCHAR(100)
	,RptDate	DATE
	,[Hour]		TINYINT
	,ProductGroup	VARCHAR(100)
	,ProductName	VARCHAR(100)
	,ActiveMember	INT
	,NoMatch		INT
	,BetCount		INT
	,WinlossMember	DECIMAL(19,6)
	,TurnoverMember	DECIMAL(19,6)
	,TurnoverMember_nodraw	DECIMAL(19,6)
	,Commission				DECIMAL(19,6)
	,HouseIncome			DECIMAL(19,6)
	,HouseTurnOver			DECIMAL(19,6)
	,HouseTurnOver_nodraw	DECIMAL(19,6)
	,HouseVirtualWinloss	DECIMAL(19,6)
	,HouseVirtualTurnover	DECIMAL(19,6)
	,HouseVirtualTurnover_nodraw	DECIMAL(19,6)
	,VarianceWinloss				DECIMAL(19,6)
	,VarianceTurnover				DECIMAL(19,6)
	,VarianceTurnover_nodraw		DECIMAL(19,6)
	)

INSERT INTO #tmpReportProduct
SELECT 	  'All' GroupType,
		b.RptDate,
		--CASE WHEN P.ProductID IN (3, 26) THEN -- Number Game, Lucky 3
		--	CASE WHEN DATEDIFF(dd, m.kickofftime, b.RptDate) = 1 and DATEPART(HOUR, m.kickofftime) = 23 
		--	THEN 0 --kickoff at 23PM and settled on the next day then convert to 0 AM 
		--	ELSE  DATEPART(HOUR, m.kickofftime) 
		--	END 
		--ELSE	--Casino, Virtual Sports and Keno
		--	CASE WHEN DATEDIFF(dd, b.transdate, b.RptDate) = 1 and DATEPART(HOUR, b.transdate) = 23 
		--	THEN 0 --bet at 23PM then convert to 0 AM 
		--	ELSE  DATEPART(HOUR, b.transdate) 
		--	END
		--END
		 DATEPART(HOUR, b.transdate)  AS [Hour],
		CASE WHEN sbt.CasinoType = 1 THEN 'Casino'
			WHEN sbt.CasinoType = 2 THEN 'Live Casino'
			WHEN p.ProductName IN( 'SportsBook') THEN 'SportsBook'
			ELSE p.ProductName END ProductGroup,
			
		CASE WHEN b.Bettype IN (9,29) THEN 'Parlay' 
			WHEN p.ProductName = 'SportsBook' AND sp.SportName ='Soccer' THEN 'Soccer'
			WHEN p.ProductName = 'SportsBook' AND sp.SportName <>'Soccer' THEN 'Other Sports'
			ELSE p.ProductName END ProductName,
		COUNT(DISTINCT b.CustID) ActiveMember,
		COUNT(DISTINCT CASE WHEN p.ProductID =1 THEN b.MatchID ELSE NULL END) NoMatch,
		-- [Bet Count]
		SUM(CASE WHEN b.BetType = 500 THEN 0 
				 ELSE BetCount  END) BetCount,
		SUM(b.WinlossP * b.ActualRate) [WinlossMember],
		SUM(b.Stake * b.ActualRate) [TurnoverMember],
		SUM(b.Stake * b.ActualRate
			*(CASE WHEN b.TicketStatus IN (3,111) THEN 0 WHEN p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)) [TurnoverMember_nodraw],
		-- [Commission]
		SUM(-b.CommissionS*b.ActualRate) Commission,
		-- [Company Real Income]
		SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * b.ActualRate*CASE WHEN b.SiteID NOT IN(-2,-4) THEN 1 ELSE 0 END) HouseIncome,
		-- [Company Real Turnover]
		SUM(
			(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
			) HouseTurnOver,
		SUM(
			(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
			*(CASE WHEN b.TicketStatus IN (3,111) THEN 0 WHEN p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
			) HouseTurnOver_nodraw,
		-- [Company Virtual Income]
		SUM(-((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
				+ (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)
			 ) * b.ActualRate) [HouseVirtualWinloss],
		-- [Company Virtual Turnover]
		SUM(
			(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate						 
			) [HouseVirtualTurnover],
		SUM(
			(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
			*(CASE WHEN b.TicketStatus IN (3,111) THEN 0 WHEN p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)							 
			) [HouseVirtualTurnover_nodraw],
		-- [Variance WL]
		SUM((b.WinlossIBC - b.ExtraWL
				+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * b.ActualRate) [Variance Winloss],--90
		-- [Variance Turnover]
		SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
			) [Variance Turnover],
		SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
			*(CASE WHEN b.TicketStatus IN (3,111) THEN 0 WHEN p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
			) [Variance Turnover_nodraw]
		FROM
			#FactCustWinloss b with (nolock)				
			 LEFT JOIN bodb02.dbo.Sports sp (NOLOCK)
					ON sp.SportType = b.SportType
		   LEFT JOIN #tmpProduct P
			ON P.Bettype = b.Bettype 
		   LEFT JOIN #SportBettype sbt
			ON sbt.Bettype = b.Bettype 
		   LEFT JOIN #tmpMatch M
			ON M.MatchID = b.MatchID
		GROUP BY
			b.RptDate,
		--CASE WHEN P.ProductID IN (3, 26) THEN -- Number Game, Lucky 3
		--	CASE WHEN DATEDIFF(dd, m.kickofftime, b.RptDate) = 1 and DATEPART(HOUR, m.kickofftime) = 23 
		--	THEN 0 --kickoff at 23PM and settled on the next day then convert to 0 AM 
		--	ELSE  DATEPART(HOUR, m.kickofftime) 
		--	END 
		--ELSE	--Casino, Virtual Sports and Keno
		--	CASE WHEN DATEDIFF(dd, b.transdate, b.RptDate) = 1 and DATEPART(HOUR, b.transdate) = 23 
		--	THEN 0 --bet at 23PM then convert to 0 AM 
		--	ELSE  DATEPART(HOUR, b.transdate) 
		--	END
		--END,
		 DATEPART(HOUR, b.transdate) ,
		CASE WHEN sbt.CasinoType = 1 THEN 'Casino'
			WHEN sbt.CasinoType = 2 THEN 'Live Casino'
			WHEN p.ProductName IN( 'SportsBook') THEN 'SportsBook'
			ELSE p.ProductName END,
			CASE WHEN b.Bettype IN (9,29) THEN 'Parlay' 
			WHEN p.ProductName = 'SportsBook' AND sp.SportName ='Soccer' THEN 'Soccer'
			WHEN p.ProductName = 'SportsBook' AND sp.SportName <>'Soccer' THEN 'Other Sports'
			ELSE p.ProductName END 

INSERT INTO #tmpReportProduct
SELECT 	 'SportsBook' GroupType,
		b.RptDate,
		--CASE WHEN P.ProductID IN (3, 26) THEN -- Number Game, Lucky 3
		--	CASE WHEN DATEDIFF(dd, m.kickofftime, b.RptDate) = 1 and DATEPART(HOUR, m.kickofftime) = 23 
		--	THEN 0 --kickoff at 23PM and settled on the next day then convert to 0 AM 
		--	ELSE  DATEPART(HOUR, m.kickofftime) 
		--	END 
		--ELSE	--Casino, Virtual Sports and Keno
		--	CASE WHEN DATEDIFF(dd, b.transdate, b.RptDate) = 1 and DATEPART(HOUR, b.transdate) = 23 
		--	THEN 0 --bet at 23PM then convert to 0 AM 
		--	ELSE  DATEPART(HOUR, b.transdate) 
		--	END
		--END 
		 DATEPART(HOUR, b.transdate) AS [Hour],
		 'Saba' ProductGroup,
		'Saba-'+ sp.SportName  ProductName,
		COUNT(DISTINCT b.CustID) ActiveMember,
		COUNT(DISTINCT CASE WHEN p.ProductID =1 THEN b.MatchID ELSE NULL END) NoMatch,
		-- [Bet Count]
		SUM(CASE WHEN b.BetType = 500 THEN 0 
				 ELSE BetCount  END) BetCount,
		SUM(b.WinlossP * b.ActualRate) [WinlossMember],
		SUM(b.Stake * b.ActualRate) [TurnoverMember],
		SUM(b.Stake * b.ActualRate
			*(CASE WHEN b.TicketStatus IN (3,111) THEN 0 WHEN p.ProductID = 1 AND b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)) [TurnoverMember_Nodraw],
		-- [Commission]
		SUM(-b.CommissionS*b.ActualRate) Commission,
		-- [Company Real Income]
		SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * b.ActualRate*CASE WHEN b.SiteID NOT IN(-2,-4) THEN 1 ELSE 0 END) HouseIncome,
		-- [Company Real Turnover]
		SUM(
			(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
			) HouseTurnOver,
		SUM(
			(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
			*(CASE WHEN b.TicketStatus IN (3,111) THEN 0 WHEN p.ProductID = 1 AND b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
			) HouseTurnOver_Nodraw,
		-- [Company Virtual Income]
		SUM(-((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
				+ (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)
			 ) * b.ActualRate) [HouseVirtualWinloss],
		-- [Company Virtual Turnover]
		SUM(
			(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
			) [HouseVirtualTurnover],
		SUM(
			(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
			*(CASE WHEN b.TicketStatus IN (3,111) THEN 0 WHEN p.ProductID = 1 AND b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
			) [HouseVirtualTurnover_Nodraw],
		-- [Variance WL]
		SUM((b.WinlossIBC - b.ExtraWL
				+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * b.ActualRate) [Variance Winloss],--90
		-- [Variance Turnover]
		SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
			) [Variance Turnover],
		SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
			*(CASE WHEN b.TicketStatus IN (3,111) THEN 0 WHEN p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
			) [Variance Turnover_Nodraw]
		FROM
			#FactCustWinloss b with (nolock)					
			 LEFT JOIN bodb02.dbo.Sports sp (NOLOCK)
					ON sp.SportType = b.SportType				
			 LEFT JOIN bodb02.dbo.League l (NOLOCK)
					ON l.LeagueID = b.LeagueID
		   LEFT JOIN #tmpProduct P
			ON P.Bettype = b.Bettype
		   LEFT JOIN #tmpMatch M
			ON M.MatchID = b.MatchID
			
		 WHERE ISNULL(l.LeagueGroupID,-1) IN( 42,74)
			AND b.BetType NOT IN(9,29)
		GROUP BY 
			b.RptDate,
		--CASE WHEN P.ProductID IN (3, 26) THEN -- Number Game, Lucky 3
		--	CASE WHEN DATEDIFF(dd, m.kickofftime, b.RptDate) = 1 and DATEPART(HOUR, m.kickofftime) = 23 
		--	THEN 0 --kickoff at 23PM and settled on the next day then convert to 0 AM 
		--	ELSE  DATEPART(HOUR, m.kickofftime) 
		--	END 
		--ELSE	--Casino, Virtual Sports and Keno
		--	CASE WHEN DATEDIFF(dd, b.transdate, b.RptDate) = 1 and DATEPART(HOUR, b.transdate) = 23 
		--	THEN 0 --bet at 23PM then convert to 0 AM 
		--	ELSE  DATEPART(HOUR, b.transdate) 
		--	END
		--END,
		 DATEPART(HOUR, b.transdate) ,
			'Saba-'+ sp.SportName 

SELECT td.ProductGroup,
		td.ProductName,
		td.[Hour],
		td.NoMatch,
		td.ActiveMember,
		td.BetCount,
		td.[TurnoverMember] Mem_TO,
		td.[TurnoverMember_Nodraw] Mem_TO_Nodraw,
		td.[WinlossMember] Mem_WL,
		CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END Mem_MG,
		CASE WHEN td.[TurnoverMember_Nodraw] <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember_Nodraw] ELSE 0 END Mem_MG_Nodraw,
		td.HouseTurnOver	House_Real_TO,
		td.HouseTurnOver_Nodraw	House_Real_TO_Nodraw,
		td.HouseIncome	House_Real_WL,
		CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END House_Real_MG,
		CASE WHEN td.HouseTurnOver_Nodraw <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver_Nodraw ELSE 0 END House_Real_MG_Nodraw,
		td.[HouseVirtualTurnover] House_Virtual_TO,
		td.[HouseVirtualTurnover_Nodraw] House_Virtual_TO_Nodraw,
		td.[HouseVirtualWinloss] House_Virtual_WL,
		CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END House_Virtual_MG,
		CASE WHEN td.[HouseVirtualTurnover_Nodraw] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover_Nodraw] ELSE 0 END House_Virtual_MG_Nodraw,
		CASE WHEN td.ProductName LIKE 'Saba-Soccer' THEN 1
			WHEN td.ProductName LIKE 'Saba-Basketball' THEN 2
			WHEN td.ProductName LIKE 'Saba-Cricket' THEN 3
			WHEN td.ProductName LIKE 'Saba-%' THEN 4
			WHEN td.ProductName LIKE 'Soccer' THEN 11
			WHEN td.ProductName LIKE 'Other Sports' THEN 12
			WHEN td.ProductName LIKE 'Parlay' THEN 13
			WHEN td.ProductGroup LIKE 'SportsBook' THEN 200
			WHEN td.ProductGroup LIKE 'Bet Builder' THEN 210
			WHEN td.ProductGroup LIKE 'Casino' THEN 300
			WHEN td.ProductGroup LIKE 'Live Casino' THEN 400
			ELSE 1001
			END ORDERID
FROM #tmpReportProduct td	
ORDER BY ORDERID ,ProductName, td.[Hour] 


PRINT 'End Processing compare by product'  
RETURN
 
 




 
SELECT 	  'All' GroupType,
		b.RptDate,
		--CASE WHEN P.ProductID IN (3, 26) THEN -- Number Game, Lucky 3
		--	CASE WHEN DATEDIFF(dd, m.kickofftime, b.RptDate) = 1 and DATEPART(HOUR, m.kickofftime) = 23 
		--	THEN 0 --kickoff at 23PM and settled on the next day then convert to 0 AM 
		--	ELSE  DATEPART(HOUR, m.kickofftime) 
		--	END 
		--ELSE	--Casino, Virtual Sports and Keno
		--	CASE WHEN DATEDIFF(dd, b.transdate, b.RptDate) = 1 and DATEPART(HOUR, b.transdate) = 23 
		--	THEN 0 --bet at 23PM then convert to 0 AM 
		--	ELSE  DATEPART(HOUR, b.transdate) 
		--	END
		--END 
		CASE WHEN sbt.CasinoType = 1 THEN 'Casino'
			WHEN sbt.CasinoType = 2 THEN 'Live Casino'
			WHEN p.ProductName IN( 'SportsBook') THEN 'SportsBook'
			ELSE p.ProductName END ProductGroup,
			
		CASE WHEN b.Bettype IN (9,29) THEN 'Parlay' 
			WHEN p.ProductName = 'SportsBook' AND sp.SportName ='Soccer' THEN 'Soccer'
			WHEN p.ProductName = 'SportsBook' AND sp.SportName <>'Soccer' THEN 'Other Sports'
			ELSE sp.SportName  END ProductName,
		COUNT(DISTINCT b.CustID) ActiveMember,
		COUNT(DISTINCT CASE WHEN p.ProductID =1 THEN b.MatchID ELSE NULL END) NoMatch,
		-- [Bet Count]
		SUM(CASE WHEN b.BetType = 500 THEN 0 
				 ELSE BetCount  END) BetCount,
		SUM(b.WinlossP * b.ActualRate) [WinlossMember],
		SUM(b.Stake * b.ActualRate) [TurnoverMember],
		SUM(b.Stake * b.ActualRate
			*(CASE WHEN b.TicketStatus IN (3,111) THEN 0 WHEN p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)) [TurnoverMember_nodraw],
		-- [Commission]
		SUM(-b.CommissionS*b.ActualRate) Commission,
		-- [Company Real Income]
		SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * b.ActualRate*CASE WHEN b.SiteID NOT IN(-2,-4) THEN 1 ELSE 0 END) HouseIncome,
		-- [Company Real Turnover]
		SUM(
			(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
			) HouseTurnOver,
		SUM(
			(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
			(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
			*(CASE WHEN b.TicketStatus IN (3,111) THEN 0 WHEN p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
			) HouseTurnOver_nodraw,
		-- [Company Virtual Income]
		SUM(-((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
				+ (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)
			 ) * b.ActualRate) [HouseVirtualWinloss],
		-- [Company Virtual Turnover]
		SUM(
			(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate						 
			) [HouseVirtualTurnover],
		SUM(
			(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
			*(CASE WHEN b.TicketStatus IN (3,111) THEN 0 WHEN p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)							 
			) [HouseVirtualTurnover_nodraw],
		-- [Variance WL]
		SUM((b.WinlossIBC - b.ExtraWL
				+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * b.ActualRate) [Variance Winloss],--90
		-- [Variance Turnover]
		SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
			) [Variance Turnover],
		SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
			*(CASE WHEN b.TicketStatus IN (3,111) THEN 0 WHEN p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
			) [Variance Turnover_nodraw]
		FROM
			#FactCustWinloss b with (nolock)				
			 LEFT JOIN bodb02.dbo.Sports sp (NOLOCK)
					ON sp.SportType = b.SportType
		   LEFT JOIN #tmpProduct P
			ON P.Bettype = b.Bettype 
		   LEFT JOIN #SportBettype sbt
			ON sbt.Bettype = b.Bettype 
		   LEFT JOIN #tmpMatch M
			ON M.MatchID = b.MatchID
		GROUP BY
			b.RptDate,
		--CASE WHEN P.ProductID IN (3, 26) THEN -- Number Game, Lucky 3
		--	CASE WHEN DATEDIFF(dd, m.kickofftime, b.RptDate) = 1 and DATEPART(HOUR, m.kickofftime) = 23 
		--	THEN 0 --kickoff at 23PM and settled on the next day then convert to 0 AM 
		--	ELSE  DATEPART(HOUR, m.kickofftime) 
		--	END 
		--ELSE	--Casino, Virtual Sports and Keno
		--	CASE WHEN DATEDIFF(dd, b.transdate, b.RptDate) = 1 and DATEPART(HOUR, b.transdate) = 23 
		--	THEN 0 --bet at 23PM then convert to 0 AM 
		--	ELSE  DATEPART(HOUR, b.transdate) 
		--	END
		--END, 
		CASE WHEN sbt.CasinoType = 1 THEN 'Casino'
			WHEN sbt.CasinoType = 2 THEN 'Live Casino'
			WHEN p.ProductName IN( 'SportsBook') THEN 'SportsBook'
			ELSE p.ProductName END,
			CASE WHEN b.Bettype IN (9,29) THEN 'Parlay' 
			WHEN p.ProductName = 'SportsBook' AND sp.SportName ='Soccer' THEN 'Soccer'
			WHEN p.ProductName = 'SportsBook' AND sp.SportName <>'Soccer' THEN 'Other Sports'
			ELSE sp.SportName  END 
