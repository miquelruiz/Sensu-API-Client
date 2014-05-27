package Sensu::API::Client::APICaller;

use 5.010;
use Moo::Role;

use Carp;
use JSON;
use HTTP::Tiny;

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

sub get {
    my ($self, $url) = @_;
    my $r = $self->ua->get($self->url . $url, { headers => $self->headers });
    croak "$r->{status} $r->{reason}" unless $r->{success};

    return decode_json($r->{content});
}

sub post {
    my ($self, $url, $body) = @_;
    my $post = { headers => $self->headers };
    if (defined $body) {
        $post->{content} = encode_json($body);
    } else {
        $post->{headers}->{'Content-Length'} = '0';
    }

    my $r = $self->ua->post($self->url . $url, $post);
    croak "$r->{status} $r->{reason}" unless $r->{success};

    return decode_json($r->{content});
}

sub delete {
    my ($self, $url) = @_;
    my $r = $self->ua->delete($self->url . $url, { headers => $self->headers });
    croak "$r->{status} $r->{reason}" unless $r->{success};
    return;
}

1;
