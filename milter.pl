#!/usr/bin/perl -w

use Sendmail::PMilter qw(:all);
use DriftNet;
use strict; 

my %my_milter_callbacks = (
    'eoh' => \&my_eoh_callback,
    'body' => \&my_body_callback,
    'eom' => \&my_eom_callback,
    'abort' => \&my_abort_callback,
);

my $milter = new Sendmail::PMilter;
my $socket = '/var/run/driftnet.sock';
$milter->setconn("local:$socket");
$milter->register('driftnet', { %my_milter_callbacks }, SMFI_CURR_ACTS);
$milter->main();

sub my_eoh_callback {
    my $ctx = shift;
    my $body = "";
    $ctx->setpriv(\$body);
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
    my $net = DriftNet->new( key => "xxxx");
    if ($net->phishes_found(${$body_ref})) {
        my $phishes = $net->phishes;
        foreach my $phish (@$phishes) {
            my $warning = '*' x 80 . "\n";
            $warning .= "WARNING! THIS IS EMAIL MAY NOT BE FROM WHO IT CLAIMS TO BE! FOR MORE INFORMATION,\n";
            $warning .= "GO TO " . $phish->{phish_detail_url} . "\n";
            $warning .= '*' x 80 . "\n";
            ${$body_ref} = $warning . ${$body_ref}; 
        }
    }        
    $ctx->replacebody(${$body_ref});
    $ctx->setpriv(undef);
    return SMFIS_ACCEPT;
}

sub my_abort_callback {
    my $ctx = shift;
    $ctx->setpriv(undef);
    return SMFIS_CONTINUE;
}
