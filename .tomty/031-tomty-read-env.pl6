bash "echo {config()<foo>}",%( expect_stdout => 100 );
bash "echo {config()<bar>}",%( expect_stdout => 'baz' );
