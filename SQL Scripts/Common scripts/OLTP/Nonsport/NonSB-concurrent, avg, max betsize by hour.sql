/*
	Creator: Harris
	Param:
			@winlostdate: from a specific date
			@product: table to input request product
	Output: 
			ConcurrentUser, average betcount, avg MemberTO, Avg HouseWL, avg memberWL, avg houseWL, max betsize per hour
*/

Declare @winlostdate date
Declare @product table (productID int, productname varchar(50), sporttype int, reftable int)

select @winlostdate = '20200415' -- winlostdate here
INSERT @product
Select distinct p.productID, productname,sporttype, reftable from products p with (nolock)
join SportBettypeMatrix pt with (Nolock) on pt.ProductID = p.ProductID
where productname in ('Macau games','RNG keno', 'allbet') -- input product list here

select * from @product

IF OBJECT_ID('tempdb..#tmp') is not null DROP TABLE #tmp
CREATE TABLE #TMP (productid int, [day] int, [hour] int
					, concurrentUser int, ticketcount INT,maxBet money
					, MemberTO money, HouseTO money
					, memberWL money, houseWL money
			)

-- BettransLC -- Allbet
IF EXISTS (select 1 from @product where reftable = 2)
INSERT #TMP
select bt.productID, datepart(day,transdate) d,datepart(hour,transdate) [h]
		, count(distinct custid) concurrent, count(1) ticketcount, max(stake * actualrate)
		, sum(stake * actualrate) MemberTO
		, Sum(stake * (1-tpositiontaking - Epositiontaking) * actualrate ) HouseTO
		, sum((winlost-actual_stake) * actualrate)
		,  -sum (((winlost-actual_stake)*(1-tpositiontaking-epositiontaking)+ (Scomm - Scomm / (1-tpositiontaking) * epositiontaking))*actualrate) houseWL
from BettransLC  b with (Nolock)
join @product bt on b.productID = bt.sporttype
where  currency <>20 and statusID not in(0,1) and transdate >= winlostdate and statusid in (111,112,113) and winlostdate >= @winlostdate
group by datepart(hour,transdate), datepart(day,transdate), bt.productID--,datepart(minute,transdate)
UNION
select bt.productID, datepart(day,transdate) d,datepart(hour,transdate) [h]
		, count(distinct custid) concurrent, count(1) ticketcount, max(stake * actualrate)
		, sum(stake * actualrate) MemberTO
		, Sum(stake * (1-tpositiontaking - Epositiontaking) * actualrate ) HouseTO
		, sum((winlost-actual_stake) * actualrate)
		,  -sum (((winlost-actual_stake)*(1-tpositiontaking-epositiontaking)+ (Scomm - Scomm / (1-tpositiontaking) * epositiontaking))*actualrate) houseWL
from BettransLC14  b with (Nolock)
join @product bt on b.productID = bt.sporttype
where currency <>20 and statusID not in(0,1) and transdate >= winlostdate and statusid in (111,112,113) and winlostdate >= @winlostdate
group by datepart(hour,transdate), datepart(day,transdate), bt.productID--,datepart(minute,transdate)
UNION
select bt.productID, datepart(day,transdate) d,datepart(hour,transdate) [h]
		, count(distinct custid) concurrent, count(1) ticketcount, max(stake * actualrate)
		, sum(stake * actualrate) MemberTO
		, Sum(stake * (1-tpositiontaking - Epositiontaking) * actualrate ) HouseTO
		, sum((winlost-actual_stake) * actualrate)
		,  -sum (((winlost-actual_stake)*(1-tpositiontaking-epositiontaking)+ (Scomm - Scomm / (1-tpositiontaking) * epositiontaking))*actualrate) houseWL
from bodb_archive.dbo.BettransLC_bk  b with (Nolock)
join @product bt on b.productID = bt.sporttype
where currency <>20 and statusID not in(0,1) and transdate >= winlostdate and statusid in (111,112,113) and winlostdate >= @winlostdate
group by datepart(hour,transdate), datepart(day,transdate), bt.productID--,datepart(minute,transdate)


-- BettransRNG tables
IF EXISTS (select 1 from @product where reftable = 1)
INSERT #TMP
select bt.productID, datepart(day,transdate) d,datepart(hour,transdate) [h]
		, count(distinct custid) concurrent, count(1) ticketcount, max(stake * actualrate)
		, sum(stake * actualrate) MemberTO
		, Sum(stake * (1-tpositiontaking - Epositiontaking) * actualrate ) HouseTO
		, sum((winlost-actual_stake) * actualrate)
		,  -sum (((winlost-actual_stake)*(1-tpositiontaking-epositiontaking)+ (Scomm - Scomm / (1-tpositiontaking) * epositiontaking))*actualrate) houseWL
