SELECT *
	FROM pgbench_accounts AS pa
	WHERE pa.aid > 0
	LIMIT 2000;
