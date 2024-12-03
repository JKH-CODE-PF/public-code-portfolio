With UnderRev as (
	SELECT DISTINCT a.APNO, 
	CONVERT(date,MIN(c.STATUSDTTM)) AS rev_start, 
	CONVERT(date,MAX(d.STATUSDTTM)) as rev_end
	FROM testdb.bldg.[BLDGAPPL] a
	LEFT JOIN testdb.bldg.[BLDGAPPLEXT] b ON b.APBLDGKEY = a.APBLDGKEY
	LEFT JOIN testdb.bldg.[BLDGSTATUSLOG] c ON c.APBLDGKEY = b.APBLDGKEY
	LEFT JOIN testdb.bldg.[BLDGSTATUSLOG] d ON c.APBLDGKEY = d.APBLDGKEY
	LEFT JOIN testdb.bldg.[BLDGPROCESSSTATE] e ON e.APBLDGPROCESSSTATEKEY = c.APBLDGPROCESSSTATEKEY
	LEFT JOIN testdb.bldg.[BLDGPROCESSSTATE] f ON f.APBLDGPROCESSSTATEKEY = d.APBLDGPROCESSSTATEKEY 
	WHERE e.CODE = 'Under Review' AND f.CODE = 'Contractor License' AND a.ISSDTTM IS NOT NULL and d.STATUSDTTM < a.ISSDTTM
	GROUP BY a.APNO
	UNION
	SELECT DISTINCT a.APNO, 
	CONVERT(date,MIN(c.STATUSDTTM)) AS rev_start, 
	CONVERT(date,MIN(d.STATUSDTTM)) as rev_end
	FROM testdb.bldg.[BLDGAPPL] a
	LEFT JOIN testdb.bldg.[BLDGAPPLEXT] b ON b.APBLDGKEY = a.APBLDGKEY
	LEFT JOIN testdb.bldg.[BLDGSTATUSLOG] c ON c.APBLDGKEY = b.APBLDGKEY
	LEFT JOIN testdb.bldg.[BLDGSTATUSLOG] d ON c.APBLDGKEY = d.APBLDGKEY
	LEFT JOIN testdb.bldg.[BLDGPROCESSSTATE] e ON e.APBLDGPROCESSSTATEKEY = c.APBLDGPROCESSSTATEKEY
	LEFT JOIN testdb.bldg.[BLDGPROCESSSTATE] f ON f.APBLDGPROCESSSTATEKEY = d.APBLDGPROCESSSTATEKEY 
	WHERE e.CODE = 'Under Review' AND f.CODE = 'Contractor License' AND a.ISSDTTM IS NOT NULL
	GROUP BY a.APNO, a.ISSDTTM
	HAVING MIN(d.STATUSDTTM) >= a.ISSDTTM
)

select base.apno, base.apname, base.appl_milestone, CONVERT(date, base.apdttm) as appl_date , base.issdttmfmt,
	(DATEDIFF(DAY, ur.rev_start, ur.rev_end) + 1) -- total days including start and end
    - (DATEDIFF(WEEK, ur.rev_start, ur.rev_end) * 2) -- subtract weekends
    -- handle partial weeks at the start or end of the range
    - CASE WHEN DATEPART(WEEKDAY, ur.rev_start) = 7 THEN 1 ELSE 0 END -- subtract for Saturday start
    - CASE WHEN DATEPART(WEEKDAY, ur.rev_end) = 7 THEN 1 ELSE 0 END -- subtract for Saturday end
    - CASE WHEN DATEPART(WEEKDAY, ur.rev_end) = 1 THEN 1 ELSE 0 END AS wrk_days_under_rev,
	(DATEDIFF(DAY, CONVERT(date, base.apdttm), base.issdttmfmt) + 1) -- total days including start and end
    - (DATEDIFF(WEEK, CONVERT(date, base.apdttm), base.issdttmfmt) * 2) -- subtract weekends
    -- Handle partial weeks at the start or end of the range
    - CASE WHEN DATEPART(WEEKDAY, CONVERT(date, base.apdttm)) = 7 THEN 1 ELSE 0 END -- subtract for Saturday start
    - CASE WHEN DATEPART(WEEKDAY, base.issdttmfmt) = 7 THEN 1 ELSE 0 END -- subtract for Saturday end
    - CASE WHEN DATEPART(WEEKDAY, base.issdttmfmt) = 1 THEN 1 ELSE 0 END AS wrk_days_to_iss
FROM testdb.dbo.RPT_PERMIT_BASE base
LEFT JOIN testdb.prop.[ADDRESS] a ON a.addrkey = base.addrkey
LEFT JOIN testdb.prop.[ADDRPRCL] b ON b.ADDRKEY = a.ADDRKEY
LEFT JOIN testdb.prop.PARCEL c on b.PRCLKEY = c.PRCLKEY
LEFT JOIN testdb.bldg.[BLDGAPPL] d ON d.APNO = base.apno
LEFT JOIN testdb.bldg.[BLDGAPPLEXT] e ON e.APBLDGKEY = d.APBLDGKEY
LEFT JOIN UnderRev ur ON ur.APNO = base.apno
where c.prclid IN ('292317546500010','292317546500030','292317546500040','292317546500020') 
		AND base.issdttmfmt IS NOT NULL AND LEFT(base.apname,4) = 'PEXP' --AND base.bldgapplstatus = 'Open'
		AND e.PLANSUBMITTAL <> 'No Plans Required' --AND base.appl_type = 'BLD'
order by base.issdttmfmt desc