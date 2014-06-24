use strict;
use warnings;

use Test::More;
use Sensu::API::Client 'async';

SKIP: {
    skip '$ENV{SENSU_API_URL} not set', 5 unless $ENV{SENSU_API_URL};

    my $api = Sensu::API::Client->new(
        url => $ENV{SENSU_API_URL},
    );

    my $cv = AnyEvent->condvar;
    $api->info($cv);
    my $r = $cv->recv;
    ok($r->{sensu},    'Got info about Sensu');
    ok($r->{rabbitmq}, 'Got info about RabbitMQ');
    ok($r->{redis},    'Got info about Redis');
}

done_testing();
