--VR 1

select top 100 * 
from Customer (nolock)
where roleid=1
order by custid desc


select * from ProfileVirtualSetting

select * from DBTXN.bodb02.dbo.Sport_Bettype_Reference_VirtualRate --DW:  bodb_staging.dbo.Sport_Bettype_Reference_VirtualRate 
select top 100 * from CustVirtualSetting

--get VR setting
SELECT	top 10  cvs.custid,
		bodb02.dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID) AS VirtualRate --DW: bodb_dwrs.dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID)
	
FROM	bodb02.dbo.CustVirtualSetting		AS cvs WITH(NOLOCK) 	 --DW: bodb_Account.dbo.CustVirtualSetting		
		INNER JOIN	bodb02.dbo.ProfileVirtualSetting	AS pvs WITH(NOLOCK) 
		ON	cvs.seqNo = pvs.seqNo
		
WHERE pvs.isActive = 1
and sporttype = 2
and bettype=1
and islive=1
and custid=44464675


--VR 2
select top 100 * from VRLeagueGroup
select top 100 * from VRBettypeGroup
select top 100 * from DBCUST.CustDB.dbo.VRValueMapping
select top 100 * from DBCUST.CustDB.dbo.VRSettingHierarchy


select top 100 * from DBCUST.CustDB.dbo.VRCustSetting
where custid=0

--get custsetting
--DBCUST.CustDB


EXEC DBCUST.CustDB.dbo.[Acc_CustRealMultiplier_Sel] --Acc_CustVirtualMultiplier_Sel
  @CustID= 185849
, @SportType=2
, @ErrCode= 0 
, @ErrMsg= '' 

--member site call Dot_Member_CustomerGetVirtualRateBySportBettype

