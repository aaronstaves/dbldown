=pod

=head1 NAME

DoubleDown::IRC::AutoResponder

=head1 SYNOPSIS

Base command functions for DoubleDown

=head1 DESCRIPTION

This module handles all top level commands for DoubleDown

=cut
package DoubleDown::Plugin::AutoResponder;

use strict;
use warnings;

use DoubleDown::Core;

use Moose;
use MooseX::NonMoose;

has text_match => (
  is => 'ro',
  isa => 'HashRef',
  builder => '_build_text_match'
);

sub _build_text_match {
  return {
    '(?:(?<=ha)(ha)|(ha)(?=ha))' =>  'lolcon_level',
  };
}


sub lolcon_level {
	my ( $self, $message ) = @_;

	my $core = DoubleDown::Core->instance;
	my $channel = $message->channel;

	my $count = scalar grep defined, ( $message->text =~ /(?:(?<=ha)(ha)|(ha)(?=ha))/g );

	$core->debug( message => 'Got message: ' . $message->text );
	$core->debug( message => 'Got lolcount: ' . $count );
	$core->irc->_con->send_msg( undef, PRIVMSG => $channel, "LOLCON LEVEL $count" ) if $count;

	return;
}

1;
