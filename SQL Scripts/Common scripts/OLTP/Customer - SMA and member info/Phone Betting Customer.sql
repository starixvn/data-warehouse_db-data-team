select top 100 c.custid, c.username2, p.* 
from PhoneBettingCustomerList p (nolock)
	left join customer c (nolock) on c.username= p.username