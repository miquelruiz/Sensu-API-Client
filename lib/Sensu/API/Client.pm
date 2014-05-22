package Sensu::API::Client;
# ABSTRACT: Perl client for the Sensu API

use 5.010;
use Moo;
use JSON;
use Carp;

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

sub info {
    return shift->get('/info');
}

sub get_stash {
    my ($self, $path) = @_;
    return $self->get('/stashes/' . $path);
}

sub get_stashes {
    return shift->get('/stashes');
}

sub create_stash {
    my ($self, @args) = @_;

    my $hash = { @args };
    my %valid_keys = ( path => 1, content => 1 );
    my @not_valid  = grep { not defined $valid_keys{$_} } keys %$hash;

    die 'Unexpected keys: ' . join(',', @not_valid) if (scalar @not_valid);
    die 'Path required'    unless $hash->{path};
    die 'Content required' unless $hash->{content};

    return $self->post('/stashes', {@args});
}

sub delete_stash {
    my ($self, $path) = @_;
    return $self->delete('/stashes/' . $path);
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
