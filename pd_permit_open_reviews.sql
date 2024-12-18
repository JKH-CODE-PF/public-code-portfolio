With OpenRev AS (
SELECT 
A.APNO
,LEFT(A.APNO,3) AS APPL_TYPE
,A.APNAME
,ISNULL(nm.FULLNAME,'') as FULLNAME
,IIF(LEFT(A.APNO,3) = 'DEM','Demolition',A.WORKTYPE) as WORKTYPE
,A.BLDGAPPLSTATUS
,D.CODE AS APPL_MILESTONE
,B.RELEVANTREVIEW
,CONVERT(date,B.SUSPDT) AS DUEDTTM
,C.DEPT
,C.DESCRIPT
FROM testdb.bldg.BLDGAPPL A
INNER JOIN testdb.bldg.BLDGREVIEW B ON A.APBLDGKEY = B.APBLDGKEY
INNER JOIN testdb.bldg.BLDGREVIEWTYPE C ON B.APBLDGREVIEWTYPEKEY = C.APBLDGREVIEWTYPEKEY
INNER JOIN testdb.bldg.BLDGPROCESSSTATE D ON A.APBLDGDEFNKEY = D.APBLDGDEFNKEY AND A.APBLDGPROCESSSTATEKEY = D.APBLDGPROCESSSTATEKEY
LEFT JOIN (
	SELECT x.EMPID, Z.FULLNAME
	FROM testdb.resrc.EMPLOYEE X --ON upper(A.ADDBY) = upper(X.EMPID)
	INNER JOIN testdb.resrc.CONTACT Y ON X.CONTACTKEY = Y.CNTCTKEY
	INNER JOIN testdb.resrc.CNTCTID Z ON Y.IDKEY = Z.IDKEY
	WHERE z.FULLNAME <> '' AND z.EXPDATE IS NULL
) nm ON nm.EMPID = b.ASSIGNTO
WHERE B.COMPDTTM IS NULL 
			AND B.SUSPDT IS NOT NULL 
			AND B.SUSPDT > DATEADD(YEAR, -5, GETDATE()) 
			AND D.CODE NOT IN ('Expired', 'Withdrawn','Issue COC Complete','Complete') 
			AND b.RELEVANTREVIEW = 'Y'
)

select rev.*
		, CASE WHEN ps.PLANREVTYPECD = 'C' THEN 'COMMERCIAL'
			   WHEN ps.PLANREVTYPECD = 'R1' THEN 'RESIDENTIAL 1/2'
			   WHEN ps.PLANREVTYPECD = 'R3' THEN 'RESIDENTIAL 3 OR MORE'
			   ELSE ps.PLANREVTYPECD END AS review_type
		, ISNULL(COALESCE(i.[Permit Express], p.[Permit Express]),'N') as permit_exp
		, ISNULL(COALESCE(i.[Private Provider], p.[Private Provider]),'N') as private_provider
		, CONVERT(date,GETDATE()) as run_date
FROM OpenRev rev
LEFT JOIN testdb.dbo.RPT_BLD_ISS i ON i.[Permit Number] = rev.APNO
LEFT JOIN testdb.dbo.RPT_BLD_PROC p ON p.[Permit Number] = rev.APNO
LEFT JOIN testdb.dbo.RPT_PERMIT_BASE ps ON ps.apno = rev.APNO
where rev.APNAME NOT LIKE '%TEST%' AND rev.BLDGAPPLSTATUS <> 'Finaled'
order by rev.DUEDTTM asc
