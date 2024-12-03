--NUM CASES OVER NUM INSPECTIONS + DAYS TO FIRST INSP
SELECT cal.cal_yr 
		, cal.month
		, cal.month_name
		, h.APDESC AS case_type
		--, mp.CENTLAT as lat
		--, mp.CENTLON as long
		, COUNT(CaseInfo.APNO) as num_cases
		, SUM(IIF(CaseInsp.first_inspection_date IS NULL, 0,1)) as num_inspected
		, SUM(DATEDIFF(Day,CONVERT(date,CaseInfo.ADDDTTM), IIF(CONVERT(date,CaseInfo.ADDDTTM) > CaseInsp.first_inspection_date, CaseInfo.ADDDTTM, CaseInsp.first_inspection_date ) ))*1.0 / COUNT(CaseInfo.APCASEKEY)  as days_to_insp
		, COUNT(CaseHear.CASEKEY) as case_hearing_count
FROM testdb.code_enf.CaseInfo CaseInfo
INNER JOIN testdb.dbo.calendar_map cal ON CONVERT(date, CaseInfo.ADDDTTM) = cal.date
INNER JOIN testdb.dbo.addrkey_coord_map mp ON mp.addrkey = CaseInfo.ADDRKEY
LEFT JOIN (SELECT CaseInsp.APCASEKEY, MIN(CaseInsp.COMPDTTM) AS first_inspection_date
			FROM testdb.code_enf.CASEINSP CaseInsp
			where CaseInsp.COMPDTTM < GETDATE()
			GROUP BY CaseInsp.APCASEKEY) CaseInsp ON CaseInsp.APCASEKEY = CaseInfo.APCASEKEY
LEFT JOIN (SELECT DISTINCT CaseHear.CASEKEY
			FROM testdb.code_enf.[CASEHEARING] CaseHear
			WHERE CaseHear.NAME = 'Code Enforcement Board Hearing'
				AND CaseHear.RESULT <> 'ICBH') CaseHear ON CaseHear.CASEKEY = CaseInfo.APCASEKEY
left join testdb.code_enf.CASETYPE h on CaseInfo.APCASEDEFNKEY = h.APCASEDEFNKEY
WHERE cal.fiscal_yr > 2019 AND h.APDESC <> 'Business Tax Receipt'
GROUP BY cal.cal_yr 
		, cal.month
		, cal.month_name
		, h.APDESC
		--, mp.CENTLAT
		--, mp.CENTLON
ORDER BY cal.cal_yr, cal.month

--CASE SOURCE
with srcfix as 
(select 
a.apno,
case when
CHARINDEX('Type Of',b.comments) =1
then SUBSTRING(b.comments,9,16) 
else 'UNK' end as src_fix
from  testdb.code_enf.CASEINFO a
INNER JOIN testdb.code_enf.CASELOG b ON a.APCASEKEY = b.APCASEKEY
where b.logtype = 'ActionReq' 
and a.casedttm >= '01/01/2020'
and a.CASEDTTM < '06/30/2024')

SELECT  IIF(CaseInfo.SRC <> '', CaseInfo.SRC,
		case 
			when sf.src_fix like '%staff%' then 'Staff'
			when sf.src_fix like '%citizen%' then 'Citizen'
			when sf.src_fix like '%refer%' then 'Referral'
			when sf.src_fix like '%anon%' then 'Anonymous'
		else '' end) AS src
		, COUNT(CaseInfo.APNO) as num_cases
FROM testdb.code_enf.CASEINFO CaseInfo
INNER JOIN testdb.dbo.calendar_map cal ON CONVERT(date, CaseInfo.ADDDTTM) = cal.date
LEFT JOIN srcfix sf ON sf.APNO = CaseInfo.APNO
WHERE cal.fiscal_yr > 2023
GROUP BY IIF(CaseInfo.SRC <> '', CaseInfo.SRC,
		case 
			when sf.src_fix like '%staff%' then 'Staff'
			when sf.src_fix like '%citizen%' then 'Citizen'
			when sf.src_fix like '%refer%' then 'Referral'
			when sf.src_fix like '%anon%' then 'Anonymous'
		else null end)

--NUM CASES OVER NUM INSPECTIONS + DAYS TO FIRST INSP
SELECT cal.cal_yr 
		, cal.month
		, cal.month_name
		, h.APDESC as case_type
		, CASE WHEN CHARINDEX('.', f.CODESECTION) > 0
			   THEN SUBSTRING(f.CODESECTION, 1, CHARINDEX('.', f.CODESECTION) - 1)
			   ELSE ISNULL(f.CODESECTION, 'OTHER')
		  END AS code_viol_grp
		, COUNT(CaseInfo.APNO) as num_cases
		, SUM(IIF(CaseInsp.first_inspection_date IS NULL, 0,1)) as num_inspected
		, SUM(DATEDIFF(Day,CaseInfo.ADDDTTM, CaseInsp.first_inspection_date))*1.0 / COUNT(CaseInfo.APCASEKEY)  as days_to_insp
		, COUNT(CaseHear.CASEKEY) as case_hearing_count
