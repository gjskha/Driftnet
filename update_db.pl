#!/usr/bin/perl -w 

use strict;
use DriftNet;

my $net = DriftNet->new( key => "xxxx" );

$net->sync_db;
