--dangerous setting
select c.custid, c.username, danger Original, danger2 ABI, danger3 [Other Sports], c.creatdate, ag.site, e.currency
from custInfo cu (nolock) join Customer c (nolock) on c.custid=cu.custid
left join Customer ag (nolock) on ag.custid = c.recommend
left join Exchange e (nolock) on e.exchangeid = c.currency
where 
 --cu.custid=44269816
 cu.username='S863RSK76551'