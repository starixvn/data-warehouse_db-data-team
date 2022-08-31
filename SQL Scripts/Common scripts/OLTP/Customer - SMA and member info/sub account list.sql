select top 100 
	cs. subaccid, c.username Agent, c.site,
	cs.username, cs.UserName2, 
	cs.firstname, cs.lastname, cs.createdate
from custSub cs (nolock) join customer c(nolock)  on c.custid=cs.custid