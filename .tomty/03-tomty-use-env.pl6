=begin tomty
%(
  tag => ( "broken", "flaky" )
)
=end tomty

bash "tomty --env-set dev";
bash "echo {config()<foo>}",%( expect_stdout => 100 );
bash "echo {config()<bar>}",%( expect_stdout => 'baz' );
