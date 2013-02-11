#!/usr/bin/perl -w 

use strict;
use DriftNet;

# replace 'xxxx' with your personal key
my $net = DriftNet->new( key => "xxxx" );

$net->sync_db;
