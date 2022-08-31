
/*	Created by: Dan
	Task: get data betchoice of a bettype Keno
	DB: DBACC/bodb02	

Revisions:

*/
--betchoice lookup table
 -- drop table #betchoiceList
 select betchoice.*
  into #betchoiceList
  from 
	  (SELECT 
		--[RefId],
		  [ResourceId] BetchoiceID
		  ,[Resource_en] BetchoiceName
	  FROM DBTP.bodb02.dbo.[_RefResource]
	  where refid='SC_BT'
	  ) betchoice
 
 select* from #betchoiceList

--select * from bettype where typeid=3104

-- get data for Keno bettype
--  drop table #data

--select 
--	winlostdate, transdesc,  
--	transid, gameid bettype, custid, 
--	stake,winlost,actual_stake
--	,actualrate,virtualrate
--	,tpositiontaking,epositiontaking
--	,awinlost,mwinlost,swinlost,scomm,playercomm

--into #data
--from bettransLC b (nolock)
--where gameid=3104
--AND statusID IN(111, 112, 113)
--and b.currency <>20


select 
	winlostdate, transdesc,  
	transid, gameid bettype, custid, 
	stake,winlost,actual_stake
	,actualrate,virtualrate
	,tpositiontaking,epositiontaking
	,awinlost,mwinlost,swinlost,scomm,playercomm

into #data
from bodb_archive.dbo.bettransLC_bk b (nolock)
where gameid=3104
AND statusID IN(111, 112, 113)
and b.currency <>20
and winlostdate>='2020/05/26'
and winlostdate<='2020/06/25'

--select transdesc, comstatus  from bettrans (nolock)
--where bettype=1515
--and matchid=202
--group by transdesc, comstatus

   
/*
choice=4013*site=733333*tableCode=71*result=34*results=*winResult=*ForcedCompleted=0*ReasonCode=0
choice=4003*site=733333*tableCode=71*result=34*results=*winResult=*ForcedCompleted=0*ReasonCode=0
choice=4005*site=733333*tableCode=71*result=34*results=*winResult=*ForcedCompleted=0*ReasonCode=0
choice=4026*site=733333*tableCode=71*result=34*results=*winResult=*ForcedCompleted=0*ReasonCode=0
choice=4022*site=733333*tableCode=71*result=34*results=*winResult=*ForcedCompleted=0*ReasonCode=0
choice=4020*site=733333*tableCode=71*result=34*results=*winResult=*ForcedCompleted=0*ReasonCode=0
choice=4016*site=INDO*tableCode=71*result=34*results=*winResult=*ForcedCompleted=0*ReasonCode=0
choice=4010*site=733333*tableCode=71*result=34*results=*winResult=*ForcedCompleted=0*ReasonCode=0
*/

-- parse transdesc to get betchoiceID
-- drop table #betchoiceData

select 
	winlostdate, 
	substring( transdesc, 8, charindex('*',transdesc)-8)  BetchoiceID,  --,  charindex('choice=',transdesc) + 7
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
into #betchoiceData
from #data b
group by winlostdate, substring( transdesc, 8, charindex('*',transdesc)-8) ,custid


--select * from #betchoiceData

--select BetchoiceID from #betchoiceData
--group by BetchoiceID
--order by BetchoiceID

--report
select winlostdate, 
	custid,
	data.BetchoiceID, 
	l.BetchoiceName, 
	--case when BetchoiceName in ('BetchoiceName')
	sum(memberTO) memberTO ,
	sum(memberWL) memberWL,
	sum(RealTurnover) RealTurnover,
	sum(RealIncome) RealIncome,
	sum(betcount) betcount
from #betchoiceData  data
	left join #betchoiceList l on l.BetchoiceID=data.BetchoiceID
group by winlostdate, custid,
	data.BetchoiceID, 
	l.BetchoiceName
order by winlostdate, memberTO desc

 


