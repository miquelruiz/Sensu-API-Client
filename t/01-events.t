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

    my $r = $api->events;
    is(scalar @$r, 2, 'Two events');

    $r = $api->events('sensu-server');
    is(scalar @$r, 2, 'Two events for "sensu-server"');

    $r = $api->events('sensu-server', 'XXXX');
    is(ref $r, 'HASH', 'Just one event for client and check query');

    lives_ok {
        $api->resolve('sensu-server', 'XXXX');
    } 'Call to resolve des not die';

    throws_ok {
        $api->events('sensu-server', 'XXXX');
    } qr/404/, 'Not found after resolve';
}

done_testing();
