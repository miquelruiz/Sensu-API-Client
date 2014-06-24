use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN { use_ok 'Sensu::API::Client' }

my $api;

dies_ok { Sensu::API::Client->new() } 'Dies if no URL given';
lives_ok {
    $api = Sensu::API::Client->new(url => $ENV{SENSU_API_URL});
} 'Object correctly built';

done_testing();
