package App::Announcr::Config;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    die 'file is required' unless $self->{file};

    return $self;
}

sub load {
    my $self = shift;

    my %config = ();

    my $file = $self->{file};

    my ($key, $value) = ('', '');

    open my $fh, '<', $file or die "Can't open file '$file': $!";
    while (defined(my $line = <$fh>)) {
        chomp $line;

        if ($line =~ s/^\s+//) {
            $value .= "\n" if length $value;
            $value .= $line;
        }
        else {
            $config{$key} = $value if length $key && length $value;
            ($key, $value) = ('', '');

            ($key, $value) = split /\s*=\s*/, $line;
        }
    }

    $config{$key} = $value if length $key && length $value;

    return %config;
}

1;
