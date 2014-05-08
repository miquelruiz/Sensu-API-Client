package Sensu::API::Client;

use 5.010;
use Moo;
use JSON;

use Data::Dump;

with 'Sensu::API::Client::APICaller';

has url => (
    is       => 'ro',
    required => 1,
);

sub events {
    my ($self, $client, $check) = @_;
    my $path = '/events';
    $path .= "/$client" if $client;
    $path .= "/$check"  if $check;
    return $self->get($path);
}

sub resolve {
    my ($self, $client, $check) = @_;
    die "client and check required" unless ($client and $check);
    return $self->post('/resolve', { client => $client, check => $check });
}

1;

__END__
=pod

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=over 4

=item *
Miquel Ruiz <mruiz@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Miquel Ruiz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
