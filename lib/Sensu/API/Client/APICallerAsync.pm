package Sensu::API::Client::APICallerAsync;

use 5.010;
use Moo::Role;

use Carp;
use JSON;
use MIME::Base64;
use AnyEvent::HTTP;

has headers => (
    is => 'ro',
    default => sub { {
        'Accept'        => 'application/json',
        'Content-type'  => 'application/json',
    }; },
);

after BUILD => sub {
    my ($self) = @_;
    $self->headers->{Authorization} = 'Basic '
        . MIME::Base64::encode($self->_auth);
};

sub _request {
    my ($self, $method, $url, %args) = @_;

    my $guard;
    $guard = http_request(
        uc $method => $self->url . $url,
        headers => $self->headers,
        timeout => 60, # Default timeout for HTTP::Tiny
        sub {
            my ($res, $hdr) = @_;
            if ($hdr->{Status} =~ /^2/) {
                $args{cb}->send($res ? decode_json($res) : 1);
            } else {
                $args{cb}->croak("$hdr->{Status} $hdr->{Reason}");
            }

            # Undef the guard here so it doesn't go out of scope untill the
            # provided callbacks are properly dispatched
            undef $guard;
        },
    );
}

1;
