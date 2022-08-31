--run on DBDW2
select distinct c.custid, c.username,c.RoleId, c.site, ca.custid AssocCustid, ca.site assocSite, ca.username assocName, ca.RoleId assocRoleid
from [bodb_DT].[dbo].[FPS_Associations] a with (Nolock)
join bodb_Account.dbo.Customer c with (nolock) on c.custid = a.CustId
cross apply  (select  c1.custid, c1.site, username , roleid
						 FROM [bodb_DT].[dbo].[FPS_Associations] a1 with(Nolock)
				join bodb_Account.dbo.customer c1 with (nolocK) on a1.custid = c1.custid 
				where a1.DeviceId = a.DeviceId and c1.custid <> a.custid --and c1.site = 'IBO'
 ) ca
where c.site ='IBO'

