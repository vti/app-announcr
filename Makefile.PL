#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME         => 'App::Announcr',
    VERSION_FROM => 'lib/App/Announcr.pm',
    ABSTRACT     => 'Newsletter sender',
    AUTHOR       => 'Viacheslav Tykhanovskyi <vti@cpan.org>',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (
        $mm < 6.46
        ? ()
        : (
            META_MERGE => {
                requires  => {perl => '5.008007'},
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => 'http://github.com/vti/app-announcr'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),

    PREREQ_PM => {
        'Carp'                      => '0',
        'MIME::Lite'                => '0',
        'Test::More'                => '0',
        'Test::Class'               => '0',
        'Test::Fatal'               => '0',
        'Test::MockObject::Extends' => '0',
        'Text::CSV'                 => '0',
    },
    test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t'}
);
