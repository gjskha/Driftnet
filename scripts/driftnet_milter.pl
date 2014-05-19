#!/usr/bin/perl -w

use Sendmail::PMilter qw(:all);
use MIME::Base64;
use MIME::QuotedPrint;
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

    if (lc $field eq 'subject') {
        $ctx->{subject} = $value;
    }

    # search for some common encodings
    if (lc $field eq 'content-transfer-encoding') {
       
	if (lc $value eq 'base64') {
            $ctx->{encoding} = "base64";
	} elsif (lc $value eq 'quoted-printable') {
            $ctx->{encoding} = "qp";
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

    # deal with some common encodings
    if ($ctx->{encoding} eq "base64") {
        $body = decode_base64($body);
    } elsif ($ctx->{encoding} eq "qp") {
        $body = decode_qp($body);
    } 

    my $net = DriftNet->new;

    if ($net->phishes_found($body)) {

        my $phishes = $net->phishes;
        foreach my $phish (@{$phishes}) {
           $ctx->addheader("X-Driftnet-Status", "Possible phish, please see $phish->{phish_detail_url}" ); 
        }

    }        

    $ctx->addheader("X-Driftnet-Seen", "true" );    
    $ctx->chgheader("Subject", 0, "[Phish] $ctx->{subject}" );    
    $ctx->setpriv(undef);

    return SMFIS_ACCEPT;

}
