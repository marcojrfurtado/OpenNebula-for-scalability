CREATE OR REPLACE FUNCTION get_seq_page_scan()
  RETURNS real AS
$BODY$
    my $rc = qx('/usr/bin/get_seq_page_cost');
        return $rc;
END;
$BODY$
LANGUAGE plperlu VOLATILE
COST 100;
