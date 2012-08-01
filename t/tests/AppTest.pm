package AppTest;

use strict;
use warnings;

use base 'TestBase';

use Test::More;
use Test::Fatal;
use Test::MockObject::Extends;

use App::Announcr;

sub app : Test(2) {
    my $self = shift;

    my $messages = [];
    my $app      = $self->_build_app(
        $messages,
        from => 'foo@bar.com',
        log  => '/tmp/app-announcr.log'
    );

    $app->run('t/tests/AppTest/emails.csv', 't/tests/AppTest/message.txt');

    my $message = $messages->[0];

    is($message->get('Subject'), '=?UTF-8?B?0J/RgNC40LLQtdGC?=');
    is($message->data, "Всем!\n");
}

sub _build_app {
    my $self = shift;
    my ($messages, %params) = @_;

    my $app = App::Announcr->new(%params);
    $app = Test::MockObject::Extends->new($app);

    $app->mock(_send_message => sub { push @$messages, $_[1] });

    return $app;
}

1;
