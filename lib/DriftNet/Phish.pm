package DriftNet::Phish;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $data = shift;
    my $self = {};

    while ( my ($k, $v) = each(%$data)) {
        $self->{$k} = $v;
    }
    bless ($self, $class);
    return $self;
}

sub phish_id {
    my $self = shift;
    return $self->{phish_id};
}

sub url {
    my $self = shift;
    return $self->{url};
}

sub phish_detail_url {
    my $self = shift;
    return $self->{phish_detail_url};
}

sub submission_time {
    my $self = shift;
    return $self->{submission_time};
}

sub verified {
    my $self = shift;
    return $self->{verified};
}

sub verification_time {
    my $self = shift;
    return $self->{verification_time};
}

sub online {
    my $self = shift;
    return $self->{online};
}

sub target {
    my $self = shift;
    return $self->{target};
}

sub details {
=head
per http://phishtank.com/developer_info.php
'details' => array(
    array(
      'ip_address' => '1.2.3.4',
      'cidr_block' => '1.2.3.0/24',
      'announcing_network' => '1234',
      'rir' => 'arin',
      'detail_time' => '2006-10-01T02:30:54+00:00'                         
    )
)
=cut

    my $self = shift;
    return $self->{details};
}
 
1;
