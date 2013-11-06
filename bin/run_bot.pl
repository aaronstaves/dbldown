#!/usr/bin/env perl

use strict;
use warnings;

use DoubleDown;
use Getopt::Long::Descriptive;


my @opts = (
  [ "config_file|c=s" => 'Config to use' ],
  [ "help|h"     => 'Usage' ]
);

my ( $opts, $usage ) = describe_options( "usage: %c %o", @opts );

if ( $opts->{help} ) {
    print $usage;
    exit;
}


# Instantiate and run the bot
my $dbldown = DoubleDown->new({ config_file => $opts->{config_file} });
$dbldown->run();
