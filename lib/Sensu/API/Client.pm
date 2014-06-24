package Sensu::API::Client;
# ABSTRACT: Perl client for the Sensu API

use 5.010;

use URI;
use JSON;
use Carp;
use Try::Tiny;

use Moo;
use namespace::clean;

with 'Sensu::API::Client::APICaller';

has url => (
    is       => 'ro',
    required => 1,
);

has _auth => (
    is      => 'rw',
);

sub BUILD {
    my ($self) = @_;
    $self->_auth(URI->new($self->url)->userinfo);
}

sub events {
    my ($self, $client, %args) = @_;
    my $path = '/events';
    $path .= "/$client" if $client;
    return $self->_request('get', $path, %args);
}

sub event {
    my ($self, $client, $check, %args) = @_;
    croak 'Client and check required' unless ($client and $check);
    return $self->_request(
        'get',
        sprintf('/events/%s/%s', $client, $check),
        %args,
    );
}

sub resolve {
    my ($self, $client, $check, %args) = @_;
    croak "Client and check required" unless ($client and $check);
    return $self->_request(
        'post',
        '/resolve',
        body => { client => $client, check => $check },
        %args,
    );
}

sub info {
    return shift->_request('get', '/info', @_);
}

sub stash {
    my ($self, $path, %args) = @_;
    croak 'Path required' unless $path;
    return $self->_request('get', '/stashes/' . $path, %args);
}

sub stashes {
    return shift->_request('get', '/stashes', @_);
}

sub create_stash {
    my ($self, %args) = @_;

    my %valid_keys = ( path => 1, content => 1, expire => 1 );

    die 'Path required'    unless $args{path};
    die 'Content required' unless $args{content};

    my %body = map { $_ => delete $args{$_} } qw/ path content expire /;
    return $self->_request('post', '/stashes', body => \%body, %args);
}

sub delete_stash {
    my ($self, $path, %args) = @_;
    croak 'Path required' unless defined $path;
    return $self->_request('delete', '/stashes/' . $path, %args);
}

sub health {
    my ($self, %args) = @_;
    my ($c, $m, $r) = (delete $args{consumers}, delete $args{messages}, undef);
    croak "Consumers and Messages required" unless ($c and $m);
    try {
        $r = $self->_request(
            'get',
            sprintf('/health?consumers=%d&messages=%d', $c, $m),
            %args,
        );
    } catch {
        if ($_ =~ qw/503/) {
            $r = 0;
        } else {
            croak $_;
        }
    };
    return $r;
}

sub client {
    my ($self, $name, %args) = @_;
    croak 'Client name required' unless defined $name;
    return $self->_request('get', sprintf('/clients/%s', $name), %args);
}

sub clients {
    return shift->_request('get', '/clients', @_);
}

sub delete_client {
    my ($self, $name, %args) = @_;
    croak 'Client name required' unless defined $name;
    return $self->_request('delete', sprintf('/clients/%s', $name), %args);
}

sub client_history {
    my ($self, $name, %args) = @_;
    croak 'Client name required' unless defined $name;
    return $self->_request(
        'get',
        sprintf('/clients/%s/history', $name),
        %args,
    );
}

sub checks {
    return shift->_request('get', '/checks', @_);
}

sub check {
    my ($self, $name, %args) = @_;
    croak 'Check name required' unless defined $name;
    return $self->_request('get', sprintf('/checks/%s', $name), %args);
}

sub request {
    my ($self, $name, $subs, %args) = @_;
    croak 'Name and subscribers required'
        unless (defined $name and defined $subs);
    croak 'Subscribers must be an arrayref' unless (ref $subs eq 'ARRAY');
    return $self->_request(
        'post',
        '/request',
        body => { check => $name, subscribers => $subs },
        %args,
    );
}

1;

__END__
=pod

=head1 NAME

Sensu::API::Client - API client for the Sensu monitoring framework

