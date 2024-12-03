
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Jeremy Han>
-- Create date: <11/02/24>
-- Description:	<procedure will consolidate multiple tables to tabulate noc approvals and who they were approved by in one place, 
--				   also updates license completion table to aggregate how many license were completed by individual techs>
-- =============================================
CREATE PROCEDURE <dbo.sp_ptech_productivity> 

AS
BEGIN

SET NOCOUNT ON;

DROP TABLE dbo.noc_aprvls

SELECT DISTINCT c.apno
				, LEFT(c.apno, 3) as appl_type
				, c.apdttm
				, b.condtype
				, z.FULLNAME as APRVBY
				, a.APRVDTTM
				, DATEPART(hh,a.APRVDTTM) as hour
				, a.APRVED
				, aprv.cal_yr
				, aprv.day_name 
				, aprv.month
				, aprv.month_name
				, CONVERT(date,GETDATE()) as run_date
INTO testdb.dbo.noc_aprvls
FROM testdb.bldg.BLDGCOND a
INNER JOIN testdb.bldg.BLDGCONDTYPE b ON a.APBLDGCONDTYPEKEY = b.APBLDGCONDTYPEKEY AND b.CONDTYPE = 'RecvdNOC'
INNER JOIN testdb.bldg.BLDGAPPL c ON a.APBLDGKEY = c.APBLDGKEY 
LEFT JOIN testdb.resrc.EMPLOYEE X ON upper(a.APRVBY) = upper(x.EMPID)
LEFT JOIN testdb.resrc.CONTACT Y ON X.CONTACTKEY = Y.CNTCTKEY
LEFT JOIN  testdb.resrc.CNTCTID Z ON Y.IDKEY = Z.IDKEY
LEFT JOIN testdb.dbo.calendar_map aprv ON aprv.date = CONVERT(date, a.APRVDTTM)
WHERE YEAR(a.APRVDTTM) >= YEAR(DATEADD(year,-1,GETDATE())) --AND a.APRVED = 'Y'
order by a.APRVED, APRVDTTM desc

DROP TABLE dbo.tl_completions

select tl.LICENSENO
	, SUBSTRING(tl.LICENSENO, 1, PATINDEX('%[0-9]%', tl.LICENSENO + '0') - 1) as license_type
	, CONVERT(date,atch.ADDDTTM) as date
	, DATEPART(hh,atch.ADDDTTM) as hour
	, z.FULLNAME
	, addt.cal_yr
	, addt.day_name
	, addt.month
	, addt.month_name
	, CONVERT(date,GETDATE()) as run_date
INTO testdb.dbo.tl_completions
from testdb.lcnse.TRADELICENSE tl
left join testdb.lcnse.ATTCHMTAP atmp ON atmp.APKEY = tl.APKEY
left join testdb.lcnse.ATTCHMT atch ON atch.ATTCHMTKEY = atmp.ATTCHMTKEY
LEFT JOIN testdb.resrc.EMPLOYEE X ON upper(atch.ADDBY) = upper(x.EMPID)
LEFT JOIN testdb.resrc.CONTACT Y ON X.CONTACTKEY = Y.CNTCTKEY
LEFT JOIN  testdb.resrc.CNTCTID Z ON Y.IDKEY = Z.IDKEY
LEFT JOIN testdb.dbo.calendar_map addt ON addt.date = CONVERT(date,atch.ADDDTTM)
where atch.ATTCHMTID IS NOT NULL AND YEAR(atch.ADDDTTM) >= YEAR(DATEADD(year,-1,GETDATE()))

order by ADDDTTM desc, LICENSENO

END
GO