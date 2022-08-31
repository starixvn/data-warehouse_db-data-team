USE [bodb02]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Created by Tom

Task: Explore data by hourly

Param's Explanation:
	@DateCompare1 	@DateCompare2: Data on date need to compare (Example: DateCompare1: Yesterdate vs DateCompare2: Today)
	
	@Adjustment: 
		0: Include draw
		1: Exclude draw 
		
	@SiteName: SiteName	(	SELECT Site FROM bodb02.dbo.Site s (NOLOCK)	)
		'' : Get All
		NOT BLANK: CHECK Site NAME
		
	@SiteType: SiteType
		0: Get All
		1: Credit (exclude CN88)
		2: Cash
		3: CN88
		
	@ProductID: Product ID (	SELECT DISTINCT ProductID,ProductName FROM DBWH.bodb_Account.dbo.Product_Bettype	)
		0: Get ALL
		-1	MG-SuperLive
		-2	Bettrade 
		-3	Bet Builder
		1   SportsBook
		2   Racing
		
	@SportType: SportType(	SELECT * FROM bodb02.dbo.Sports s (NOLOCK)	)
		0: Get ALL
		-9 : Parlay
		Not in(-9,0) : SportType
		
	@ReportBy:
		0:  Get All mode
		1:	ProductName	| NoMatch	| ActiveMember	| BetCount	| Mem_TO	| Mem_WL	Mem_MG	....	PerChange NoMatch	| PerChange ActiveMember	| PerChange BetCount	| ....
		2:  SiteType	| ProductName	| NoMatch	| ActiveMember	| BetCount	| Mem_TO	| Mem_WL	Mem_MG	....	PerChange NoMatch	| PerChange ActiveMember	| PerChange BetCount	| ....
		3:	SiteType	| NoMatch	| ActiveMember	| BetCount	| Mem_TO	| Mem_WL	Mem_MG	....	PerChange NoMatch	| PerChange ActiveMember	| PerChange BetCount	| ....
		4:	Site	| NoMatch	| ActiveMember	| BetCount	| Mem_TO	| Mem_WL	Mem_MG	....	PerChange NoMatch	| PerChange ActiveMember	| PerChange BetCount	| ....
		5:	Site	| ProductName	|NoMatch	| ActiveMember	| BetCount	| Mem_TO	| Mem_WL	Mem_MG	....	PerChange NoMatch	| PerChange ActiveMember	| PerChange BetCount	| ....

*/

SET NOCOUNT ON;
 
DECLARE @DateCompare1 SMALLDATETIME= DATEADD(DD,0,CAST(GETDATE() AS DATE)) 
DECLARE @DateCompare2 SMALLDATETIME= DATEADD(DD,1,@DateCompare1 )--'20200507'

DECLARE @ProductID INT = 0
		,@SportType INT = 0

DECLARE @Adjustment INT = 1
DECLARE @SiteType INT = 2
DECLARE @SiteName VARCHAR(100)= ''
DECLARE @ReportBy INT = 0

DECLARE @MoveBetDate SMALLDATETIME
DECLARE @BalanceUpDate SMALLDATETIME
DECLARE @SportName VARCHAR(100)=''

SELECT 
	@BalanceUpDate = MIN(EventDate),
	@MoveBetDate = MAX(Eventdate)
 From bodb02.dbo.match14 m WITH (NOLOCK);

SELECT CASE WHEN @DateCompare1 > @DateCompare2 THEN @DateCompare1 ELSE @DateCompare2 END DateCompare1,
	CASE WHEN @DateCompare1 > @DateCompare2 THEN @DateCompare2 ELSE @DateCompare1 END  DateCompare2,
	@BalanceUpDate  BalanceUpDate,
	@MoveBetDate MoveBetDate;

IF OBJECT_ID('tempdb..#tmpProduct') IS NOT NULL
	BEGIN
		DROP TABLE #tmpProduct
	END
	
CREATE TABLE #tmpProduct(
   ProductID     INT
 , ProductName    VARCHAR(500)
 , Bettype       INT
)

IF @SportType = -9
	SELECT @ProductID = 1
ELSE IF @SportType <> 0	
	SELECT TOP 1 @ProductID = ProductID
	FROM bodb02.dbo.SportBettypeMatrix mx(NOLOCK)
	WHERE SportType = @SportType

INSERT INTO #tmpProduct
SELECT ProductID,ProductName,Bettype FROM DBWH.bodb_Account.dbo.Product_Bettype
WHERE (ProductID = @ProductID OR @ProductID = 0);

IF OBJECT_ID('tempdb..#tmpBetFrom') IS NOT NULL
	BEGIN
		DROP TABLE #tmpBetFrom
	END
   CREATE TABLE #tmpBetFrom(
	   BetFromID     INT
	 , BetFrom    VARCHAR(500)
	 , BetFromName      VARCHAR(500)
	 , DeviceGroup    VARCHAR(500)	 
	)
	
INSERT INTO #tmpBetFrom(BetFromID ,BetFrom, BetFromName , DeviceGroup)
SELECT betfromid,	betfrom	,fullname	,DeviceGroup FROM DBWH.bodb_Account.dbo.tbl_BetFrom;

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
	[RptDate] [date] NOT NULL,
	[SiteID] [int] NULL,
	[SportType] [int] NULL,
	[BetType] [int] NULL,
	[TicketStatus] [int] NULL,
	[LiveStatus] [int] NULL,
	[LeagueID] [int] NULL,
	[MatchID] [int] NULL,
	[CurrencyID] [int] NULL,
	[BetFromID] VARCHAR(100) NULL,
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
	bodb02.dbo.Site si WITH (NOLOCK) ;
	
INSERT INTO #Site
SELECT
	recommend, MIN(SiteID) AS SiteID 
FROM
	bodb02.dbo.vw_Customer cu WITH (NOLOCK)
	LEFT JOIN bodb02.dbo.Site si WITH (NOLOCK)
		ON cu.site = si.site
WHERE
	roleid = 2
	AND cu.currency NOT IN(20,27,28)
GROUP BY recommend

IF OBJECT_ID('tempdb..#tmpWinlostDate') IS NOT NULL
	BEGIN
		DROP TABLE #tmpWinlostDate
	END

CREATE TABLE #tmpWinlostDate
(WinlostDate SMALLDATETIME
,DataSoure VARCHAR(100)
)

INSERT INTO #tmpWinlostDate
SELECT @DateCompare1 WinlostDate,CASE WHEN @DateCompare1>@MoveBetDate THEN 'Bettrans' ELSE 'DW' END DataSoure
UNION ALL
SELECT @DateCompare2 WinlostDate,CASE WHEN @DateCompare2>@MoveBetDate THEN 'Bettrans' ELSE 'DW' END DataSoure

