use strict;
use warnings;

use Test::More;
use Test::Exception;

use Sensu::API::Client;

use Data::Dump;

SKIP: {
    skip '$ENV{SENSU_API_URL} not set', 5 unless $ENV{SENSU_API_URL};

    my $api = Sensu::API::Client->new(
        url => $ENV{SENSU_API_URL},
    );

    throws_ok {
        $api->resolve('unexistant-host', 'XXXX');
    } qr/404/, 'Not found when resolving unexistant event';

    throws_ok {
        $api->events('unexistant-host', 'XXXX');
    } qr/404/, 'Not found when getting unexistant event';

    TODO: {
        local $TODO = "Haven't figured out how to test this";
        my $r = $api->events;
        is(scalar @$r, 2, 'Two events');

        lives_ok { $r = $api->events('sensu-server'); } 'Call to events lives';
        is(scalar @$r, 2, 'Two events for "sensu-server"');

        lives_ok { $r = $api->events('sensu-server', 'XXXX'); } 'Call to events lives';
        is(ref $r, 'HASH', 'Just one event for client and check query');
    };
}

done_testing();
