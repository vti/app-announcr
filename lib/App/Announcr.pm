package App::Announcr;

use strict;
use warnings;

our $VERSION = '0.01';

use Text::CSV;
use MIME::Lite;
use Encode;

use App::Announcr::Config;

sub new {
    my $class = shift;
    my (%params) = @_;

    if (my $config = $params{config}) {
        %params =
          (%params, App::Announcr::Config->new(file => $config)->load);
    }

    my $self = {%params};
    bless $self, $class;

    die 'from is required' unless $self->{from};
    die 'log is required'  unless $self->{log};

    if (my $file = $self->{signature_file}) {
        $self->{signature} = $self->_slurp($file);
    }

    $self->{mailer} ||= "App::Announcr/$VERSION";

    return $self;
}

sub run {
    my $self = shift;
    my ($list, $message) = @_;

    $self->_prepare_log;

    my $body = $self->_slurp($message);

    $body =~ s{^Subject: ([^\n]+)\n+}{}ms;
    my $subject = $1;

    my @rows;
    my $csv = Text::CSV->new({binary => 1})
      or die "Cannot use CSV: " . Text::CSV->error_diag();

    open my $fh, '<:encoding(utf8)', $list
      or die "Can't open file '$list': $!";

    $csv->column_names($csv->getline($fh));

    while (my $row = $csv->getline_hr($fh)) {
        next if $self->_is_processed($row->{email});

        my $message = $self->_build_message($row->{email}, $subject, $body);
        $self->_send_message($message);

        $self->_log($row->{email});
    }
    $csv->eof or $csv->error_diag();
    close $fh;

    $self->_finalize_log;
}

sub _is_processed {
    my $self = shift;
    my ($email) = @_;

    return exists $self->{processed}->{$email};
}

sub _build_message {
    my $self = shift;
    my ($to, $subject, $body) = @_;

    if (my $prefix = $self->{prefix}) {
        $subject = $prefix . ' ' . $subject;
    }

    if (my $signature = $self->{signature}) {
        $body .= "\n-- \n" . $signature;
    }

    my $message = MIME::Lite->new(
        From     => $self->{from},
        To       => Encode::encode('MIME-Header', $to),
        Subject  => Encode::encode('MIME-Header', $subject),
        Data     => Encode::encode('UTF-8', $body),
        Encoding => 'base64'
    );

    $message->attr('content-type' => 'text/plain; charset=utf-8');

    $message->delete('X-Mailer');
    $message->add('X-Mailer' => $self->{mailer});

    if (my $description = $self->{description}) {
        $message->delete('List-Id');
        $message->add('List-Id' => $description);
    }

    if (my $unsubscribe = $self->{unsubscribe}) {
        $message->delete('List-Unsubscribe');
        $message->add('List-Unsubscribe' => $unsubscribe);
    }

    return $message;
}

sub _send_message {
    my $self = shift;
    my ($message) = @_;

    $message->send;
}

sub _prepare_log {
    my $self = shift;

    $self->{processed} = {};

    my $is_done = 0;
    if (open my $log_fh, '<', $self->{log}) {
        while (defined(my $line = <$log_fh>)) {
            if ($line =~ m/^SENT (.*?)$/) {
                $self->{processed}->{$1}++;
            }
            elsif ($line =~ m/^DONE/) {
                $is_done = 1;

                $self->{processed} = {};

                last;
            }
        }
    }

    my $mode = $is_done ? '>' : '>>';
    open my $log_fh, $mode, $self->{log}
      or die "Can't open log '$self->{log}': $!";
    $self->{log_fh} = $log_fh;

    return $self;
}

sub _finalize_log {
    my $self = shift;

    my $fh = $self->{log_fh};
    print $fh "DONE\n";
}

sub _log {
    my $self = shift;
    my ($email) = @_;

    my $fh = $self->{log_fh};
    print $fh "SENT $email\n";
}

sub _slurp {
    my $self = shift;
    my ($file) = @_;

    local $/;
    open my $fh, '<', $file or die "Can't open file '$file': $!";

    return <$fh>;
}

1;
