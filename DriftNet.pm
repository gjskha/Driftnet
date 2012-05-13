package DriftNet;

use LWP::UserAgent;
use Date::Parse;
use MongoDB;
use JSON;
use Data::Dumper;
use HTML::TokeParser::Simple; 

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

# dump known information

$net->db_stats;

=back

=head1 DESCRIPTION

DriftNet stores and queries the PhishTank database as a MongoDB collection of
JSON documents.

=head1 DEPENDENCIES

Depends on the following Perl modules:

=over 4

=item MongoDB

=item LWP::UserAgent

=item JSON

=item HTML::TokeParser::Simple

=item Date::Parse

=back

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    my $self = {};
    $self->{key} = $opts{key} if $opts{key};
    $self->{host} = $opts{host} || 'localhost';
    $self->{port} = $opts{port} || 27017;
    $self->{connection} = MongoDB::Connection->new(host => $self->{host}, port => $self->{port});
    $self->{database} = $self->{connection}->phishes;
    $self->{collection} = $self->{database}->driftnet;
    $self->{phishes} = [];
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
    my $parser = HTML::TokeParser::Simple->new(string => $doc);
    while (my $token = $parser->get_token) {
        if ($token->is_tag('a')) {
            my $href = $token->get_attr('href');
            if ($self->is_phish($href)) {
                $self->{phish_count}++;
            }
        }
    }
    return $self->{phish_count};
}

sub is_phish {
    my ($self, $url) = @_;
    my $cursor = $self->{collection}->find({ "url" => $url });
    if (my $record = $cursor->next) {
        push(@{$self->{phishes}}, $record);
        return 1; 
    }       
}

sub phishes {
    my $self = shift;
    return $self->{phishes};
}

sub sync_db {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    my $response = $ua->head($self->{url});
    # TDB: figure out how to make the more straightforward way work properly.
    my $last_sync = $self->{database}->run_command({distinct => "driftnet", key => "last_sync"});
    if (str2time ($response->{_headers}->{"last-modified"}) > str2time (${$last_sync->{values}}[0])) {
        my $dump = $ua->get($self->{url});
        my $json = JSON->new;
        if $ua-
        $decoded = $json->decode($dump->decoded_content);
        $self->{collection}->drop;
        foreach my $hr (@{$decoded}) {
            $self->{collection}->insert($hr);
        }
        $self->{collection}->ensure_index({"url" => "ascending"});
        $self->{collection}->insert({'last_sync' => $response->{_headers}->{'last-modified'}});
    }
}

sub db_stats {
    my $self = shift;
    #my $ic = $self->{collection}->count;
    foreach my $p (@{$self->{phishes}}) {
        print Dumper $p, "\n";
    }
}

sub submit_phish {
}

1;
