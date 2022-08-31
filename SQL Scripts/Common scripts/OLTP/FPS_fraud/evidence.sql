--run on DBFRAUD

-- get FPS evidences of customers
SELECT top 100
      [EviCode]
	  , cust.CustId
	  , cust.Username
	  , cust.Username2
      ,sub.SubscriberName as Subscriber
      ,custevi.[CreatedDate]
  
  FROM [FPS_MiddleService].[dbo].[CustomerEvidences] (nolock) custevi
  inner join [FPS_MiddleService].[dbo].[Customers] (nolock) cust on custevi.CustId = cust.CustId
  inner join [FPS_ADMIN].[dbo].[Subscribers] (nolock) sub on custevi.SubscriberId = sub.SubscriberID