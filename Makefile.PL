

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DriftNet',
    VERSION_FROM => 'lib/DriftNet.pm', # finds \$VERSION
    AUTHOR       => 'gjskha (gjskha)',
    ABSTRACT     => 'A perl interface to the PhishTank database',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'MongoDB' => 0.44,
                     'JSON' => 0.44,
                     'Date::Parse' => 0.1,
                     'LWP::UserAgent' => 0.1,
                     'URI::Find::Schemeless' => 0.44,
                    },
);
