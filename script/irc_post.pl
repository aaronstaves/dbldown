#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long::Descriptive;
use String::Util 'trim';
use DoubleDown::Core;


my @opts = (
  [ "dir|d=s" => 'Base directory of project to add git hook to' ],
  [ "message|m=s" => 'Message to send' ],
  [ "channel|c=s" => 'Channel to send it to' ],
  [ "channelset|s=s" => 'Channelset to send it to' ],
  [ "help|h"  => 'Usage' ]
);

my ( $opts, $usage ) = describe_options( "usage: %c %o", @opts );

# User wants help
if ( $opts->{help} ) {
    print $usage;
    exit;
}

# No message defined
if ( !defined $opts->{message} ) {
	die ( "message required" );
}

# No channel or channelset defined
if ( !defined $opts->{channel} && !defined $opts->{channelset} ) {
	die ( "channel or channelset required" );
}

my $publish_obj = { message => $opts->{message} };
if ( defined $opts->{channel} ) {
	$publish_obj->{channel} = $opts->{channel};  # '#blackjack'
}
if ( defined $opts->{channelset} ) {
	$publish_obj->{channelset} = $opts->{channelset}; # 'blackjack'
}
my $core = DoubleDown::Core->instance;
$core->mq->publish( $publish_obj, 'DoubleDown.Message' );
