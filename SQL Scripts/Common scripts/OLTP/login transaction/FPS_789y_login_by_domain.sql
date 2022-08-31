use FPS_SUB_MAXBET789Y
select url-- , count(1) logincount, count(distinct a.accountID) memberlogin
,url as domain, TransID, a.AccountID
into #tmp
 from Transactions t with (nolock)
join Accounts a with (Nolock) on a.AccountID= t.AccountID
where TransDate >='20200401'
and ActionName = 'login'
and ActionResult like '%successful%'
and username not like '%supertest%'
and username not like'%twnoc%'
and username not like'%twpg%'and username not like'%twqa%' 
and a.AccountID not in (1346698,4559323,5606539,5675827,5660859,4603343)
--and CountryCode = 'TW' 
--group by url

select top 100 * from #tmp
where domain like '%bong88%'

update #tmp
set domain = REPLACE (domain,'/login/index','')
update #tmp
set domain = REPLACE(domain, 'https://','')
update #tmp
set domain = REPLACE(domain, 'http://','')
update #tmp
set domain = REPLACE(domain, '/processlogin.aspx','')
update #tmp
set domain = REPLACE(domain, '/FPSHandler','')

update #tmp
set domain = REPLACE(domain, 'www.','')

update #tmp
set domain = REPLACE(domain, left(domain,4),'')
where domain like 'm__.%'
--update #tmp
--set domain = REPLACE(domain, left(domain,2),'')
--where domain like 'm.%'
update #tmp
set domain = REPLACE(domain, right(domain,4),'')
where domain like '%:___'

select domain, count(1) logincount, count(distinct accountID) MemberCount
from #tmp
group by domain
--drop table #tmp