from bettransRNG  b with (Nolock)
join @product bt on b.productID = bt.sporttype
where  currency <>20 and statusID not in(0,1) and transdate >= winlostdate and statusid in (111,112,113) and winlostdate >= @winlostdate
group by datepart(hour,transdate), datepart(day,transdate), bt.productID--,datepart(minute,transdate)
UNION
select bt.productID, datepart(day,transdate) d,datepart(hour,transdate) [h]
		, count(distinct custid) concurrent, count(1) ticketcount, max(stake * actualrate)
		, sum(stake * actualrate) MemberTO
		, Sum(stake * (1-tpositiontaking - Epositiontaking) * actualrate ) HouseTO
		, sum((winlost-actual_stake) * actualrate)
		,  -sum (((winlost-actual_stake)*(1-tpositiontaking-epositiontaking)+ (Scomm - Scomm / (1-tpositiontaking) * epositiontaking))*actualrate) houseWL
from bettransRNG14  b with (Nolock)
join @product bt on b.productID = bt.sporttype
where currency <>20 and statusID not in(0,1) and transdate >= winlostdate and statusid in (111,112,113) and winlostdate >= @winlostdate
group by datepart(hour,transdate), datepart(day,transdate), bt.productID--,datepart(minute,transdate)
UNION
select bt.productID, datepart(day,transdate) d,datepart(hour,transdate) [h]
		, count(distinct custid) concurrent, count(1) ticketcount, max(stake * actualrate)
		, sum(stake * actualrate) MemberTO
		, Sum(stake * (1-tpositiontaking - Epositiontaking) * actualrate ) HouseTO
		, sum((winlost-actual_stake) * actualrate)
		,  -sum (((winlost-actual_stake)*(1-tpositiontaking-epositiontaking)+ (Scomm - Scomm / (1-tpositiontaking) * epositiontaking))*actualrate) houseWL
from bodb_archive.dbo.bettransRNG_bk  b with (Nolock)
join @product bt on b.productID = bt.sporttype
where currency <>20 and statusID not in(0,1) and transdate >= winlostdate and statusid in (111,112,113) and winlostdate >= @winlostdate
group by datepart(hour,transdate), datepart(day,transdate), bt.productID--,datepart(minute,transdate)

-- translog
IF EXISTS (select 1 from @product where reftable = 3)
INSERT #TMP
select bt.productID, datepart(day,transdate) d,datepart(hour,transdate) [h]
		, count(distinct custid) concurrent, count(1) ticketcount, max(stake * actualrate)
		, sum(stake * actualrate) MemberTO
		, Sum(stake * (1-tpositiontaking - Epositiontaking) * actualrate ) HouseTO
		, sum((winlost-actual_stake) * actualrate)
		,  -sum (((winlost-actual_stake)*(1-tpositiontaking-epositiontaking)+ (Scomm - Scomm / (1-tpositiontaking) * epositiontaking))*actualrate) houseWL
from Bettrans  b with (Nolock)
join @product bt on b.matchid = bt.sporttype
where  currency <>20 and statusID not in(0,1) and transdate >= winlostdate and statusid in (111,112,113) and winlostdate >= @winlostdate
group by datepart(hour,transdate), datepart(day,transdate), bt.productID--,datepart(minute,transdate)
UNION
select bt.productID, datepart(day,transdate) d,datepart(hour,transdate) [h]
		, count(distinct custid) concurrent, count(1) ticketcount, max(stake * actualrate)
		, sum(stake * actualrate) MemberTO
		, Sum(stake * (1-tpositiontaking - Epositiontaking) * actualrate ) HouseTO
		, sum((winlost-actual_stake) * actualrate)
		,  -sum (((winlost-actual_stake)*(1-tpositiontaking-epositiontaking)+ (Scomm - Scomm / (1-tpositiontaking) * epositiontaking))*actualrate) houseWL
from Bettrans14  b with (Nolock)
join @product bt on b.matchid = bt.sporttype
where currency <>20 and statusID not in(0,1) and transdate >= winlostdate and statusid in (111,112,113) and winlostdate >= @winlostdate
group by datepart(hour,transdate), datepart(day,transdate), bt.productID--,datepart(minute,transdate)
UNION
select bt.productID, datepart(day,transdate) d,datepart(hour,transdate) [h]
		, count(distinct custid) concurrent, count(1) ticketcount, max(stake * actualrate)
		, sum(stake * actualrate) MemberTO
		, Sum(stake * (1-tpositiontaking - Epositiontaking) * actualrate ) HouseTO
		, sum((winlost-actual_stake) * actualrate)
		,  -sum (((winlost-actual_stake)*(1-tpositiontaking-epositiontaking)+ (Scomm - Scomm / (1-tpositiontaking) * epositiontaking))*actualrate) houseWL
from bodb_archive.dbo.Bettrans_bk  b with (Nolock)
join @product bt on b.matchid = bt.sporttype
where currency <>20 and statusID not in(0,1) and transdate >= winlostdate and statusid in (111,112,113) and winlostdate >= @winlostdate
group by datepart(hour,transdate), datepart(day,transdate), bt.productID--,datepart(minute,transdate)


--select top 100 * from #tmp
select ProductName,concurrentUser, avg(ticketcount) avgBet, AVG(memberTO) AvgMemberTO, AVG(houseTO) AvgHouseTO, max(maxbet) Maxbet
from #tmp t
join @product p on p.ProductID = t.ProductID
group by ProductName,concurrentUser

--select top 100 * from bettransRNG  b with (Nolock)
--join (select distinct productid,bettype from SportBettypeMatrix with (Nolock) where productid in (6,34)) bt on b.gameID = bt.BetType
