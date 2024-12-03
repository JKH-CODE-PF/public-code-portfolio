IF OBJECT_ID('tempdb..#parcels') IS NOT NULL DROP TABLE #parcels
select Parcel_OCPA, DORDesc, MAX(p.TOTAL_MKT) as market_value, MAX(p.TOTAL_ASSD) as assessed_value, MAX(p.TOTAL_XMPT) as exempt_value, MAX(p.TAXABLE) as taxable_value, MAX(TAXES) as taxes
into #parcels
from testdb.gis.GIS_ParcelsOCPA p
GROUP BY Parcel_OCPA, DORDesc;

With getprcl as (
       select distinct
			  a.ADDRKEY,
              max(c.prclid) as prclid
       from testdb.bldg.BLDGAPPL a
       LEFT JOIN testdb.prop.[ADDRPRCL] b ON b.ADDRKEY = a.ADDRKEY
       LEFT JOIN testdb.prop.PARCEL c on b.PRCLKEY = c.PRCLKEY
       group by a.ADDRKEY
       )

SELECT  
		  e.FAILEDCODE
		, e.COMMENTS_SEARCH
		, COUNT(distinct CaseInfo.APNO) as num_cases
from testdb.code_enf.CASEINFO CaseInfo
INNER JOIN testdb.dbo.calendar_map cal ON CONVERT(date, CaseInfo.ADDDTTM) = cal.date
LEFT JOIN getprcl gp ON gp.ADDRKEY = CaseInfo.ADDRKEY
LEFT JOIN testdb.prop.[ADDRPRCL] b ON b.ADDRKEY = CaseInfo.ADDRKEY
LEFT JOIN testdb.prop.PARCEL c on b.PRCLKEY = c.PRCLKEY
LEFT JOIN #parcels p on p.Parcel_OCPA = c.PRCLID
left join (select distinct CASEKEY, FAILEDCODE, COMMENTS_SEARCH FROM testdb.code_enf.CASEFAILED) e on e.CASEKEY = CaseInfo.APCASEKEY
left join testdb.code_enf.CASECODEVIOL f on e.FAILEDCODE = f.CODE
left join testdb.code_enf.CASETYPE h on CaseInfo.APCASEDEFNKEY = h.APCASEDEFNKEY
WHERE cal.fiscal_yr = 2024 AND h.APDESC <> 'Business Tax Receipt' AND (DORDesc LIKE '%Family%' OR DORDesc LIKE '%Residential%' )AND FAILEDCODE IS NOT NULL 
GROUP BY 
		  e.FAILEDCODE
		, e.COMMENTS_SEARCH
ORDER BY  num_cases desc, e.FAILEDCODE