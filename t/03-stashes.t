use strict;
use warnings;

use Test::More;
use Test::Exception;

use Sensu::API::Client;

SKIP: {
    skip '$ENV{SENSU_API_URL} not set', 5 unless $ENV{SENSU_API_URL};

    my $api = Sensu::API::Client->new(
        url => $ENV{SENSU_API_URL},
    );

    my $path = 'xxxx';
    my $cont = { key => 'value' };
    my $r = $api->create_stash(
        path    => $path,
        content => $cont,
    );
    is ($r->{path}, $path, 'Stash created');

    $r = $api->get_stash($path);
    is ($r->{key}, $cont->{key}, 'Correct payload retrieved');

    # Clean before start
    $r = $api->get_stashes;
    is(ref $r, 'ARRAY', 'Got an array ref');
    cmp_ok(@$r, '>=', 1, 'There is at least 1 stash');

    foreach my $s (@$r) {
        $api->delete_stash($s->{path});
    }
    $r = $api->get_stashes;
    is(@$r, 0, 'Stashes deleted');

    throws_ok { $api->create_stash(
        path => $path . $path,
        content => { key => 'value' },
        unexpected => 'shit',
    ) } qr/unexpected/i, 'Unexpected keys dies';

}

done_testing();
