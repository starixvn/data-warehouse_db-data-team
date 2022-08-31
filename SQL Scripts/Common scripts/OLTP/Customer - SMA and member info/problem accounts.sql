SELECT c.custid, ag.site, --l.isAcknowledgement, 
	c.username, 
	SUBSTRING(c.username2,  CHARINDEX('$',c.username2)+1, LEN(c.username2)-CHARINDEX('$',c.username2)) AS username2,
	p.IsAbnormalMember,--CAST(p.ProblemStatus&POWER(2,c.roleid-1) AS BIT)  ProblemStatus,
	pr.ReasonName,
	e.currency, CASE WHEN d.custid IS NULL THEN 0 ELSE 1 END isVip, 
	a.ActionName, p.MaxBet, p.MaxPerEvent as MaxPerMatch, p.CreatedDate as MarkDate, p.comment,
	inform1.username as inform1, inform2.username as inform2 
FROM customer c WITH(NOLOCK)
	INNER JOIN ProblemAccount p WITH(NOLOCK) ON c.custid = p.custid
	LEFT JOIN Dep_CustVip d WITH(NOLOCK) ON c.custid = d.custid
	LEFT JOIN ProblemAccountAction a WITH(NOLOCK) ON p.ActionID = a.ActionID
	INNER JOIN Exchange e WITH(NOLOCK) ON c.currency = e.exchangeid 
	LEFT JOIN custinfo inform1 WITH(NOLOCK) ON p.Informed1By = inform1.custid
	LEFT JOIN custinfo inform2 WITH(NOLOCK) ON p.Informed2By = inform2.custid
	LEFT JOIN customer ag WITH(NOLOCK) ON ag.custid = c.recommend
	LEFT JOIN ProblemAccountReason pr WITH(NOLOCK) ON pr.ReasonID = p.ReasonId
WHERE c.roleid = 1