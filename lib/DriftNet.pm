package DriftNet;

use LWP::UserAgent;
use Date::Parse;
use MongoDB;
use JSON;
use URI::Find::Schemeless;

=head1 NAME

DriftNet -- A Perl interface to the PhishTank database

=head1 SYNOPSIS

=over

my $net = Driftnet->new(%opts);

# investigate a chunk of HTML, for example in an email.

if ( $net->phishes_found($message)) {

    $phishes = $net->phishes;

    # do stuff with the JSON records.

}

# investigate a specific URL.

if ( $net->is_phish("http://www.this.is/owned")) {

    $phish = $net->phishes;
    
    # do stuff with the JSON records.

}

# sync with the remote database.

$net->sync_db;

=back

=head1 DESCRIPTION

DriftNet stores and queries the PhishTank database as a MongoDB collection of
JSON documents.

=head1 DEPENDENCIES

Depends on mongodb and the following Perl modules:

=over 4

=item MongoDB

=item LWP::UserAgent

=item JSON

=item URI::Find::Schemeless

=item Date::Parse

=back

=cut

our $VERSION = '0.05';

sub new {

    my $class = shift;
    my %opts = @_;
    my $self = {};

    # stow connection info    
    $self->{key} = $opts{key} if $opts{key};
    $self->{host} = $opts{host} || 'localhost';
    $self->{port} = $opts{port} || 27017;

    # Db variables 
    $self->{connection} = MongoDB::Connection->new(host => $self->{host}, port => $self->{port});
    $self->{database} = $self->{connection}->phishes;
    $self->{collection} = $self->{database}->driftnet;
    $self->{phishes} = [];

    # construct url to fetch updates
    $self->{url} = 'http://data.phishtank.com/data/';
    $self->{url} .= $self->{key} . "/" if $self->{key};
    $self->{url} .= "online-valid.json";
    bless ($self, $class);
    return $self;

}

sub phishes_found {

    my $self = shift;
    my $doc = shift;
    $self->{phish_count} = 0;
    my $finder = URI::Find::Schemeless->new(sub { $self->{phish_count}++ if $self->is_phish($_[0]) });
    $finder->find(\$doc);
    return $self->{phish_count};
}

sub is_phish {

    my ($self, $url) = @_;

    # for some reason, the perl API for Mongo only works with regex
    my $cursor = $self->{collection}->find({ "url" => qr/$url?/ });

    if (my $record = $cursor->next) {
        push(@{$self->{phishes}}, $record);
        return 1; 
    }       
}

# phishes returns an array of hashrefs corresponing to the individual JSON record(s)
sub phishes {

    my $self = shift;
    return $self->{phishes};
}

sub sync_db {

    my $self = shift;
    my $ua = LWP::UserAgent->new;
    my $response = $ua->head($self->{url});
    my $last_sync = $self->{database}->run_command({distinct => "driftnet", key => "last_sync"});

    # Has the database been updated since we last synced with the remote Phishtank database?
    if (str2time ($response->{_headers}->{"last-modified"}) > str2time (${$last_sync->{values}}[0])) {
        my $dump = $ua->get($self->{url});
        my $json = JSON->new;

        if ($dump->is_success) {

            my $inflated = $json->decode($dump->decoded_content);
            $self->{collection}->drop;

            foreach my $hr (@{$inflated}) {
                $self->{collection}->insert($hr);
            }
            
            # prepare for next time. 
            $self->{collection}->ensure_index({"url" => "ascending"});
            $self->{collection}->insert({'last_sync' => $response->{_headers}->{'last-modified'}});
        }
    }
}

1;