=head1 SYNOPSIS

    use Try::Tiny;
    use Sensu::API::Client;

    my $api = Sensu::API::Client->new(url => 'http://user:pass@host:port');

    # Retrieve current events
    my $events = $api->events;
    foreach my $e (@$events) {
        printf("%s, %s, %d\n", $e->{client}, $e->{check}, $e->{status});

        # Resolve them
        $api->resolve($e->{client}, $e->{check});
    }

    # Retrieve envents for a single client
    my $client_events = $api->events('my-client');

    # Get a list of clients
    my $clients = $api->clients;
    foreach my $c (@$clients) {
        printf("%s, %s\n", $c->{name}, $c->{address});
    }

    # Get a single client
    my $client;
    try {
        # Some methods throw an exception if the object is not found
        $client = $api->client('my-client');
    } catch {
        if ($_ =~ /404/) {
            warn 'my-client not found';
        } else {
            warn "Something bad happened: $_";
        }
    };

    # Get check result history for a client
    my $hist = $api->client_history('my-client');

    # Delete it
    try {
        $api->delete_client('my-client');
    } catch {
        if ($_ =~ /404/) {
            warn 'my-client not found';
        } else {
            warn "Something bad happened: $_";
        }
    };

=head1 DESCRIPTION

Set of modules to access the REST API provided by the Sensu monitoring
framework. Currently supports the version 0.12 of the Sensu API.

All methods throw exceptions in case of errors. Not passing a required
parameter is considered to be an error.

=head1 METHODS

=head2 new

Returns an instance of Sensu::API::Client.

=head3 Required Arguments

=over 4

=item url

It is the URL where the API resides. It accepts user and password for basic
authentication. Example: http://admin:secret@localhost:4567

=back

=head2 events($client)

Returns an arrayref containing events. Each event is a hashref with the
following keys: client, check, occurrences, output, status and flapping.

The client name is an optional arbument to filter the result by Sensu client.

=head2 event($client, $check)

Returns a single event.

Both arguments are required.

Throws an exception "404" if the event does not exist.

=head2 resolve($client, $check)

Resolves an event identified by client and check.

Both arguments are required.

Throws an exception "404" if the event does not exist.

=head2 info

Returns a hashref containing info about the API service.

Docs about the returned data: L<http://sensuapp.org/docs/0.12/api-info>

=head2 stashes

Returns an arrayref containing all the stashes. Each stash is a hash containing
the following keys: path (string), content (hashref), expire (integer).

=head2 stash($path)

Returns a single stash as a hashref.

Throws an exception "404" if the stash does not exist.

=head2 create_stash(%args)

Creates a stash.

=head3 Arguments

=over 4

=item path

Required. String. The path identifying this stash.

=item content

Required. Hashref. Set of key values stored in the stash.

=item expire

Optional. Integer. Time in seconds before the stash expires and is deleted.

=back

=head2 delete_stash($path)

Deletes a stash.

Argument required.

=head2 health(%args)

Returns a boolean. Checks the health of the API to see if it can connect to
Redis and RabbitMQ.

Takes parameters for minimum consumers and maximum messages and checks
RabbitMQ.

=head3 Arguments

=over 4

=item consumers

Required. Integer. Minimum number of consumers to consider the service healthy.

=item messages

Required. Integer. Maximum number of messages in queue to consider the service
healthy.

=back

=head2 client($name)

Returns a single client as a hashref. Each one contains the following keys:
name (string), address (string), subscriptions (arrayref), timestamp (integer).

Name is required.

Throws an exception "404" if the client is not found.

=head2 clients

Returns an arrayref with a list of clients.

=head2 delete_client($name)

Deletes a client, resolving all its events. It returns inmediately, but the
actual deletion is delayed.

Name is required.

Throws an exception "404" if the client is not found.

=head2 client_history($name)

Returns an arrayref with the historic results for each check of a client. Each
element in the list contains the following keys: check (string), last_status
(integer), last_execution (integer), history (arrayref with status codes).

Name is required.

=head2 check($name)

Returns a check as a hashref containing: name (string), command (string),
subscribers (arrayref), interval (integer).

Name is required

Throws an exception "404" if the check does not exist.

=head2 checks

Returns the list of checks.

=head2 request($name, @subscribers)

Issues a check request.

The name of the check, and an arrayref of subscribers are required.

=head1 SEE ALSO

=over 4

=item *

L<http://sensuapp.org/docs/0.12/api>

=back

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
