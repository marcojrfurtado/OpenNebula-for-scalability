CREATE OR REPLACE FUNCTION get_seq_page_scan()
  RETURNS real AS
$BODY$
    my $rc = qx( sudo /sbin/hdparm -t /dev/vda );

    my $throughput;
    if ( $rc =~  m/([0-9]*\.[0-9]+) MB\/sec/  ) {
	$throughput = $1
    } else {
	$throughput = 50.0
    }
    my $throughput_KBms= $throughput*1.024;
    my $page_cost = 8/$throughput_KBms;

    return $page_cost;
END;
$BODY$
  LANGUAGE plperlu VOLATILE
  COST 100;
ALTER FUNCTION get_seq_page_scan()
  OWNER TO calibrate;
