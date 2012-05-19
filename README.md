DriftNet
========

SYNOPSIS
--------

    my $net = Driftnet->new(%opts);

    # investigate a chunk of HTML, for example in an email.
    if ( $net->phishes_found($message)) {
    $phishes = $net->phishes;
    # do stuff with the JSON records in $phishes
    }
    
    # investigate a chunk of HTML, for example in an email.
    if ( $net->phishes_found($message)) {
    $phishes = $net->phishes;
    # do stuff with the JSON records.
    }
    
    # investigate a specific URL.
    if ( $net->is_phish("http://www.this.is/owned")) {
    $phish = $net->phishes;
    # do stuff with the JSON record in $phish
    }
    
    # sync with the remote database.
    $net->sync_db;

DESCRIPTION
-----------

DriftNet stores and queries the PhishTank database as collection of JSON documents in MongoDB.

DEPENDENCIES
------------
Depends on the following Perl modules:

  - MongoDB
  - LWP::UserAgent
  - JSON
  - HTML::TokeParser::Simple
  - Date::Parse
