--MYSQL


--get subcriber
set session transaction isolation level read uncommitted;
SELECT distinct SubscriberID FROM CTS_DataCenter.MappingSubscriberSite
where SubscriberType = 0;  -- credit site



--get evidence
set session transaction isolation level read uncommitted;
select cus.CustID, cus.UserName, cus.UserName2, evi.EvidenceCode, evi.EvidenceName 
from CustEvidence ce 
	inner join CTSCustomer cus on cus.CTSCustID = ce.CTSCustID 
    inner join Evidence evi on evi.EvidenceID = ce.EvidenceID
where ce.level = 0 and cus.SubscriberID in (130,2,169,168,4549,2338,2339,4604,4605,4606,4607,4608,4609,4610,4611,4612,4613,4614,4615,4616,4617,4618,4619,4620,4621,13658,13659)