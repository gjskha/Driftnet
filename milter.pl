#!/usr/bin/perl -w

use Sendmail::PMilter qw(:all);
use MIME::Base64;
use DriftNet;
use strict; 

my %my_milter_callbacks = (
    'header'  => \&my_header_callback,
    'body' => \&my_body_callback,
    'eom' => \&my_eom_callback,
);

my $milter = new Sendmail::PMilter;
my $socket = '/var/run/driftnet.sock';
$milter->setconn("local:$socket");
$milter->register('driftnet', {%my_milter_callbacks}, SMFI_CURR_ACTS);
$milter->main();

sub my_header_callback {
    my($ctx, $field, $value) = @_;
    if (lc $field eq 'content-transfer-encoding') {
	if ($value =~ /base64/oi) {
            $ctx->{encoding} = "base64";
	} elsif ($value =~ /quoted-printable/oi) {
            $ctx->{encoding} = "qp";
        } elsif ($value =~ /7?bit/oi) { 
            $ctx->{encoding} = "7bit";
        } 
    } else {
        $ctx->{encoding} = "default";
    }
    return SMFIS_CONTINUE;
}

sub my_body_callback {
    my $ctx = shift;
    my $body_chunk = shift;
    my $body_ref = $ctx->getpriv();
    ${$body_ref} .= $body_chunk;
    $ctx->setpriv($body_ref);
    return SMFIS_CONTINUE;
}

sub my_eom_callback {
    my $ctx = shift;
    my $body_ref = $ctx->getpriv();

    my $body = ${$body_ref};
    # check encoding
    if ($ctx->{encoding} eq "base64") {
        $body = decode_base64($body);
        print "body is now $body\n";
    } elsif ($ctx->{encoding} eq "qp") {
        # do something
    } elsif ($ctx->{encoding} eq "7bit") {
        # do something 
    }
    
    my $net = DriftNet->new;
    if ($net->phishes_found($body)) {
        my $phishes = $net->phishes;
        $ctx->addheader("X-Driftnet-Status", "phish" ); 
            # convert to multipart message here -- TBD figure out what phish parts really are
            $ctx->addheader("MIME-Version", "1.0" );    
            $ctx->addheader("Content-Type", "multipart/mixed; boundary=\"---- 1234abcd\"" );    
            my $warning .= '*' x 80 . "\n";
            $warning .= "\n"; 
            $warning .= "WARNING! THIS EMAIL MIGHT NOT BE FROM WHO IT CLAIMS TO BE! FOR MORE INFORMATION,\n";

            foreach my $phish (@$phishes) {
                $warning .= "GO TO " . $phish->{phish_detail_url} . "\n";
            }

            $warning .= '*' x 80 . "\n";
            $warning .= "---- 1234abcd\n";
            $warning .= "Content-Type: multipart/mixed; name=\"the phish\"\n";
            $warning .= "Content-Disposition: attachment;\n";
            $warning .= "\n"; 
            $warning .= "\n"; 
            $warning .= $body;
            $ctx->replacebody($body);
    }        
    $ctx->setpriv(undef);
    $ctx->addheader("X-Driftnet-Seen", "true" );    
    return SMFIS_ACCEPT;
}