FROM testdb.code_enf.CaseInfo CaseInfo
INNER JOIN testdb.dbo.calendar_map cal ON CONVERT(date, CaseInfo.ADDDTTM) = cal.date
LEFT JOIN (SELECT CaseInsp.APCASEKEY, MIN(CaseInsp.COMPDTTM) AS first_inspection_date
			FROM testdb.code_enf.CASEINSP CaseInsp
			where CaseInsp.COMPDTTM < GETDATE()
			GROUP BY CaseInsp.APCASEKEY) CaseInsp ON CaseInsp.APCASEKEY = CaseInfo.APCASEKEY
LEFT JOIN (SELECT DISTINCT CaseHear.CASEKEY
			FROM testdb.code_enf.[CASEHEARING] CaseHear
			WHERE CaseHear.NAME = 'Code Enforcement Board Hearing'
				AND CaseHear.RESULT <> 'ICBH') CaseHear ON CaseHear.CASEKEY = CaseInfo.APCASEKEY
left join (select distinct CASEKEY, FAILEDCODE FROM testdb.code_enf.CASEFAILED) e on e.CASEKEY = CaseInfo.APCASEKEY
left join testdb.code_enf.CASECODEVIOL f on e.FAILEDCODE = f.CODE
left join testdb.code_enf.CASETYPE h on CaseInfo.APCASEDEFNKEY = h.APCASEDEFNKEY
WHERE cal.fiscal_yr > 2019 AND h.APDESC <> 'Business Tax Receipt'
GROUP BY cal.cal_yr 
		, cal.month
		, cal.month_name
		, h.APDESC
		, CASE WHEN CHARINDEX('.', f.CODESECTION) > 0
			   THEN SUBSTRING(f.CODESECTION, 1, CHARINDEX('.', f.CODESECTION) - 1)
			   ELSE ISNULL(f.CODESECTION, 'OTHER')
		  END 
ORDER BY cal.cal_yr, cal.month



--code enforcement cases by month/year/case_type/code_section
SELECT  cal.cal_yr 
		, cal.month
		, cal.month_name
		, h.APDESC as case_type
		, CASE WHEN CHARINDEX('.', f.CODESECTION) > 0
			   THEN SUBSTRING(f.CODESECTION, 1, CHARINDEX('.', f.CODESECTION) - 1)
			   ELSE ISNULL(f.CODESECTION, 'OTHER')
		  END AS code_viol_grp
		, COUNT(distinct CaseInfo.APNO) as num_cases
from testdb.code_enf.CASEINFO CaseInfo
INNER JOIN testdb.dbo.calendar_map cal ON CONVERT(date, CaseInfo.ADDDTTM) = cal.date
left join (select distinct CASEKEY, FAILEDCODE FROM testdb.code_enf.CASEFAILED) e on e.CASEKEY = CaseInfo.APCASEKEY
left join testdb.code_enf.CASECODEVIOL f on e.FAILEDCODE = f.CODE
left join testdb.code_enf.CASETYPE h on CaseInfo.APCASEDEFNKEY = h.APCASEDEFNKEY
WHERE cal.fiscal_yr * 100 + cal.fiscal_month > 202000 AND h.APDESC <> 'Business Tax Receipt'
GROUP BY cal.cal_yr 
		, cal.month
		, cal.month_name
		, h.APDESC
		, CASE WHEN CHARINDEX('.', f.CODESECTION) > 0
			   THEN SUBSTRING(f.CODESECTION, 1, CHARINDEX('.', f.CODESECTION) - 1)
			   ELSE ISNULL(f.CODESECTION, 'OTHER')
		  END
ORDER BY cal_yr, cal.month, cal.month_name, case_type, code_viol_grp


--code enforcement cases by case_type/failure category
SELECT  
		  h.APDESC as case_type
		, e.FAILEDCODE
		, COUNT(distinct CaseInfo.APNO) as num_cases
from testdb.code_enf.CASEINFO CaseInfo
INNER JOIN testdb.dbo.calendar_map cal ON CONVERT(date, CaseInfo.ADDDTTM) = cal.date
left join (select distinct CASEKEY, FAILEDCODE FROM testdb.code_enf.CASEFAILED) e on e.CASEKEY = CaseInfo.APCASEKEY
left join testdb.code_enf.CASECODEVIOL f on e.FAILEDCODE = f.CODE
left join testdb.code_enf.CASETYPE h on CaseInfo.APCASEDEFNKEY = h.APCASEDEFNKEY
WHERE cal.fiscal_yr = 2024 AND h.APDESC <> 'Business Tax Receipt'
GROUP BY 
		 h.APDESC
		, e.FAILEDCODE
ORDER BY  num_cases desc, case_type, e.FAILEDCODE

