
--drop table #customerNew
select custid, recommend, site,creatdate
into #customerNew
from bodb02.dbo.Customer c (nolock) 
where roleid=1
and creatdate>='2020/04/01'
--and creatdate<'2020/02/18'



select a.site, count(1) NewMembers
from #customerNew c join bodb02.dbo.customer a (nolock) on a.custid=c.recommend
group by a.site
order by NewMembers desc

select a.username Agent, count(1) NewMembers
from #customerNew c join bodb02.dbo.customer a (nolock) on a.custid=c.recommend
group by a.username
order by NewMembers desc

select cast(c.creatdate as DATE) CreatedDate, count(1) NewMembers
from #customerNew c 
group by cast(c.creatdate as DATE) 
order by CreatedDate 

--select * from customer
--where username='BA03HK'


--select * from DirectCustomer c
--where c.GroupName='BAO3HK'