DriftNet
========

DESCRIPTION
-----------

DriftNet is a Perl library that stores and queries the [PhishTank database](http://www.phishtank.com) as collection of JSON documents in MongoDB. PhishTank is:

> a collaborative clearing house for data and information about phishing on the
> Internet. Also, PhishTank provides an open API for developers and researchers
> to integrate anti-phishing data into their applications at no charge.

SYNOPSIS
--------

    # defaults will be used if these are not provided.
    my $net = Driftnet->new( key => key,
                             port => port,
                             host => host, 
                           );

    # investigate a chunk of text, for example in an email.
    if ( $net->phishes_found($message) ) {
        $phishes = $net->phishes;
        # do stuff with the JSON records in $phishes
    }
    
    # investigate a specific URL.
    if ( $net->is_phish("http://www.this.is/owned") ) {
        $phish = $net->phishes;
        # do stuff with the JSON record in $phish
    }
    
    # sync with the remote PhishTank database.
    $net->sync_db;

DEPENDENCIES
------------

The library depends on the following Perl modules:

  - MongoDB
  - LWP::UserAgent
  - JSON
  - URI::Find::Schemeless
  - Date::Parse

MILTER
------

One obvious application for this data is for the purpose of scanning incoming emails on a mail server, in order to see if any PhishTank entries are found within them.  Towards that end, a common method is to use the milter protocol, which was originally devised for the sendmail program. If you are going to write a milter likewise in Perl, you will also need one of Perl's milter modules installed. See "driftnet_milter.pl" in this directory for an example implementation. Instructions for installation and maintenance of milters are beyond the scope of this document, but [milter.org](http://www.milter.org) is a good starting point. 

INSTALLATION 
-------------

    perl Makefile.PL
    make
    make test
    make install

