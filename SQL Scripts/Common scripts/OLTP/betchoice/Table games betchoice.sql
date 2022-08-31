/*	Created by: Dan
	Task: get data betchoice of a bettype Table games
	DB: DBACC/bodb02	

Revisions:

*/ 
--betchoice lookup table
-- drop table #betchoiceKenoList
 select Kenobetchoice.*, bettypeKeno
  into #betchoiceKenoList
  from 
	  (SELECT 
		--[RefId],
		  [ResourceId] BetchoiceID
		  ,[Resource_en] BetchoiceKeno
		  ,[Sort1] bettypeKenoID
		  --,[Resource_vn]    
	  FROM DBTP.bodb02.dbo.[_RefResource]-- [bodb02].[dbo].[RefResource]
	  where RefId like '%TableGameBetChoice%' 
	  ) Kenobetchoice
  join 
		(  SELECT --RefId ,
		  [ResourceId] bettypeKenoID
		  ,[Resource_en]     bettypeKeno
		  --,[Resource_vn] bettypeName_vn
    
	  FROM  DBTP.bodb02.dbo.[_RefResource]
	  where RefId like '%TableGameBettype%' ) KenoBettype 
  ON Kenobetchoice.bettypeKenoID=KenoBettype.bettypeKenoID

--select * from #betchoiceKenoList
--where bettypeKeno like 'result%'
--select * from bettype where typeid in (4908,4909)


-- get data 
--  drop table #data
select 
	winlostdate, transdesc, comstatus, 
	transid, bettype, custid, 
	stake,winlost,actual_stake
	,actualrate,virtualrate
	,tpositiontaking,epositiontaking
	,awinlost,mwinlost,swinlost,scomm,playercomm

into #data
from bettrans b (nolock)
where bettype IN (4908,4909)
--and matchid=202
AND statusID IN(111, 112, 113)
	   and b.currency <>20

-- select * from #data

--parse transdesc to get betchoiceID
-- drop table #betchoiceKeno
select  winlostdate, 
	substring(transdesc, charindex(',',transdesc)+1, 5) BetchoiceID,  
	custid,
	count(b.transid) as betcount	
	,sum(ABS(b.stake)*actualrate) as memberTO			
	,sum((winlost-actual_stake+playercomm)*actualrate ) memberWL
	,SUM(CASE
                              WHEN tpositiontaking = 1
                              THEN 0
                              ELSE(1 - b.tpositiontaking - ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * ABS(b.stake) * CASE
                                                                                                      WHEN virtualrate > actualrate
                                                                                                      THEN virtualrate
                                                                                                      ELSE actualrate
                                                                                                  END
                          END) AS RealTurnover
	,-SUM((winlost - actual_stake + awinlost + mwinlost + swinlost + scomm - (CASE
                                                                                                  WHEN tpositiontaking = 1
                                                                                                  THEN 0
                                                                                                  ELSE winlost - actual_stake + scomm / (1 - tpositiontaking)
                                                                                             END) * ISNULL(CAST(b.epositiontaking AS DECIMAL(9, 8)), 0)) * actualrate) AS RealIncome
into #betchoiceKeno
from #data b
group by winlostdate, substring(transdesc, charindex(',',transdesc)+1, 5),custid

select winlostdate, 
	data.BetchoiceID, BetchoiceKeno, BettypeKeno as SubBettypeKeno,
	sum(memberTO) memberTO ,
	sum(memberWL) memberWL,
	sum(RealTurnover) RealTurnover,
	sum(RealIncome) RealIncome
from #betchoiceKeno  data
	left join #betchoiceKenoList l on l.BetchoiceID=data.BetchoiceID
group by winlostdate, 
	data.BetchoiceID, BetchoiceKeno, BettypeKeno
order by winlostdate, memberTO desc

--select * from #betchoiceKeno



select BetchoiceID from #betchoiceKeno
group by BetchoiceID
order by BetchoiceID


 