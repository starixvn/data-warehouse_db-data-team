select 
	winlostdate, 
	gameid, 
	case when Stake <100 then '1-100' 
		when Stake >=100  and Stake < 200 then '100-200' 
		when Stake >=200  and Stake < 500 then '200-500' 
		when Stake >=500  and Stake < 1000 then '500-1k' 
		when Stake >=1000 then '1k+' 
	end BetSize,
	COUNT(1) betcount,
	sum(Stake*actualrate) Stake_RM,
	sum(Stake) Stake
into #data
from bettransRnG14 b (nolock)
	JOIN dbo.Customer ag WITH(NOLOCK) ON ag.custid = b.recommend 
where gameid in (
	select bettype 
	from SportBettypeMatrix
	where productid=42)
	and winlostdate>= '2020-11-24 00:00:00'
	and winlostdate<= '2020-11-27 00:00:00'
	AND statusID IN(111, 112, 113)
		   and b.currency <>20
	AND ag.site= '789Y'
 GROUP BY winlostdate ,
	gameid,
		case when Stake <100 then '1-100' 
		when Stake >=100  and Stake < 200 then '100-200' 
		when Stake >=200  and Stake < 500 then '200-500' 
		when Stake >=500  and Stake < 1000 then '500-1k' 
		when Stake >=1000 then '1k+' 
	end
select * from #data

insert into #data
select 
	winlostdate, 
	gameid, 
	case when Stake <100 then '1-100' 
		when Stake >=100  and Stake < 200 then '100-200' 
		when Stake >=200  and Stake < 500 then '200-500' 
		when Stake >=500  and Stake < 1000 then '500-1k' 
		when Stake >=1000 then '1k+' 
	end BetSize,
	COUNT(1) betcount,
	sum(Stake*actualrate) Stake_RM,
	sum(Stake) Stake

from bettransRnG b (nolock)
	JOIN dbo.Customer ag WITH(NOLOCK) ON ag.custid = b.recommend 
where gameid in (
	select bettype 
	from SportBettypeMatrix
	where productid=42)
	and winlostdate>= '2020-11-28 00:00:00'
	and winlostdate<= '2020-11-30 00:00:00'
	AND statusID IN(111, 112, 113)
		   and b.currency <>20
	AND ag.site= '789Y'
 GROUP BY winlostdate ,
	gameid,
		case when Stake <100 then '1-100' 
		when Stake >=100  and Stake < 200 then '100-200' 
		when Stake >=200  and Stake < 500 then '200-500' 
		when Stake >=500  and Stake < 1000 then '500-1k' 
		when Stake >=1000 then '1k+' 
	end

select t.winlostdate , 
	b.typenamee Bettype,
	t.BetSize,
	t.betcount,
	t.Stake,
	t.Stake_RM
from #data t join bettype b on b.typeid=t.gameID
order by winlostdate