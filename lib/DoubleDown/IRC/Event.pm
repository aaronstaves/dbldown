package DoubleDown::IRC::Event;

use strict;
use warnings;

use Moose;
use Try::Tiny;

# use require in case we wanna use this later
require DoubleDown::IRC::Message;

sub disconnect {

	my ( $self, $con ) = @_;

	my $core = DoubleDown::Core->instance;
	$core->debug( message => "Logged Out", color => $core->debug_green );

}

sub channel_join {
	my ( $self, $con , $nick, $channel, $is_myself ) = @_;

	my $core = DoubleDown::Core->instance;
	my $config = $core->_config;

	if ( $is_myself ) {
		$nick = "I" if $is_myself;
	}
	else {
		$core->debug( message => sprintf ( '%s joined channel %s', $nick, $channel ), color => $core->debug_cyan );

		# See if we're supposed to attempt to op
		my ( $prefix, $host ) = split ( '@', $con->split_nick_mode ( $con->nick_ident ( $nick ) ) );

		if ( defined $config->{irc}{ops} && ( ( $nick ~~ $config->{irc}{ops}{nicks} ) || ( $host ~~ $config->{irc}{ops}{hosts} ) ) ) {
			$core->debug( message => sprintf ( 'attempting to op %s in channel %s', $nick, $channel ), color => $core->debug_green );
			$con->send_msg( mode => "$channel +o", $nick );
		}
	}
}

sub public_msg {
	my ( $self, $con, $channel, $ircmsg, $nick ) = @_;

	my $message = DoubleDown::IRC::Message->new(
		irc_msg => $ircmsg,
		msg_type    => 'public'
	);
	$message->process();

}

sub private_msg {
	my $self = shift;
	my ( $self, $channel, $ircmsg, $nick ) = @_;

	my $message = DoubleDown::IRC::Message->new(
		irc_msg => $ircmsg,
		msg_type    => 'private'
	);
	$message->process();

}


sub registered {

	my ( $self, $con ) = @_;

	my $core = DoubleDown::Core->instance;
	$core->debug( message => "Logged In", color => $core->debug_green );

}

sub error {

	my ( $self, $con, $code, $message, $ircmsg ) = @_;

	my $core = DoubleDown::Core->instance;
	$core->debug( message => sprintf( "Error received [ %s ]: %s", $code, $message ), color => $core->debug_red );

}



1;

