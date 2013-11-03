=pod

ABSTRACT: Help functions

=cut
package DoubleDown::Plugin::Help;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose; use LWP::UserAgent;

has text_match => (
  is => 'ro',
  isa => 'HashRef',
  builder => '_build_text_match'
);


sub _build_text_match {

  return { 
		'^help$' => {
			func => 'show_help',
			match_desc => 'help',
			desc => 'Shows help information'
		},
	};
}

sub show_help {
	my ( $self, $message ) = @_;

	# Only show meme commands in private
	return if $message->msg_type ne 'private';

	my $core = DoubleDown::Core->instance();
	my $config = $core->_config;
	my $con  = $core->irc->_con;
	my $channel = $message->channel;

	my $commands = $core->_commands();
	my $text_matches = $core->_text_match();

	my @rows;
	foreach my $class ( sort { $a cmp $b } keys %{ $commands } ) { 

		foreach my $regex ( sort { $a cmp $b } keys %{ $commands->{ $class } } ) {
			push @rows, [ 'Command', $commands->{ $class }->{ $regex }->{match_desc}, $commands->{ $class }->{ $regex }->{desc} ];
		}
	}

	foreach my $class ( sort { $a cmp $b } keys %{ $text_matches } ) { 

		foreach my $regex ( sort { $a cmp $b } keys %{ $text_matches->{ $class } } ) {
			push @rows, [ 'Text', $text_matches->{ $class }->{ $regex }->{match_desc}, $text_matches->{ $class }->{ $regex }->{desc} ];
		}
	}

	@rows = sort { 
		$a->[0] cmp $b->[0]
		||
		$a->[1] cmp $b->[1]
		||
		$a->[2] cmp $b->[2]
	} @rows;
	unshift @rows, [ 'Type', 'Match', 'Description' ];

	$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( sprintf ( "Commands must be prefixed with '!%s'", $config->{app_name} ) )->yellow('black') );
	my $output = $core->irc->table( \@rows );
	foreach my $line ( @{ $output } ) {
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( $line )->white('black') );
	}



}
1;



