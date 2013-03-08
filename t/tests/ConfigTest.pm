package ConfigTest;

use strict;
use warnings;
use utf8;

use base 'TestBase';

use Test::More;
use Test::Fatal;

use App::Announcr::Config;

sub load_config : Test {
    my $self = shift;

    my %config =
      App::Announcr::Config->new(file => 't/tests/ConfigTest/config')->load;

    is_deeply(
        \%config,
        {   mailer    => 'Mailer/1.0',
            signature => "Haha\nlala\n\nthere",
            from      => 'me@example.com',
            log       => 'log',
            prefix    => '[Prefix]'
        }
    );
}

sub load_config_with_utf : Test {
    my $self = shift;

    my %config =
      App::Announcr::Config->new(file => 't/tests/ConfigTest/config_with_utf')->load;

    is_deeply(
        \%config,
        {   mailer    => 'Mailer/1.0',
            signature => "привет",
            from      => 'me@example.com',
            log       => 'log',
            prefix    => '[Префикс]'
        }
    );
}

1;