--Bettrans
IF EXISTS(SELECT * FROM #tmpWinlostDate WHERE DataSoure = 'Bettrans')
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM #SportBettype WHERE RefTable IN(0,3))
			INSERT INTO #FactCustWinloss
			(DataSource
			,[RptDate]
			,SiteID		
			,SportType	
			,[BetType]
			--,CurrencyID
			,TicketStatus
			,LiveStatus
			,LeagueID
			,MatchID 
			--,BetFromID
			--,SuperID
			--,MasterID
			--,AgentID
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
						--WHEN mc.bettype IN (9,29) AND b1.sporttype_COUNT > 1 THEN - 3 -- Mixed Other sports
						--WHEN mc.bettype IN (9,29) THEN  ISNULL(b1.sporttype, -1)  --Other sports
						WHEN  mc.bettype = 10 THEN ISNULL(l.sporttype,-1)
						ELSE ISNULL(CAST(m.sporttype AS INT),-1)
				END	 SportType	
				,mc.bettype [BetType]
				--,mc.currency CurrencyID
				,CASE WHEN ABS(mc.modds) = 0.25
							AND mc.statusid IN (112,113) THEN mc.statusid+2 ELSE mc.statusid END AS TicketStatus
				,CASE WHEN mc.bettype IN (9,29) THEN mc.livehomescore ELSE CAST(mc.liveindicator AS tinyint) END LiveStatus --0: Nonlive | 1:Live | 2: Mixed		
				,ISNULL(m.LeagueID,-1) LeagueID	
				,mc.MatchID  AS MatchID 
				--,ISNULL(mc.BetFrom ,'-1') BetFromID
				--,mc.srecommend SuperID
				--,mc.mrecommend MasterID
				--,mc.recommend AgentID
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
			LEFT JOIN bodb02.dbo.match m WITH (NOLOCK) ON mc.matchid = m.matchid AND mc.bettype <>10
			LEFT JOIN bodb02.dbo.outright  o WITH (NOLOCK) ON mc.matchid = o.orid AND mc.bettype =10
			LEFT JOIN bodb02.dbo.League  l WITH (NOLOCK) ON l.leagueid = o.leagueid		

			WHERE mc.winlostdate IN (SELECT Winlostdate FROM #tmpWinlostDate WHERE DataSoure = 'Bettrans')
				AND mc.statusID IN (111,112,113)
				AND mc.Currency NOT IN (20,27,28)			
				AND mc.ruben = 1 
				
				AND EXISTS(SELECT TOP 1 1 FROM #SportBettype spm where spm.RefTable IN( 0,3) AND spm.Bettype = mc.Bettype)
				--AND CASE WHEN mc.bettype IN (9,29) THEN mc.livehomescore ELSE CAST(mc.liveindicator AS tinyint) END = 1
				--AND (m.sporttype = 1 
				--	OR l.sporttype = 1
					--OR (mc.bettype IN (9,29) AND mc.liveawayscore = 1)
				--	)
				--AND mc.matchid = 35079069
			GROUP BY mc.winlostdate				
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
						--WHEN mc.bettype IN (9,29) AND b1.sporttype_COUNT > 1 THEN - 3 -- Mixed Other sports
						--WHEN mc.bettype IN (9,29) THEN  ISNULL(b1.sporttype, -1)  --Other sports
						WHEN  mc.bettype = 10 THEN ISNULL(l.sporttype,-1)
						ELSE ISNULL(CAST(m.sporttype AS INT),-1)
				END	
				,mc.bettype
				,mc.currency
				,CASE WHEN ABS(mc.modds) = 0.25
							AND mc.statusid IN (112,113) THEN mc.statusid+2  ELSE mc.statusid END
				,CASE WHEN mc.bettype IN (9,29) THEN mc.livehomescore ELSE CAST(mc.liveindicator AS tinyint) END --0: Nonlive | 1:Live | 2: Mixed		
				--,CASE 
				--	WHEN mc.bettype IN (9,29) AND b1.leagueid_COUNT > 1 THEN - 2 -- Mixed League
				--	WHEN mc.bettype IN (9,29) AND b1.leagueid_COUNT <= 1 THEN ISNULL(b1.leagueid, -1)			
				--	WHEN mc.bettype = 18000 AND mc.betteam = '1' THEN -3 --Colossus Bets Freeplay
				--	ELSE ISNULL(ev.leagueid,-1)
				--END LeagueID	
				,ISNULL(m.LeagueID,-1)	
				,mc.MatchID
				--,ISNULL(mc.BetFrom ,'-1')
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
			,SiteID		
			,SportType	
			,[BetType]
			--,CurrencyID
			,TicketStatus
			,LiveStatus
			,LeagueID
			,MatchID 
			--,BetFromID
			--,SuperID
			--,MasterID
			--,AgentID
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
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END AS SiteID		
				,mc.productID	 SportType	
				,mc.GameID [BetType]
				--,mc.currency CurrencyID
				,mc.statusid TicketStatus
				,0 LiveStatus --0: Nonlive | 1:Live | 2: Mixed		
				,0 LeagueID	
				,0 MatchID 
				--,ISNULL(mc.BetFrom ,'-1') BetFromID
				--,mc.srecommend SuperID
				--,mc.mrecommend MasterID
				--,mc.recommend AgentID
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
			WHERE mc.winlostdate IN (SELECT Winlostdate FROM #tmpWinlostDate WHERE DataSoure = 'Bettrans')
				AND mc.statusID IN (111,112,113)
				AND mc.Currency NOT IN (20,27,28)
				
				AND EXISTS(SELECT TOP 1 1 FROM #SportBettype spm where spm.RefTable IN( 1) AND spm.Bettype = mc.gameID)
				--AND CASE WHEN mc.bettype IN (9,29) THEN mc.livehomescore ELSE CAST(mc.liveindicator AS tinyint) END = 1
				--AND (m.sporttype = 1 
				--	OR l.sporttype = 1
					--OR (mc.bettype IN (9,29) AND mc.liveawayscore = 1)
				--	)
				--AND mc.matchid = 35079069
			GROUP BY mc.winlostdate
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END		
				,mc.productID	
				,mc.GameID
				--,mc.currency CurrencyID
				,mc.statusid				
				,mc.CustID
				--,ISNULL(mc.BetFrom ,'-1')
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6))
			OPTION (MAXDOP 10)
		   
		   --3. Bettrans LC
		 IF EXISTS(SELECT TOP 1 1 FROM #SportBettype WHERE RefTable =2)
			INSERT INTO #FactCustWinloss
			(DataSource
			,[RptDate]
			,SiteID		
			,SportType	
			,[BetType]
			--,CurrencyID
			,TicketStatus
			,LiveStatus
			,LeagueID
			,MatchID 
			--,BetFromID
			--,SuperID
			--,MasterID
			--,AgentID
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
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END AS SiteID		
				,mc.productID	 SportType	
				,mc.GameID [BetType]
				--,mc.currency CurrencyID
				,mc.statusid TicketStatus
				,0 LiveStatus --0: Nonlive | 1:Live | 2: Mixed		
				,0 LeagueID	
				,0 MatchID 
				--,ISNULL(mc.BetFrom ,'-1') BetFromID
				--,mc.srecommend SuperID
				--,mc.mrecommend MasterID
				--,mc.recommend AgentID
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
			WHERE mc.winlostdate IN (SELECT Winlostdate FROM #tmpWinlostDate WHERE DataSoure = 'Bettrans')
				AND mc.statusID IN (111,112,113)
				AND mc.Currency NOT IN (20,27,28)				
				AND EXISTS(SELECT TOP 1 1 FROM #SportBettype spm where spm.RefTable IN( 2) AND spm.Bettype = mc.gameID)
				--AND CASE WHEN mc.bettype IN (9,29) THEN mc.livehomescore ELSE CAST(mc.liveindicator AS tinyint) END = 1
				--AND (m.sporttype = 1 
				--	OR l.sporttype = 1
					--OR (mc.bettype IN (9,29) AND mc.liveawayscore = 1)
				--	)
				--AND mc.matchid = 35079069
			GROUP BY mc.winlostdate
				,CASE 
					WHEN mc.recommend = 52466
						THEN - 2 --8RM
					WHEN mc.recommend = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(s.siteid,-1)
				END		
				,mc.productID	
				,mc.GameID
				--,mc.currency CurrencyID
				,mc.statusid
				
				,mc.CustID
				--ISNULL(mc.BetFrom ,'-1')
				,mc.actualrate
				,CAST((mc.virtualrate / mc.actualrate - 1) AS DECIMAL(9,6))
			OPTION (MAXDOP 10)
	END	--Bettrans

--DW
IF EXISTS(SELECT * FROM #tmpWinlostDate WHERE DataSoure = 'DW')
	BEGIN
			INSERT INTO #FactCustWinloss
			(DataSource
			,[RptDate]
			,SiteID		
			,SportType	
			,[BetType]
			--,CurrencyID
			,TicketStatus
			--,LiveStatus
			,LeagueID
			,MatchID 
			--,BetFromID
			--,SuperID
			--,MasterID
			--,AgentID
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
			'DW' DataSource
			,mc.[RptDate]
			,CASE 
				WHEN mc.AgentID = 52466
					THEN - 2 --8RM
				WHEN mc.AgentID = 5707545
					THEN - 4 --BARM
				ELSE ISNULL(mc.siteid,-1)
			END AS SiteID		
			,mc.SportType	
			,mc.bettype [BetType]
			--,mc.currency CurrencyID
			,mc.TicketStatus --0: Nonlive | 1:Live | 2: Mixed		
			,ISNULL(mc.LeagueID,-1) LeagueID	
			,mc.MatchID  AS MatchID 
			--,ISNULL(mc.BetFrom ,'-1') BetFromID
			--,mc.srecommend SuperID
			--,mc.mrecommend MasterID
			--,mc.recommend AgentID
			,mc.CustID
			,e.rate actualrate
			,mc.VarianceVR
				
			/************************************************************MEASURE**********************************************************************************/
			,SUM(mc.Stake) Stake
			,SUM(mc.ActualStake) ActualStake
			,SUM(mc.WinlossIBC ) WinlossIBC
			,SUM(mc.WinlossS) WinlossS
			,SUM(WinlossM) WinlossM
			,SUM(WinlossA) WinlossA
			,SUM(WinlossP) WinlossP
			,SUM(TurnoverIBC) TurnoverIBC
			,SUM(TurnoverS) TurnoverS
			,SUM(TurnoverM) TurnoverM
			,SUM(TurnoverA) TurnoverA
			,SUM(CommissionS) CommissionS
			,SUM(CommissionM) CommissionM
			,SUM(CommissionA) CommissionA
			,SUM(CommissionP) CommissionP
			,SUM(ExtraWL) ExtraWL
			,SUM(ExtraTO) ExtraTO	
			,CAST(SUM(ExtraComm) AS [decimal](19, 6)) ExtraComm
			----
			,SUM(BetCount) AS BetCount		
			FROM DBDW2.bodb_Account.dbo.FactCustWinloss mc WITH (NOLOCK)		
					LEFT JOIN DBDW2.bodb_Account.dbo.tbl_currency_daily e  WITH (NOLOCK) ON mc .rptDate=e.exchangedate AND mc .currencyid=e.currency
			WHERE mc.RptDate IN (SELECT Winlostdate FROM #tmpWinlostDate WHERE DataSoure = 'DW')
					AND mc.CurrencyID NOT IN (20,27,28)
					AND mc.TicketStatus NOT IN (-1, 18, 9, 10, 14 )
					AND mc.Bettype IN(SELECT bettype FROM #tmpProduct)
			GROUP BY mc.[RptDate]
				,CASE 
					WHEN mc.AgentID = 52466
						THEN - 2 --8RM
					WHEN mc.AgentID = 5707545
						THEN - 4 --BARM
					ELSE ISNULL(mc.siteid,-1)
				END 	
				,mc.SportType	
				,mc.bettype
				--,mc.currency CurrencyID
				,mc.TicketStatus --0: Nonlive | 1:Live | 2: Mixed		
				,ISNULL(mc.LeagueID,-1)	
				,mc.MatchID
				--,ISNULL(mc.BetFrom ,'-1') BetFromID
				--,mc.srecommend SuperID
				--,mc.mrecommend MasterID
				--,mc.recommend AgentID
				,mc.CustID
				,e.rate
				,mc.VarianceVR
			OPTION (MAXDOP 10)
				
	END	--Warehouse

IF OBJECT_ID('tempdb..#SiteName') IS NOT NULL
	BEGIN
		DROP TABLE #SiteName
	END	
CREATE TABLE #SiteName (DataSource VARCHAR(100),SiteID int,SiteName varchar(1000),isDeposit INT)

INSERT INTO #SiteName(DataSource,SiteID,SiteName,isDeposit)
SELECT 'Bettrans' DataSource,SiteID,Site,isDeposit FROM bodb02.dbo.Site si (NOLOCK)
UNION ALL
SELECT 'DW' DataSource,SiteID,Site,isDeposit FROM DBDW2.bodb_account.dbo.tbl_site si (NOLOCK)
UNION ALL
SELECT 'Bettrans' DataSource,-4 SiteID,'BEST-ODDS' Site,1 isDeposit 
UNION ALL
SELECT 'Bettrans' DataSource,-2 SiteID,'XYZBET' Site,0 isDeposit
UNION ALL
SELECT 'DW' DataSource,-4 SiteID,'BEST-ODDS' Site,1 isDeposit 
UNION ALL
SELECT 'DW' DataSource,-2 SiteID,'XYZBET' Site,0 isDeposit
				
IF @SiteType <> 0
BEGIN
	IF @SiteType = 1 --Credit (Exclude CN88)
			DELETE #SiteName
			WHERE isDeposit = 1
				OR SiteName ='CN88';
		
	IF @SiteType = 2 --Cash
		DELETE #SiteName
		WHERE isDeposit = 2
		
	IF @SiteType = 3 --CN88
		DELETE #SiteName
		WHERE SiteName <>'CN88'
			
	DELETE b
	FROM
		#FactCustWinloss b 
	LEFT JOIN #tmpProduct P
		ON P.Bettype = b.Bettype
	LEFT JOIN #SiteName si_R (NOLOCK)
		ON si_R.siteid = b.siteid AND b.DataSource = si_R.DataSource
	LEFT JOIN #SiteName si_W (NOLOCK)
		ON si_W.siteid = b.siteid AND b.DataSource = si_W.DataSource
	WHERE (b.DataSource = 'bettrans' AND si_R.SiteID IS NULL)
		OR (b.DataSource = 'DW' AND si_W.SiteID IS NULL)
	
END

IF @SiteName <> ''
BEGIN
	DELETE #SiteName WHERE SiteName <> @SiteName;
			
	DELETE b
	FROM
		#FactCustWinloss b 
	LEFT JOIN #tmpProduct P
		ON P.Bettype = b.Bettype
	LEFT JOIN #SiteName si_R (NOLOCK)
		ON si_R.siteid = b.siteid AND b.DataSource = si_R.DataSource
	WHERE (si_R.SiteID IS NULL)
	
END
				
IF @SportType <> 0
BEGIN
	IF @SportType = -9
		BEGIN
			DELETE b FROM #FactCustWinloss b WHERE b.BetType NOT IN (9,29)
			SELECT @SportName = 'Parlay'
		END
	
	IF @SportType <> -9
		BEGIN
			DELETE b FROM #FactCustWinloss b WHERE b.SportType <> @SportType OR b.BetType IN (9,29)
			
			SELECT @SportName = SportName From bodb02.dbo.Sports s(NOLOCK) WHERE SportType = @SportType 
		END
END

IF @ReportBy IN(0,1)
BEGIN
	PRINT 'Start Processing compare by product'

	IF OBJECT_ID('tempdb..#tmpReportProduct') IS NOT NULL
		BEGIN
			DROP TABLE #tmpReportProduct
		END	 

	SELECT 	 'Saba' GroupType,
			b.RptDate,
			'Saba-'+ sp.SportName  ProductName,
			COUNT(DISTINCT b.CustID) ActiveMember,
			COUNT(DISTINCT CASE WHEN p.ProductID IN(1) THEN b.MatchID ELSE NULL END) NoMatch,
			-- [Bet Count]
			SUM(CASE WHEN b.BetType = 500 THEN 0 
					 ELSE BetCount  END) BetCount,
			SUM(b.WinlossP * b.ActualRate) [WinlossMember],
			SUM(b.Stake * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)) [TurnoverMember],
			-- [Commission]
			SUM(-b.CommissionS*b.ActualRate) Commission,
			-- [Company Real Income]
			SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * b.ActualRate*CASE WHEN b.SiteID NOT IN(-2,-4) THEN 1 ELSE 0 END) HouseIncome,
			-- [Company Real Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
				(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) HouseTurnOver,
			-- [Company Virtual Income]
			SUM(-((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
					+ (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)
				 ) * b.ActualRate) [HouseVirtualWinloss],
			-- [Company Virtual Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [HouseVirtualTurnover],
			-- [Variance WL]
			SUM((b.WinlossIBC - b.ExtraWL
					+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * b.ActualRate) [Variance Winloss],--90
			-- [Variance Turnover]
			SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [Variance Turnover]
			INTO #tmpReportProduct
			FROM
				#FactCustWinloss b with (nolock)
				 LEFT JOIN bodb02.dbo.Sports sp (NOLOCK)
						ON sp.SportType = b.SportType
				 LEFT JOIN bodb02.dbo.League l (NOLOCK)
						ON l.LeagueID = b.LeagueID
			   LEFT JOIN #tmpProduct P
				ON P.Bettype = b.Bettype
			 WHERE ISNULL(l.LeagueGroupID,-1)IN (42,74)
				AND b.BetType NOT IN(9,29)
			GROUP BY 
				b.RptDate,
				'Saba-'+ sp.SportName 

	INSERT INTO #tmpReportProduct
	SELECT 	  'All' GroupType,
			b.RptDate,
			CASE WHEN b.Bettype IN (9,29) THEN 'Parlay' 
				WHEN @SportName <> '' THEN @SportName
				WHEN p.ProductName = 'SportsBook' AND sp.SportName ='Soccer' THEN 'Soccer'
				WHEN p.ProductName = 'SportsBook' AND sp.SportName <>'Soccer' THEN 'Other Sports'
				ELSE p.ProductName END ProductName,
			COUNT(DISTINCT b.CustID) ActiveMember,
			COUNT(DISTINCT CASE WHEN p.ProductID IN(1) THEN b.MatchID ELSE NULL END) NoMatch,
			-- [Bet Count]
			SUM(CASE WHEN b.BetType = 500 THEN 0 
					 ELSE BetCount  END) BetCount,
			SUM(b.WinlossP * b.ActualRate) [WinlossMember],
			SUM(b.Stake * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)) [TurnoverMember],
			-- [Commission]
			SUM(-b.CommissionS*b.ActualRate) Commission,
			-- [Company Real Income]
			SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * b.ActualRate*CASE WHEN b.SiteID NOT IN(-2,-4) THEN 1 ELSE 0 END) HouseIncome,
			-- [Company Real Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
				(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) HouseTurnOver,
			-- [Company Virtual Income]
			SUM(-((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
					+ (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)
				 ) * b.ActualRate) [HouseVirtualWinloss],
			-- [Company Virtual Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)							 
				) [HouseVirtualTurnover],
			-- [Variance WL]
			SUM((b.WinlossIBC - b.ExtraWL
					+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * b.ActualRate) [Variance Winloss],--90
			-- [Variance Turnover]
			SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [Variance Turnover]
			FROM
				#FactCustWinloss b with (nolock)				
				 LEFT JOIN bodb02.dbo.Sports sp (NOLOCK)
						ON sp.SportType = b.SportType
			   LEFT JOIN #tmpProduct P
				ON P.Bettype = b.Bettype 
			GROUP BY
				b.RptDate,
				CASE WHEN b.Bettype IN (9,29) THEN 'Parlay' 
				WHEN @SportName <> '' THEN @SportName
				WHEN p.ProductName = 'SportsBook' AND sp.SportName ='Soccer' THEN 'Soccer'
				WHEN p.ProductName = 'SportsBook' AND sp.SportName <>'Soccer' THEN 'Other Sports'
				ELSE p.ProductName END

	SELECT 'Product' ReportType
	
	;WITH CTE
	AS	(
		SELECT MAX(rptDate) rptDate_MAX FROM #tmpReportProduct
		)
	SELECT td.ProductName,
			td.NoMatch NoMatch,
			td.ActiveMember ActiveMember,
			td.BetCount BetCount,
			td.[TurnoverMember] Mem_TO,
			td.[WinlossMember] Mem_WL,
			CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END Mem_MG,
			td.HouseTurnOver	House_Real_TO,
			td.HouseIncome	House_Real_WL,
			CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END House_Real_MG,
			td.[HouseVirtualTurnover] House_Virtual_TO,
			td.[HouseVirtualWinloss] House_Virtual_WL,
			CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END House_Virtual_MG,
			
			CASE WHEN yd.NoMatch <> 0 THEN ((td.NoMatch - yd.NoMatch)*100.0 /yd.NoMatch)ELSE 0.0 END [PerChange NoMatch],
			ISNULL(td.NoMatch - yd.NoMatch,0) [Diff NoMatch],
			CASE WHEN yd.ActiveMember <> 0 THEN ((td.ActiveMember - yd.ActiveMember)*100.0 /yd.ActiveMember)ELSE 0.0 END [PerChange ActiveMember],
			ISNULL(td.ActiveMember - yd.ActiveMember,0) [Diff ActiveMember],
			CASE WHEN yd.BetCount <> 0 THEN ((td.BetCount - yd.BetCount)*100.0/yd.BetCount) ELSE 0.0 END [PerChange BetCount],
			ISNULL(td.BetCount - yd.BetCount,0) [Diff BetCount],
			
			CASE WHEN yd.TurnoverMember <> 0 THEN ((td.TurnoverMember - yd.TurnoverMember)*100.0/yd.TurnoverMember) ELSE 0 END [PerChange Mem_TO],
			ISNULL(td.TurnoverMember - yd.TurnoverMember,0) [Diff TurnoverMember],
			CASE WHEN yd.WinlossMember <> 0 THEN ((td.WinlossMember - yd.WinlossMember)*100.0/ABS(yd.WinlossMember)) ELSE 0.0 END [PerChange Mem_WL],
			ISNULL(td.WinlossMember - yd.WinlossMember,0) [Diff WinlossMember],
			CASE WHEN CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END <> 0 
					THEN CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END
						- CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END
				 ELSE 0 END [PerChange Mem_MG],
			ISNULL(CASE WHEN CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END <> 0 
					THEN CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END
						- CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END
				 ELSE 0 END,0)  [Diff Mem_MG],
			
			CASE WHEN yd.HouseTurnOver <> 0 THEN ((td.HouseTurnOver - yd.HouseTurnOver)*100.0/yd.HouseTurnOver) ELSE 0 END [PerChange House_Real_TO],
			ISNULL(td.HouseTurnOver - yd.HouseTurnOver,0) [Diff HouseTurnOver],
			CASE WHEN yd.HouseIncome <> 0 THEN ((td.HouseIncome - yd.HouseIncome)*100.0/ABS(yd.HouseIncome)) ELSE 0 END [PerChange House_Real_WL],
			ISNULL(td.HouseIncome - yd.HouseIncome,0) [Diff HouseIncome],
			CASE WHEN CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END <> 0 
					THEN CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END
						- CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END
				 ELSE 0 END [PerChange House_Real_MG],
			ISNULL(CASE WHEN CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END <> 0 
					THEN CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END
						- CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END
				 ELSE 0 END,0) [Diff House_Real_MG],
			
			CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN ((td.[HouseVirtualTurnover] - yd.[HouseVirtualTurnover])*100.0/yd.[HouseVirtualTurnover]) ELSE 0 END [PerChange House_Virtual_TO],
			ISNULL(td.[HouseVirtualTurnover] - yd.[HouseVirtualTurnover],0) [Diff House_Virtual_TO],
			CASE WHEN yd.[HouseVirtualWinloss] <> 0 THEN ((td.[HouseVirtualWinloss] - yd.[HouseVirtualWinloss])*100.0/ABS(yd.[HouseVirtualWinloss])) ELSE 0 END [PerChange House_Virtual_WL],
			ISNULL(td.[HouseVirtualWinloss] - yd.[HouseVirtualWinloss],0) [Diff House_Virtual_WL],
			CASE WHEN CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END <> 0 
					THEN CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END
						- CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END
				 ELSE 0 END [PerChange House_Virtual_MG],
			ISNULL(CASE WHEN CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END <> 0 
					THEN CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END
						- CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END
				 ELSE 0 END,0) [Diff House_Virtual_MG],
				 
			CASE WHEN td.ProductName LIKE 'Saba-Soccer' THEN 1
				WHEN td.ProductName LIKE 'Saba-Basketball' THEN 2
				WHEN td.ProductName LIKE 'Saba-Cricket' THEN 3
				WHEN td.ProductName LIKE 'Saba-%' THEN 4
				WHEN td.ProductName LIKE 'Soccer' THEN 11
				WHEN td.ProductName LIKE 'Other Sports' THEN 12
				WHEN td.ProductName LIKE 'Parlay' THEN 13
				ELSE 101
				END ORDERID
	FROM #tmpReportProduct td
		INNER JOIN CTE rptMax ON td.RptDate = rptMax.rptDate_MAX 
		LEFT JOIN #tmpReportProduct yd
		ON td.GroupType = yd.GroupType
			AND td.ProductName = yd.ProductName
			AND td.RptDate <> yd.RptDate
	ORDER BY ORDERID , td.HouseTurnOver DESC 

	PRINT 'End Processing compare by product'
END

IF @ReportBy IN(0,2)
BEGIN
	PRINT 'Start Processing compare by product Site'

	IF OBJECT_ID('tempdb..#tmpReportProductSite') IS NOT NULL
		BEGIN
			DROP TABLE #tmpReportProductSite
		END	 

	SELECT 	 'Saba' GroupType,
			b.RptDate,
			CASE WHEN b.SiteID = -4 THEN 'Cash' 
				WHEN b.SiteID = -2 THEN 'Credit'
				WHEN si_R.SiteName IN ('CN88','789Y') THEN si_R.SiteName
				WHEN si_R.isDeposit = 1 THEN 'Cash' 
				WHEN si_R.isDeposit = 0 THEN 'Credit'
				ELSE 'Credit'
			END SiteType,
			'Saba-'+ sp.SportName  ProductName,
			COUNT(DISTINCT b.CustID) ActiveMember,
			COUNT(DISTINCT CASE WHEN p.ProductID IN(1) THEN b.MatchID ELSE NULL END) NoMatch,
			-- [Bet Count]
			SUM(CASE WHEN b.BetType = 500 THEN 0 
					 ELSE BetCount  END) BetCount,
			SUM(b.WinlossP * b.ActualRate) [WinlossMember],
			SUM(b.Stake * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)) [TurnoverMember],
			-- [Commission]
			SUM(-b.CommissionS*b.ActualRate) Commission,
			-- [Company Real Income]
			SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * b.ActualRate*CASE WHEN b.SiteID NOT IN(-2,-4) THEN 1 ELSE 0 END) HouseIncome,
			-- [Company Real Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
				(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) HouseTurnOver,
			-- [Company Virtual Income]
			SUM(-((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
					+ (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)
				 ) * b.ActualRate) [HouseVirtualWinloss],
			-- [Company Virtual Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [HouseVirtualTurnover],
			-- [Variance WL]
			SUM((b.WinlossIBC - b.ExtraWL
					+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * b.ActualRate) [Variance Winloss],--90
			-- [Variance Turnover]
			SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [Variance Turnover]
			INTO #tmpReportProductSite
			FROM
				#FactCustWinloss b with (nolock)
				 LEFT JOIN bodb02.dbo.Sports sp (NOLOCK)
						ON sp.SportType = b.SportType
				 LEFT JOIN bodb02.dbo.League l (NOLOCK)
						ON l.LeagueID = b.LeagueID
			   LEFT JOIN #tmpProduct P
				ON P.Bettype = b.Bettype
				 LEFT JOIN #SiteName si_R (NOLOCK)
						ON si_R.siteid = b.siteid AND b.DataSource =si_R.DataSource
			 WHERE ISNULL(l.LeagueGroupID,-1)IN (42,74)
				AND b.BetType NOT IN(9,29)
			GROUP BY 
				b.RptDate,
			CASE WHEN b.SiteID = -4 THEN 'Cash' 
				WHEN b.SiteID = -2 THEN 'Credit'
				WHEN si_R.SiteName IN ('CN88','789Y') THEN si_R.SiteName
				WHEN si_R.isDeposit = 1 THEN 'Cash' 
				WHEN si_R.isDeposit = 0 THEN 'Credit'
				ELSE 'Credit'
			END,
				'Saba-'+ sp.SportName 
	 
	INSERT INTO #tmpReportProductSite
	SELECT 	 'All' GroupType,
			b.RptDate,
			CASE WHEN b.SiteID = -4 THEN 'Cash' 
				WHEN b.SiteID = -2 THEN 'Credit'
				WHEN si_R.SiteName IN ('CN88','789Y') THEN si_R.SiteName
				WHEN si_R.isDeposit = 1 THEN 'Cash' 
				WHEN si_R.isDeposit = 0 THEN 'Credit'
				ELSE 'Credit'
			END SiteType,
			CASE WHEN b.Bettype IN (9,29) THEN 'Parlay' 
				WHEN @SportName <> '' THEN @SportName
				WHEN p.ProductName = 'SportsBook' AND sp.SportName ='Soccer' THEN 'Soccer'
				WHEN p.ProductName = 'SportsBook' AND sp.SportName <>'Soccer' THEN 'Other Sports'
				ELSE p.ProductName END ProductName,
			COUNT(DISTINCT b.CustID) ActiveMember,
			COUNT(DISTINCT CASE WHEN p.ProductID IN(1) THEN b.MatchID ELSE NULL END) NoMatch,
			-- [Bet Count]
			SUM(CASE WHEN b.BetType = 500 THEN 0 
					 ELSE BetCount  END) BetCount,
			SUM(b.WinlossP * b.ActualRate) [WinlossMember],
			SUM(b.Stake * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)) [TurnoverMember],
			-- [Commission]
			SUM(-b.CommissionS*b.ActualRate) Commission,
			-- [Company Real Income]
			SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * b.ActualRate*CASE WHEN b.SiteID NOT IN(-2,-4) THEN 1 ELSE 0 END) HouseIncome,
			-- [Company Real Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
				(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) HouseTurnOver,
			-- [Company Virtual Income]
			SUM(-((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
					+ (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)
				 ) * b.ActualRate) [HouseVirtualWinloss],
			-- [Company Virtual Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [HouseVirtualTurnover],
			-- [Variance WL]
			SUM((b.WinlossIBC - b.ExtraWL
					+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * b.ActualRate) [Variance Winloss],--90
			-- [Variance Turnover]
			SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [Variance Turnover]
			FROM
				#FactCustWinloss b with (nolock)
				 LEFT JOIN bodb02.dbo.Sports sp (NOLOCK)
						ON sp.SportType = b.SportType
				 LEFT JOIN bodb02.dbo.League l (NOLOCK)
						ON l.LeagueID = b.LeagueID
			   LEFT JOIN #tmpProduct P
				ON P.Bettype = b.Bettype
				 LEFT JOIN #SiteName si_R (NOLOCK)
						ON si_R.siteid = b.siteid AND b.DataSource =si_R.DataSource 
			GROUP BY 
				b.RptDate,
			CASE WHEN b.SiteID = -4 THEN 'Cash' 
				WHEN b.SiteID = -2 THEN 'Credit'
				WHEN si_R.SiteName IN ('CN88','789Y') THEN si_R.SiteName
				WHEN si_R.isDeposit = 1 THEN 'Cash' 
				WHEN si_R.isDeposit = 0 THEN 'Credit'
				ELSE 'Credit'
			END,
			CASE WHEN b.Bettype IN (9,29) THEN 'Parlay' 
				WHEN @SportName <> '' THEN @SportName
				WHEN p.ProductName = 'SportsBook' AND sp.SportName ='Soccer' THEN 'Soccer'
				WHEN p.ProductName = 'SportsBook' AND sp.SportName <>'Soccer' THEN 'Other Sports'
				ELSE p.ProductName END

	SELECT 'Site-Product' ReportType	
	;WITH CTE
	AS	(
		SELECT MAX(rptDate) rptDate_MAX FROM #tmpReportProductSite
		)
	SELECT td.SiteType,
			td.ProductName,		
			td.NoMatch NoMatch,
			td.ActiveMember ActiveMember,
			td.BetCount BetCount,
			td.[TurnoverMember] Mem_TO,
			td.[WinlossMember] Mem_WL,
			CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END Mem_MG,
			td.HouseTurnOver	House_Real_TO,
			td.HouseIncome	House_Real_WL,
			CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END House_Real_MG,
			td.[HouseVirtualTurnover] House_Virtual_TO,
			td.[HouseVirtualWinloss] House_Virtual_WL,
			CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END House_Virtual_MG,
			
			CASE WHEN yd.NoMatch <> 0 THEN ((td.NoMatch - yd.NoMatch)*100.0 /yd.NoMatch)ELSE 0.0 END [PerChange NoMatch],
			ISNULL(td.NoMatch - yd.NoMatch,0) [Diff NoMatch],
			CASE WHEN yd.ActiveMember <> 0 THEN ((td.ActiveMember - yd.ActiveMember)*100.0 /yd.ActiveMember)ELSE 0.0 END [PerChange ActiveMember],
			ISNULL(td.ActiveMember - yd.ActiveMember,0) [Diff ActiveMember],
			CASE WHEN yd.BetCount <> 0 THEN ((td.BetCount - yd.BetCount)*100.0/yd.BetCount) ELSE 0.0 END [PerChange BetCount],
			ISNULL(td.BetCount - yd.BetCount,0) [Diff BetCount],
			
			CASE WHEN yd.TurnoverMember <> 0 THEN ((td.TurnoverMember - yd.TurnoverMember)*100.0/yd.TurnoverMember) ELSE 0 END [PerChange Mem_TO],
			ISNULL(td.TurnoverMember - yd.TurnoverMember,0) [Diff TurnoverMember],
			CASE WHEN yd.WinlossMember <> 0 THEN ((td.WinlossMember - yd.WinlossMember)*100.0/ABS(yd.WinlossMember)) ELSE 0.0 END [PerChange Mem_WL],
			ISNULL(td.WinlossMember - yd.WinlossMember,0) [Diff WinlossMember],
			CASE WHEN CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END <> 0 
					THEN CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END
						- CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END
				 ELSE 0 END [PerChange Mem_MG],
			ISNULL(CASE WHEN CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END <> 0 
					THEN CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END
						- CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END
				 ELSE 0 END,0)  [Diff Mem_MG],
			
			CASE WHEN yd.HouseTurnOver <> 0 THEN ((td.HouseTurnOver - yd.HouseTurnOver)*100.0/yd.HouseTurnOver) ELSE 0 END [PerChange House_Real_TO],
			ISNULL(td.HouseTurnOver - yd.HouseTurnOver,0) [Diff HouseTurnOver],
			CASE WHEN yd.HouseIncome <> 0 THEN ((td.HouseIncome - yd.HouseIncome)*100.0/ABS(yd.HouseIncome)) ELSE 0 END [PerChange House_Real_WL],
			ISNULL(td.HouseIncome - yd.HouseIncome,0) [Diff HouseIncome],
			CASE WHEN CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END <> 0 
					THEN CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END
						- CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END
				 ELSE 0 END [PerChange House_Real_MG],
			ISNULL(CASE WHEN CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END <> 0 
					THEN CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END
						- CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END
				 ELSE 0 END,0) [Diff House_Real_MG],
			
			CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN ((td.[HouseVirtualTurnover] - yd.[HouseVirtualTurnover])*100.0/yd.[HouseVirtualTurnover]) ELSE 0 END [PerChange House_Virtual_TO],
			ISNULL(td.[HouseVirtualTurnover] - yd.[HouseVirtualTurnover],0) [Diff House_Virtual_TO],
			CASE WHEN yd.[HouseVirtualWinloss] <> 0 THEN ((td.[HouseVirtualWinloss] - yd.[HouseVirtualWinloss])*100.0/ABS(yd.[HouseVirtualWinloss])) ELSE 0 END [PerChange House_Virtual_WL],
			ISNULL(td.[HouseVirtualWinloss] - yd.[HouseVirtualWinloss],0) [Diff House_Virtual_WL],
			CASE WHEN CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END <> 0 
					THEN CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END
						- CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END
				 ELSE 0 END [PerChange House_Virtual_MG],
			ISNULL(CASE WHEN CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END <> 0 
					THEN CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END
						- CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END
				 ELSE 0 END,0) [Diff House_Virtual_MG],
				 
			CASE WHEN td.ProductName LIKE 'Saba-Soccer' THEN 1
				WHEN td.ProductName LIKE 'Saba-Basketball' THEN 2
				WHEN td.ProductName LIKE 'Saba-Cricket' THEN 3
				WHEN td.ProductName LIKE 'Saba-%' THEN 4
				WHEN td.ProductName LIKE 'Soccer' THEN 11
				WHEN td.ProductName LIKE 'Other Sports' THEN 12
				WHEN td.ProductName LIKE 'Parlay' THEN 13
				ELSE 101
				END ORDERID
	FROM #tmpReportProductSite td
		INNER JOIN CTE rptMax ON td.RptDate = rptMax.rptDate_MAX 
		LEFT JOIN #tmpReportProductSite yd
		ON td.GroupType = yd.GroupType
			AND td.SiteType = yd.SiteType
			AND td.ProductName = yd.ProductName
			AND td.RptDate <> yd.RptDate
	ORDER BY ORDERID   

	PRINT 'End Processing compare by Site-product'
END

IF @ReportBy IN(0,3)
BEGIN
	PRINT 'Start Processing compare by Site Type'

	IF OBJECT_ID('tempdb..#tmpReportSiteType') IS NOT NULL
		BEGIN
			DROP TABLE #tmpReportSiteType
		END	 

	SELECT 	 
			b.RptDate,
			CASE WHEN b.SiteID = -4 THEN 'Cash' 
				WHEN b.SiteID = -2 THEN 'Credit'
				WHEN si_R.SiteName IN ('CN88','789Y') THEN si_R.SiteName 
				WHEN si_R.isDeposit = 1 THEN 'Cash' 
				WHEN si_R.isDeposit = 0 THEN 'Credit'	 
				ELSE 'Credit'
			END SiteType,
			COUNT(DISTINCT b.CustID) ActiveMember,
			COUNT(DISTINCT CASE WHEN p.ProductID IN(1) THEN b.MatchID ELSE NULL END) NoMatch,
			-- [Bet Count]
			SUM(CASE WHEN b.BetType = 500 THEN 0 
					 ELSE BetCount  END) BetCount,
			SUM(b.WinlossP * b.ActualRate) [WinlossMember],
			SUM(b.Stake * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)) [TurnoverMember],
			-- [Commission]
			SUM(-b.CommissionS*b.ActualRate) Commission,
			-- [Company Real Income]
			SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * b.ActualRate*CASE WHEN b.SiteID NOT IN(-2,-4) THEN 1 ELSE 0 END) HouseIncome,
			-- [Company Real Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
				(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) HouseTurnOver,
			-- [Company Virtual Income]
			SUM(-((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
					+ (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)
				 ) * b.ActualRate) [HouseVirtualWinloss],
			-- [Company Virtual Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [HouseVirtualTurnover],
			-- [Variance WL]
			SUM((b.WinlossIBC - b.ExtraWL
					+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * b.ActualRate) [Variance Winloss],--90
			-- [Variance Turnover]
			SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [Variance Turnover],
			CASE 
				WHEN si_R.SiteName IN ('789Y') THEN 1
				WHEN si_R.isDeposit = 0 OR b.SiteID = -2 THEN 10
				WHEN si_R.SiteName IN ('CN88') THEN 20
				WHEN si_R.isDeposit = 1 OR b.SiteID = -4  THEN 30
				ELSE 100
			END OrderID
			INTO #tmpReportSiteType
			FROM
				#FactCustWinloss b with (nolock)
				 LEFT JOIN bodb02.dbo.Sports sp (NOLOCK)
						ON sp.SportType = b.SportType
				 LEFT JOIN bodb02.dbo.League l (NOLOCK)
						ON l.LeagueID = b.LeagueID
			   LEFT JOIN #tmpProduct P
				ON P.Bettype = b.Bettype
				 LEFT JOIN #SiteName si_R (NOLOCK)
						ON si_R.siteid = b.siteid AND b.DataSource = si_R.DataSource
			GROUP BY 
				b.RptDate,
			CASE WHEN b.SiteID = -4 THEN 'Cash' 
				WHEN b.SiteID = -2 THEN 'Credit'
				WHEN si_R.SiteName IN ('CN88','789Y') THEN si_R.SiteName
				WHEN si_R.isDeposit = 1 THEN 'Cash' 
				WHEN si_R.isDeposit = 0 THEN 'Credit'
				ELSE 'Credit'
			END,
			CASE 
				WHEN si_R.SiteName IN ('789Y') THEN 1
				WHEN si_R.isDeposit = 0 OR b.SiteID = -2 THEN 10
				WHEN si_R.SiteName IN ('CN88') THEN 20
				WHEN si_R.isDeposit = 1 OR b.SiteID = -4  THEN 30
				ELSE 100
			END

	INSERT INTO #tmpReportSiteType
	SELECT 	 
			b.RptDate,
			'ALL Site' SiteType,
			COUNT(DISTINCT b.CustID) ActiveMember,
			COUNT(DISTINCT CASE WHEN p.ProductID IN(1) THEN b.MatchID ELSE NULL END) NoMatch,
			-- [Bet Count]
			SUM(CASE WHEN b.BetType = 500 THEN 0 
					 ELSE BetCount  END) BetCount,
			SUM(b.WinlossP * b.ActualRate) [WinlossMember],
			SUM(b.Stake * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)) [TurnoverMember],
			-- [Commission]
			SUM(-b.CommissionS*b.ActualRate) Commission,
			-- [Company Real Income]
			SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * b.ActualRate*CASE WHEN b.SiteID NOT IN(-2,-4) THEN 1 ELSE 0 END) HouseIncome,
			-- [Company Real Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
				(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) HouseTurnOver,
			-- [Company Virtual Income]
			SUM(-((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
					+ (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)
				 ) * b.ActualRate) [HouseVirtualWinloss],
			-- [Company Virtual Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [HouseVirtualTurnover],
			-- [Variance WL]
			SUM((b.WinlossIBC - b.ExtraWL
					+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * b.ActualRate) [Variance Winloss],--90
			-- [Variance Turnover]
			SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [Variance Turnover],
			1000 OrderID
			FROM
				#FactCustWinloss b with (nolock)
				 LEFT JOIN #SiteName si_R (NOLOCK)
						ON si_R.siteid = b.siteid AND b.DataSource = si_R.DataSource
				 LEFT JOIN #tmpProduct P
					ON P.Bettype = b.Bettype
			GROUP BY 
				b.RptDate
	 	 
	SELECT 'Site Type' ReportType	
	;WITH CTE
	AS	(
		SELECT MAX(rptDate) rptDate_MAX FROM #tmpReportSiteType
		)
	SELECT td.SiteType,		
			td.NoMatch NoMatch,
			td.ActiveMember ActiveMember,
			td.BetCount BetCount,
			td.[TurnoverMember] Mem_TO,
			td.[WinlossMember] Mem_WL,
			CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END Mem_MG,
			td.HouseTurnOver	House_Real_TO,
			td.HouseIncome	House_Real_WL,
			CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END House_Real_MG,
			td.[HouseVirtualTurnover] House_Virtual_TO,
			td.[HouseVirtualWinloss] House_Virtual_WL,
			CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END House_Virtual_MG,
			
			CASE WHEN yd.NoMatch <> 0 THEN ((td.NoMatch - yd.NoMatch)*100.0 /yd.NoMatch)ELSE 0.0 END [PerChange NoMatch],
			ISNULL(td.NoMatch - yd.NoMatch,0) [Diff NoMatch],
			CASE WHEN yd.ActiveMember <> 0 THEN ((td.ActiveMember - yd.ActiveMember)*100.0 /yd.ActiveMember)ELSE 0.0 END [PerChange ActiveMember],
			ISNULL(td.ActiveMember - yd.ActiveMember,0) [Diff ActiveMember],
			CASE WHEN yd.BetCount <> 0 THEN ((td.BetCount - yd.BetCount)*100.0/yd.BetCount) ELSE 0.0 END [PerChange BetCount],
			ISNULL(td.BetCount - yd.BetCount,0) [Diff BetCount],
			
			CASE WHEN yd.TurnoverMember <> 0 THEN ((td.TurnoverMember - yd.TurnoverMember)*100.0/yd.TurnoverMember) ELSE 0 END [PerChange Mem_TO],
			ISNULL(td.TurnoverMember - yd.TurnoverMember,0) [Diff TurnoverMember],
			CASE WHEN yd.WinlossMember <> 0 THEN ((td.WinlossMember - yd.WinlossMember)*100.0/ABS(yd.WinlossMember)) ELSE 0.0 END [PerChange Mem_WL],
			ISNULL(td.WinlossMember - yd.WinlossMember,0) [Diff WinlossMember],
			CASE WHEN CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END <> 0 
					THEN CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END
						- CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END
				 ELSE 0 END [PerChange Mem_MG],
			ISNULL(CASE WHEN CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END <> 0 
					THEN CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END
						- CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END
				 ELSE 0 END,0)  [Diff Mem_MG],
			
			CASE WHEN yd.HouseTurnOver <> 0 THEN ((td.HouseTurnOver - yd.HouseTurnOver)*100.0/yd.HouseTurnOver) ELSE 0 END [PerChange House_Real_TO],
			ISNULL(td.HouseTurnOver - yd.HouseTurnOver,0) [Diff HouseTurnOver],
			CASE WHEN yd.HouseIncome <> 0 THEN ((td.HouseIncome - yd.HouseIncome)*100.0/ABS(yd.HouseIncome)) ELSE 0 END [PerChange House_Real_WL],
			ISNULL(td.HouseIncome - yd.HouseIncome,0) [Diff HouseIncome],
			CASE WHEN CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END <> 0 
					THEN CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END
						- CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END
				 ELSE 0 END [PerChange House_Real_MG],
			ISNULL(CASE WHEN CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END <> 0 
					THEN CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END
						- CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END
				 ELSE 0 END,0) [Diff House_Real_MG],
			
			CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN ((td.[HouseVirtualTurnover] - yd.[HouseVirtualTurnover])*100.0/yd.[HouseVirtualTurnover]) ELSE 0 END [PerChange House_Virtual_TO],
			ISNULL(td.[HouseVirtualTurnover] - yd.[HouseVirtualTurnover],0) [Diff House_Virtual_TO],
			CASE WHEN yd.[HouseVirtualWinloss] <> 0 THEN ((td.[HouseVirtualWinloss] - yd.[HouseVirtualWinloss])*100.0/ABS(yd.[HouseVirtualWinloss])) ELSE 0 END [PerChange House_Virtual_WL],
			ISNULL(td.[HouseVirtualWinloss] - yd.[HouseVirtualWinloss],0) [Diff House_Virtual_WL],
			CASE WHEN CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END <> 0 
					THEN CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END
						- CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END
				 ELSE 0 END [PerChange House_Virtual_MG],
			ISNULL(CASE WHEN CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END <> 0 
					THEN CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END
						- CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END
				 ELSE 0 END,0) [Diff House_Virtual_MG]
				  
	FROM #tmpReportSiteType td
		INNER JOIN CTE rptMax ON td.RptDate = rptMax.rptDate_MAX 
		LEFT JOIN #tmpReportSiteType yd
		ON  td.SiteType = yd.SiteType
			AND td.RptDate <> yd.RptDate
	ORDER BY td.OrderID

	PRINT 'End Processing compare by Site Type'
END

IF @ReportBy IN(0,4)
	BEGIN
	PRINT 'Start Processing compare by Site'

	IF OBJECT_ID('tempdb..#tmpReportSite') IS NOT NULL
		BEGIN
			DROP TABLE #tmpReportSite
		END	 

	SELECT 	 
			b.RptDate,
			CASE WHEN b.SiteID = -4 THEN 'Cash' 
				WHEN b.SiteID = -2 THEN 'Credit'
				WHEN si_R.SiteName IN ('CN88','789Y') THEN si_R.SiteName
				WHEN si_R.isDeposit = 1 THEN 'Cash' 
				WHEN si_R.isDeposit = 0 THEN 'Credit'
				ELSE 'Credit'
			END SiteType,
			CASE WHEN b.SiteID = -4 THEN 'BEST-ODDS' 
				WHEN b.SiteID = -2 THEN 'XYZBET'
				WHEN si_R.SiteName IS NOT NULL THEN si_R.SiteName
				ELSE 'N/A'
			END SiteName,
			COUNT(DISTINCT b.CustID) ActiveMember,
			COUNT(DISTINCT CASE WHEN p.ProductID IN(1) THEN b.MatchID ELSE NULL END) NoMatch,
			-- [Bet Count]
			SUM(CASE WHEN b.BetType = 500 THEN 0 
					 ELSE BetCount  END) BetCount,
			SUM(b.WinlossP * b.ActualRate) [WinlossMember],
			SUM(b.Stake * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)) [TurnoverMember],
			-- [Commission]
			SUM(-b.CommissionS*b.ActualRate) Commission,
			-- [Company Real Income]
			SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * b.ActualRate*CASE WHEN b.SiteID NOT IN(-2,-4) THEN 1 ELSE 0 END) HouseIncome,
			-- [Company Real Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
				(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) HouseTurnOver,
			-- [Company Virtual Income]
			SUM(-((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
					+ (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)
				 ) * b.ActualRate) [HouseVirtualWinloss],
			-- [Company Virtual Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [HouseVirtualTurnover],
			-- [Variance WL]
			SUM((b.WinlossIBC - b.ExtraWL
					+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * b.ActualRate) [Variance Winloss],--90
			-- [Variance Turnover]
			SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [Variance Turnover]
			INTO #tmpReportSite
			FROM
				#FactCustWinloss b with (nolock)
				 LEFT JOIN bodb02.dbo.Sports sp (NOLOCK)
						ON sp.SportType = b.SportType
				 LEFT JOIN bodb02.dbo.League l (NOLOCK)
						ON l.LeagueID = b.LeagueID
			   LEFT JOIN #tmpProduct P
				ON P.Bettype = b.Bettype
				 LEFT JOIN #SiteName si_R (NOLOCK)
						ON si_R.siteid = b.siteid AND b.DataSource =si_R.DataSource
			GROUP BY 
				b.RptDate,
			CASE WHEN b.SiteID = -4 THEN 'Cash' 
				WHEN b.SiteID = -2 THEN 'Credit'
				WHEN si_R.SiteName IN ('CN88','789Y') THEN si_R.SiteName
				WHEN si_R.isDeposit = 1 THEN 'Cash' 
				WHEN si_R.isDeposit = 0 THEN 'Credit'
				ELSE 'Credit'
			END,
			CASE WHEN b.SiteID = -4 THEN 'BEST-ODDS' 
				WHEN b.SiteID = -2 THEN 'XYZBET'
				WHEN si_R.SiteName IS NOT NULL THEN si_R.SiteName
				ELSE 'N/A'
			END

	SELECT 'Site' ReportType
	
	;WITH CTE
	AS	(
		SELECT MAX(rptDate) rptDate_MAX FROM #tmpReportSite
		)
	SELECT td.SiteType,
			td.SiteName,	
			td.NoMatch NoMatch,
			td.ActiveMember ActiveMember,
			td.BetCount BetCount,
			td.[TurnoverMember] Mem_TO,
			td.[WinlossMember] Mem_WL,
			CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END Mem_MG,
			td.HouseTurnOver	House_Real_TO,
			td.HouseIncome	House_Real_WL,
			CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END House_Real_MG,
			td.[HouseVirtualTurnover] House_Virtual_TO,
			td.[HouseVirtualWinloss] House_Virtual_WL,
			CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END House_Virtual_MG,
			
			CASE WHEN yd.NoMatch <> 0 THEN ((td.NoMatch - yd.NoMatch)*100.0 /yd.NoMatch)ELSE 0.0 END [PerChange NoMatch],
			ISNULL(td.NoMatch - yd.NoMatch,0) [Diff NoMatch],
			CASE WHEN yd.ActiveMember <> 0 THEN ((td.ActiveMember - yd.ActiveMember)*100.0 /yd.ActiveMember)ELSE 0.0 END [PerChange ActiveMember],
			ISNULL(td.ActiveMember - yd.ActiveMember,0) [Diff ActiveMember],
			CASE WHEN yd.BetCount <> 0 THEN ((td.BetCount - yd.BetCount)*100.0/yd.BetCount) ELSE 0.0 END [PerChange BetCount],
			ISNULL(td.BetCount - yd.BetCount,0) [Diff BetCount],
			
			CASE WHEN yd.TurnoverMember <> 0 THEN ((td.TurnoverMember - yd.TurnoverMember)*100.0/yd.TurnoverMember) ELSE 0 END [PerChange Mem_TO],
			ISNULL(td.TurnoverMember - yd.TurnoverMember,0) [Diff TurnoverMember],
			CASE WHEN yd.WinlossMember <> 0 THEN ((td.WinlossMember - yd.WinlossMember)*100.0/ABS(yd.WinlossMember)) ELSE 0.0 END [PerChange Mem_WL],
			ISNULL(td.WinlossMember - yd.WinlossMember,0) [Diff WinlossMember],
			CASE WHEN CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END <> 0 
					THEN CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END
						- CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END
				 ELSE 0 END [PerChange Mem_MG],
			ISNULL(CASE WHEN CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END <> 0 
					THEN CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END
						- CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END
				 ELSE 0 END,0)  [Diff Mem_MG],
			
			CASE WHEN yd.HouseTurnOver <> 0 THEN ((td.HouseTurnOver - yd.HouseTurnOver)*100.0/yd.HouseTurnOver) ELSE 0 END [PerChange House_Real_TO],
			ISNULL(td.HouseTurnOver - yd.HouseTurnOver,0) [Diff HouseTurnOver],
			CASE WHEN yd.HouseIncome <> 0 THEN ((td.HouseIncome - yd.HouseIncome)*100.0/ABS(yd.HouseIncome)) ELSE 0 END [PerChange House_Real_WL],
			ISNULL(td.HouseIncome - yd.HouseIncome,0) [Diff HouseIncome],
			CASE WHEN CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END <> 0 
					THEN CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END
						- CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END
				 ELSE 0 END [PerChange House_Real_MG],
			ISNULL(CASE WHEN CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END <> 0 
					THEN CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END
						- CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END
				 ELSE 0 END,0) [Diff House_Real_MG],
			
			CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN ((td.[HouseVirtualTurnover] - yd.[HouseVirtualTurnover])*100.0/yd.[HouseVirtualTurnover]) ELSE 0 END [PerChange House_Virtual_TO],
			ISNULL(td.[HouseVirtualTurnover] - yd.[HouseVirtualTurnover],0) [Diff House_Virtual_TO],
			CASE WHEN yd.[HouseVirtualWinloss] <> 0 THEN ((td.[HouseVirtualWinloss] - yd.[HouseVirtualWinloss])*100.0/ABS(yd.[HouseVirtualWinloss])) ELSE 0 END [PerChange House_Virtual_WL],
			ISNULL(td.[HouseVirtualWinloss] - yd.[HouseVirtualWinloss],0) [Diff House_Virtual_WL],
			CASE WHEN CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END <> 0 
					THEN CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END
						- CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END
				 ELSE 0 END [PerChange House_Virtual_MG],
			ISNULL(CASE WHEN CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END <> 0 
					THEN CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END
						- CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END
				 ELSE 0 END,0) [Diff House_Virtual_MG]
				  
	FROM #tmpReportSite td
		INNER JOIN CTE rptMax ON td.RptDate = rptMax.rptDate_MAX 
		LEFT JOIN #tmpReportSite yd
		ON  td.SiteType = yd.SiteType
			AND td.SiteName = yd.SiteName
			AND td.RptDate <> yd.RptDate
	ORDER BY td.SiteType 

	PRINT 'End Processing compare by Site'
END 

IF @ReportBy IN(0,5)
	BEGIN
	PRINT 'Start Processing compare by Site Product'

	IF OBJECT_ID('tempdb..#tmpReportSiteProduct') IS NOT NULL
		BEGIN
			DROP TABLE #tmpReportSiteProduct
		END	 

	SELECT 	 
			b.RptDate,
			CASE WHEN b.SiteID = -4 THEN 'Cash' 
				WHEN b.SiteID = -2 THEN 'Credit'
				WHEN si_R.SiteName IN ('CN88','789Y') THEN si_R.SiteName
				WHEN si_R.isDeposit = 1 THEN 'Cash' 
				WHEN si_R.isDeposit = 0 THEN 'Credit'
				ELSE 'Credit'
			END SiteType,
			CASE WHEN b.SiteID = -4 THEN 'BEST-ODDS' 
				WHEN b.SiteID = -2 THEN 'XYZBET'
				WHEN si_R.SiteName IS NOT NULL THEN si_R.SiteName
				ELSE 'N/A'
			END SiteName,
			CASE WHEN b.Bettype IN (9,29) THEN 'Parlay' 
				WHEN @SportName <> '' THEN @SportName
				WHEN p.ProductName = 'SportsBook' AND sp.SportName ='Soccer' THEN 'Soccer'
				WHEN p.ProductName = 'SportsBook' AND sp.SportName <>'Soccer' THEN 'Other Sports'
				ELSE p.ProductName END ProductName,
			COUNT(DISTINCT b.CustID) ActiveMember,
			COUNT(DISTINCT CASE WHEN p.ProductID IN(1) THEN b.MatchID ELSE NULL END) NoMatch,
			-- [Bet Count]
			SUM(CASE WHEN b.BetType = 500 THEN 0 
					 ELSE BetCount  END) BetCount,
			SUM(b.WinlossP * b.ActualRate) [WinlossMember],
			SUM(b.Stake * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)) [TurnoverMember],
			-- [Commission]
			SUM(-b.CommissionS*b.ActualRate) Commission,
			-- [Company Real Income]
			SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * b.ActualRate*CASE WHEN b.SiteID NOT IN(-2,-4) THEN 1 ELSE 0 END) HouseIncome,
			-- [Company Real Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
				(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) HouseTurnOver,
			-- [Company Virtual Income]
			SUM(-((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
					+ (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)
				 ) * b.ActualRate) [HouseVirtualWinloss],
			-- [Company Virtual Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [HouseVirtualTurnover],
			-- [Variance WL]
			SUM((b.WinlossIBC - b.ExtraWL
					+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * b.ActualRate) [Variance Winloss],--90
			-- [Variance Turnover]
			SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [Variance Turnover]
			INTO #tmpReportSiteProduct
			FROM
				#FactCustWinloss b with (nolock)
				 LEFT JOIN bodb02.dbo.Sports sp (NOLOCK)
						ON sp.SportType = b.SportType
				 LEFT JOIN bodb02.dbo.League l (NOLOCK)
						ON l.LeagueID = b.LeagueID
			   LEFT JOIN #tmpProduct P
				ON P.Bettype = b.Bettype
				 LEFT JOIN #SiteName si_R (NOLOCK)
						ON si_R.siteid = b.siteid AND b.DataSource =si_R.DataSource
			GROUP BY 
				b.RptDate,
			CASE WHEN b.SiteID = -4 THEN 'Cash' 
				WHEN b.SiteID = -2 THEN 'Credit'
				WHEN si_R.SiteName IN ('CN88','789Y') THEN si_R.SiteName
				WHEN si_R.isDeposit = 1 THEN 'Cash' 
				WHEN si_R.isDeposit = 0 THEN 'Credit'
				ELSE 'Credit'
			END,
			CASE WHEN b.SiteID = -4 THEN 'BEST-ODDS' 
				WHEN b.SiteID = -2 THEN 'XYZBET'
				WHEN si_R.SiteName IS NOT NULL THEN si_R.SiteName
				ELSE 'N/A'
			END,
			CASE WHEN b.Bettype IN (9,29) THEN 'Parlay' 
				WHEN @SportName <> '' THEN @SportName
				WHEN p.ProductName = 'SportsBook' AND sp.SportName ='Soccer' THEN 'Soccer'
				WHEN p.ProductName = 'SportsBook' AND sp.SportName <>'Soccer' THEN 'Other Sports'
				ELSE p.ProductName END

	INSERT INTO #tmpReportSiteProduct
	SELECT 	 
			b.RptDate,
			CASE WHEN b.SiteID = -4 THEN 'Cash' 
				WHEN b.SiteID = -2 THEN 'Credit'
				WHEN si_R.SiteName IN ('CN88','789Y') THEN si_R.SiteName
				WHEN si_R.isDeposit = 1 THEN 'Cash' 
				WHEN si_R.isDeposit = 0 THEN 'Credit'
				ELSE 'Credit'
			END SiteType,
			CASE WHEN b.SiteID = -4 THEN 'BEST-ODDS' 
				WHEN b.SiteID = -2 THEN 'XYZBET'
				WHEN si_R.SiteName IS NOT NULL THEN si_R.SiteName
				ELSE 'N/A'
			END SiteName,
			'Saba-'+SportName ProductName,
			COUNT(DISTINCT b.CustID) ActiveMember,
			COUNT(DISTINCT CASE WHEN p.ProductID IN(1) THEN b.MatchID ELSE NULL END) NoMatch,
			-- [Bet Count]
			SUM(CASE WHEN b.BetType = 500 THEN 0 
					 ELSE BetCount  END) BetCount,
			SUM(b.WinlossP * b.ActualRate) [WinlossMember],
			SUM(b.Stake * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)) [TurnoverMember],
			-- [Commission]
			SUM(-b.CommissionS*b.ActualRate) Commission,
			-- [Company Real Income]
			SUM(-(b.WinlossIBC - b.ExtraWL + b.CommissionS - b.ExtraComm) * b.ActualRate*CASE WHEN b.SiteID NOT IN(-2,-4) THEN 1 ELSE 0 END) HouseIncome,
			-- [Company Real Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) *
				(CASE WHEN b.VarianceVR > 0 THEN (b.VarianceVR + 1) ELSE 1 END) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) HouseTurnOver,
			-- [Company Virtual Income]
			SUM(-((b.WinlossIBC - b.ExtraWL) * (b.VarianceVR + 1)
					+ (b.CommissionS - b.ExtraComm) * (CASE WHEN b.VarianceVR < 0 THEN (b.VarianceVR + 1) ELSE 1 END)
				 ) * b.ActualRate) [HouseVirtualWinloss],
			-- [Company Virtual Turnover]
			SUM(
				(CASE WHEN b.TurnoverIBC=0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTo END) * (b.VarianceVR + 1) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [HouseVirtualTurnover],
			-- [Variance WL]
			SUM((b.WinlossIBC - b.ExtraWL
					+ CASE WHEN b.VarianceVR < 0 THEN (b.CommissionS - b.ExtraComm) ELSE 0 END) * b.VarianceVR * b.ActualRate) [Variance Winloss],--90
			-- [Variance Turnover]
			SUM((CASE WHEN b.TurnoverIBC = 0 THEN 0 ELSE b.TurnoverIBC - b.ExtraTO END) * ABS(b.VarianceVR) * b.ActualRate
				*(CASE WHEN @Adjustment =1 AND b.TicketStatus IN (3,111) THEN 0 WHEN @Adjustment =1 AND p.ProductID = 1 AND  b.TicketStatus IN (12,13,114,115) THEN 0.5 ELSE 1 END)
				) [Variance Turnover]
			FROM
				#FactCustWinloss b with (nolock)
				 LEFT JOIN bodb02.dbo.Sports sp (NOLOCK)
						ON sp.SportType = b.SportType
				 LEFT JOIN bodb02.dbo.League l (NOLOCK)
						ON l.LeagueID = b.LeagueID
			   LEFT JOIN #tmpProduct P
				ON P.Bettype = b.Bettype
				 LEFT JOIN #SiteName si_R (NOLOCK)
						ON si_R.siteid = b.siteid AND b.DataSource =si_R.DataSource
			 WHERE ISNULL(l.LeagueGroupID,-1)IN (42,74)
				AND b.BetType NOT IN(9,29)
			GROUP BY 
				b.RptDate,
			CASE WHEN b.SiteID = -4 THEN 'Cash' 
				WHEN b.SiteID = -2 THEN 'Credit'
				WHEN si_R.SiteName IN ('CN88','789Y') THEN si_R.SiteName
				WHEN si_R.isDeposit = 1 THEN 'Cash' 
				WHEN si_R.isDeposit = 0 THEN 'Credit'
				ELSE 'Credit'
			END,
			CASE WHEN b.SiteID = -4 THEN 'BEST-ODDS' 
				WHEN b.SiteID = -2 THEN 'XYZBET'
				WHEN si_R.SiteName IS NOT NULL THEN si_R.SiteName
				ELSE 'N/A'
			END,
			'Saba-'+SportName

	SELECT 'Site-Product' ReportType
	
	;WITH CTE
	AS	(
		SELECT MAX(rptDate) rptDate_MAX FROM #tmpReportSiteProduct
		)
	SELECT td.SiteType,
			td.SiteName,	
			td.ProductName,		
			td.NoMatch NoMatch,
			td.ActiveMember ActiveMember,
			td.BetCount BetCount,
			td.[TurnoverMember] Mem_TO,
			td.[WinlossMember] Mem_WL,
			CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END Mem_MG,
			td.HouseTurnOver	House_Real_TO,
			td.HouseIncome	House_Real_WL,
			CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END House_Real_MG,
			td.[HouseVirtualTurnover] House_Virtual_TO,
			td.[HouseVirtualWinloss] House_Virtual_WL,
			CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END House_Virtual_MG,
			
			CASE WHEN yd.NoMatch <> 0 THEN ((td.NoMatch - yd.NoMatch)*100.0 /yd.NoMatch)ELSE 0.0 END [PerChange NoMatch],
			ISNULL(td.NoMatch - yd.NoMatch,0) [Diff NoMatch],
			CASE WHEN yd.ActiveMember <> 0 THEN ((td.ActiveMember - yd.ActiveMember)*100.0 /yd.ActiveMember)ELSE 0.0 END [PerChange ActiveMember],
			ISNULL(td.ActiveMember - yd.ActiveMember,0) [Diff ActiveMember],
			CASE WHEN yd.BetCount <> 0 THEN ((td.BetCount - yd.BetCount)*100.0/yd.BetCount) ELSE 0.0 END [PerChange BetCount],
			ISNULL(td.BetCount - yd.BetCount,0) [Diff BetCount],
			
			CASE WHEN yd.TurnoverMember <> 0 THEN ((td.TurnoverMember - yd.TurnoverMember)*100.0/yd.TurnoverMember) ELSE 0 END [PerChange Mem_TO],
			ISNULL(td.TurnoverMember - yd.TurnoverMember,0) [Diff TurnoverMember],
			CASE WHEN yd.WinlossMember <> 0 THEN ((td.WinlossMember - yd.WinlossMember)*100.0/ABS(yd.WinlossMember)) ELSE 0.0 END [PerChange Mem_WL],
			ISNULL(td.WinlossMember - yd.WinlossMember,0) [Diff WinlossMember],
			CASE WHEN CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END <> 0 
					THEN CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END
						- CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END
				 ELSE 0 END [PerChange Mem_MG],
			ISNULL(CASE WHEN CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END <> 0 
					THEN CASE WHEN td.TurnoverMember <> 0 THEN td.[WinlossMember]*100.0 / td.[TurnoverMember] ELSE 0 END
						- CASE WHEN yd.TurnoverMember <> 0 THEN yd.[WinlossMember]*100.0 / yd.[TurnoverMember] ELSE 0 END
				 ELSE 0 END,0)  [Diff Mem_MG],
			
			CASE WHEN yd.HouseTurnOver <> 0 THEN ((td.HouseTurnOver - yd.HouseTurnOver)*100.0/yd.HouseTurnOver) ELSE 0 END [PerChange House_Real_TO],
			ISNULL(td.HouseTurnOver - yd.HouseTurnOver,0) [Diff HouseTurnOver],
			CASE WHEN yd.HouseIncome <> 0 THEN ((td.HouseIncome - yd.HouseIncome)*100.0/ABS(yd.HouseIncome)) ELSE 0 END [PerChange House_Real_WL],
			ISNULL(td.HouseIncome - yd.HouseIncome,0) [Diff HouseIncome],
			CASE WHEN CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END <> 0 
					THEN CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END
						- CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END
				 ELSE 0 END [PerChange House_Real_MG],
			ISNULL(CASE WHEN CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END <> 0 
					THEN CASE WHEN td.HouseTurnOver <> 0 THEN td.HouseIncome*100.0 / td.HouseTurnOver ELSE 0 END
						- CASE WHEN yd.HouseTurnOver <> 0 THEN yd.HouseIncome*100.0 / yd.HouseTurnOver ELSE 0 END
				 ELSE 0 END,0) [Diff House_Real_MG],
			
			CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN ((td.[HouseVirtualTurnover] - yd.[HouseVirtualTurnover])*100.0/yd.[HouseVirtualTurnover]) ELSE 0 END [PerChange House_Virtual_TO],
			ISNULL(td.[HouseVirtualTurnover] - yd.[HouseVirtualTurnover],0) [Diff House_Virtual_TO],
			CASE WHEN yd.[HouseVirtualWinloss] <> 0 THEN ((td.[HouseVirtualWinloss] - yd.[HouseVirtualWinloss])*100.0/ABS(yd.[HouseVirtualWinloss])) ELSE 0 END [PerChange House_Virtual_WL],
			ISNULL(td.[HouseVirtualWinloss] - yd.[HouseVirtualWinloss],0) [Diff House_Virtual_WL],
			CASE WHEN CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END <> 0 
					THEN CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END
						- CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END
				 ELSE 0 END [PerChange House_Virtual_MG],
			ISNULL(CASE WHEN CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END <> 0 
					THEN CASE WHEN td.[HouseVirtualTurnover] <> 0 THEN td.[HouseVirtualWinloss]*100.0 / td.[HouseVirtualTurnover] ELSE 0 END
						- CASE WHEN yd.[HouseVirtualTurnover] <> 0 THEN yd.[HouseVirtualWinloss]*100.0 / yd.[HouseVirtualTurnover] ELSE 0 END
				 ELSE 0 END,0) [Diff House_Virtual_MG],
				  
			CASE WHEN td.ProductName LIKE 'Saba-Soccer' THEN 1
				WHEN td.ProductName LIKE 'Saba-Basketball' THEN 2
				WHEN td.ProductName LIKE 'Saba-Cricket' THEN 3
				WHEN td.ProductName LIKE 'Saba-%' THEN 4
				WHEN td.ProductName LIKE 'Soccer' THEN 11
				WHEN td.ProductName LIKE 'Other Sports' THEN 12
				WHEN td.ProductName LIKE 'Parlay' THEN 13
				ELSE 101
				END ORDERID
	FROM #tmpReportSiteProduct td
		INNER JOIN CTE rptMax ON td.RptDate = rptMax.rptDate_MAX 
		LEFT JOIN #tmpReportSiteProduct yd
		ON  td.SiteType = yd.SiteType
			AND td.SiteName = yd.SiteName
			AND td.ProductName = yd.ProductName
			AND td.RptDate <> yd.RptDate
	ORDER BY td.SiteType ,ORDERID

	PRINT 'End Processing compare by Site'
END 

RETURN
GO 

RETURN
 