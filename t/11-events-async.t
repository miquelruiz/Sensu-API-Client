use strict;
use warnings;

use Test::More;
use Test::Exception;

use Sensu::API::Client 'async';

SKIP: {
    skip '$ENV{SENSU_API_URL} not set', 5 unless $ENV{SENSU_API_URL};

    my $api = Sensu::API::Client->new(
        url => $ENV{SENSU_API_URL},
    );

    my $cv = $api->resolve('unexistant-host', 'XXXX');
    throws_ok {
        $cv->recv
    } qr/404/, 'Not found when resolving unexistant event';

#    throws_ok {
#        $api->event('unexistant-host', 'XXXX');
#    } qr/404/, 'Not found when getting unexistant event';
#
#    my $r;
#    lives_ok { $r = $api->events } 'Call to events lives';
#    is(ref $r, 'ARRAY', 'Got an array');
#
#    lives_ok { $r = $api->events('sensu-server'); } 'Call to events lives';
#    is(ref $r, 'ARRAY', 'Got an array');
#
#    TODO: {
#        local $TODO = "Haven't figured out how to test this";
#
#        lives_ok { $r = $api->event('sensu-server', 'XXXX'); } 'Call to event lives';
#        is(ref $r, 'HASH', 'Just one event for client and check query');
#    };
}

done_testing();
