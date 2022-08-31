--suspend close status
select  top 100
	custid, username, 
	case when ISNULL(cps.closed,0) = 0 AND ISNULL(cps.reject,0) = 0  then 'Active'
		when ISNULL(cps.closed,0) = 1 then 'Closed'
		when ISNULL(cps.closed,0) = 0 and ISNULL(cps.reject,0)=1 then 'Suspend'
	end CustStatus,  
	ISNULL(cps.reject,0) AS Suspend,  
	ISNULL (cps.closed,0) As Closed,  
	ci.Enabled
	
from custInfo ci (nolock)
 OUTER APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed  
          , CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject  
          , bitmapHasSynced  
          , bitmapIsDisabled  
          , bitmapIsHidden  
         FROM dbo.CustProductStatus  WITH(NOLOCK)  
         WHERE CustID = ci.custid  
        ) AS cps  
 WHERE --ci.CustID = 5456778744  
	ci.roleid=1