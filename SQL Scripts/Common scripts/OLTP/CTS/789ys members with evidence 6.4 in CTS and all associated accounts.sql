/*
	20201002@Long.Luu: Get "All 789y's members with evidence 6.4 in CTS and all associated accounts"
*/

DROP TEMPORARY TABLE IF EXISTS tmpAccountList;
CREATE TEMPORARY TABLE tmpAccountList (
		CTSCustID		BIGINT UNSIGNED PRIMARY KEY
);
    
DROP TABLE IF EXISTS tmpAffectedDevices;
CREATE TEMPORARY TABLE tmpAffectedDevices(
		CTSCustID		BIGINT UNSIGNED     
	,	DCSDeviceID		BIGINT UNSIGNED
	, 	PRIMARY KEY	tmpAffectedDevices(CTSCustID,DCSDeviceID) 
);

DROP TABLE IF EXISTS tmpAssociationException;
CREATE TEMPORARY TABLE tmpAssociationException(
		FromCTSCustID 	BIGINT UNSIGNED
	,	ToCTSCustID 	BIGINT UNSIGNED
	, 	PRIMARY KEY	tmpAssociationException(FromCTSCustID,ToCTSCustID)
);
    
# START
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
INSERT INTO tmpAccountList(CTSCustID)
SELECT DISTINCT CTSCustID
FROM CTS_DataCenter.CustEvidence AS e
WHERE e.EvidenceID = 56
and e.level = 0 ; #hedging

SET SQL_SAFE_UPDATES = 0;
DELETE t
FROM tmpAccountList AS t
	INNER JOIN CTS_DataCenter.CTSCustomer AS c ON c.CTSCustID = t.CTSCustID
WHERE c.SiteID <> 3;

INSERT INTO tmpAffectedDevices(CTSCustID, DCSDeviceID)
SELECT DISTINCT t.CTSCustID, a.DCSDeviceID
FROM CTS_DataCenter.AssociationByDevice AS a    
	INNER JOIN tmpAccountList AS t ON a.CTSCustID = t.CTSCustID;
    
INSERT INTO tmpAssociationException(FromCTSCustID, ToCTSCustID)
SELECT DISTINCT t.CTSCustID
	,	CASE WHEN e.LeastCTSCustID_Order = t.CTSCustID THEN e.GreatestCTSCustID_Order ELSE e.LeastCTSCustID_Order END
FROM CTS_DataCenter.CustException AS e
	INNER JOIN tmpAccountList AS t ON e.LeastCTSCustID_Order = t.CTSCustID
												OR e.GreatestCTSCustID_Order = t.CTSCustID;

SELECT DISTINCT c.CustID
FROM tmpAccountList AS t
	INNER JOIN tmpAffectedDevices AS d ON t.CTSCustID = d.CTSCustID
	INNER JOIN CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
	LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON a.CTSCustID = c.CTSCustID AND c.CustSubID = 0
	LEFT JOIN tmpAssociationException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
WHERE (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL)
	AND c.CustID IS NOT NULL
	AND c.RoleID = 1;

SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ; 

DROP TEMPORARY TABLE IF EXISTS tmpAccountList;   
DROP TEMPORARY TABLE IF EXISTS tmpAffectedDevices;   
DROP TEMPORARY TABLE IF EXISTS tmpAssociationException;   