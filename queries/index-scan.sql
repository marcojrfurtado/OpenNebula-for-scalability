SELECT max(pa.abalance)
	FROM pgbench_accounts AS pa
	WHERE pa.aid > 100;
