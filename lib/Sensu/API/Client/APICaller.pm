package Sensu::API::Client::APICaller;

use 5.010;
use Moo::Role;

use Carp;
use JSON;
use HTTP::Tiny;

our @CARP_NOT = qw/ Sensu::API::Client /;

has ua => (
    is  => 'ro',
    default => sub { HTTP::Tiny->new },
);

has headers => (
    is => 'ro',
    default => sub { {
        'Accept'        => 'application/json',
        'Content-type'  => 'application/json',
    }; },
);

my %known_methods = (
    get    => 1,
    post   => 1,
    delete => 1,
);

sub _request {
    my ($self, $method, $url, %args) = @_;
    $method = lc $method;
    croak "Not implemented method '$method'" unless $known_methods{$method};

    my $r;
    if ($method eq 'post') {
        my $post = { headers => $self->headers };
        if (defined $args{body}) {
            $post->{content} = encode_json($args{body});
        } else {
            $post->{headers}->{'Content-Length'} = '0';
        }
        $r = $self->ua->post($self->url . $url, $post);
    } else {
        $r = $self->ua->$method(
            $self->url . $url,
            { headers => $self->headers },
        );
    }

    croak "$r->{status} $r->{reason}" unless $r->{success};
    return $r->{content} ? decode_json($r->{content}) : 1;
}

1;
