=pod

=head1 NAME

DoubleDown::IRC::Message

=head1 SYNOPSIS

Basic message object used by DoubleDown

=head1 DESCRIPTION

This module gives us a generic interface to messages received with a
little bit of DoubleDown goodness.  Mostly functions/attributes that are
helpful that aren't paret of the normal AnyEvent::IRC::Client class.

=cut
package DoubleDown::IRC::Message;

use strict;
use warnings;

use Moose;
use DoubleDown::Core;

=head1

Attributes

=head2 channel

The channel the message was posted in. Created from irc_msg

=cut

has channel => (
	is => 'ro',
	isa => 'Maybe[Str]',
	lazy => 1,
	builder => '_build_channel'
);

sub _build_channel {
	my $self = shift;

	# Grab the channel from the irc_msg
	my $channel = $self->irc_msg->{params}->[0];

	# Ignore NOTICE commands from AUTH
	return undef if $channel eq 'AUTH';

	# If it was a private message set the "channel" to the nick
	# that sent the message
	$channel = $self->nick
		if $self->msg_type eq 'private';

	return $channel;

}

=head2 irc_msg

This is passed in from the AnyEvent event handler.  We'll use this
to make up the other attributes used for a message.

=cut

has irc_msg => (
	is => 'ro',
	isa => 'HashRef',
	required => 1
);


=head2 msg_type

The type of message, public or private

=cut

has msg_type => (
	is => 'ro',
	isa => 'Str',
	default => sub { 'public' }
);

=head2 nick

The nick of the person who posted the message. Created from
irc_msg

=cut

has nick => (
	is      => 'ro',
	isa     => 'Maybe[Str]',
	lazy    => 1,
	builder => '_build_nick'
);

sub _build_nick {

	my $self = shift;

	my $con = DoubleDown::Core->instance->irc->_con;

  my @split_nick = $con->split_nick_mode( $self->irc_msg->{prefix} ) ;
  my $nick = $split_nick[1];

	return defined $nick ? $nick : 'UNKNOWN';
}

=head2 ident

The unique identity of the user making the post.  This grabs
the ident based on the nick in the NickMon code.

=cut

has ident => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_ident'
);

sub _build_ident {
	my $self = shift;

	my $core = DoubleDown::Core->instance;
	my $ident = $core->_stash->{nickmon}->{ $self->nick };

	return defined $ident ? $ident : 'UNKNOWN';
}

=head2 parts

All parts of the message, just split up into an array

=cut

has parts => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	lazy => 1,
	builder => '_build_parts'
);

sub _build_parts {
	my $self = shift;

	return [ split ' ', $self->text ];
}

=head2 text

The text the message was posted in. Created from irc_msg

=cut

has text => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_text'
);

sub _build_text {
	my $self = shift;

	# Grab the text from the irc_msg
	my $text = $self->irc_msg->{params}->[1];

	# return undef if it's just an event (i.e. AUTH) since it's
	# not a text
	return $text;

}

sub process {

	my $self = shift;

	return if !defined $self->channel || !defined $self->nick;
	my $core = DoubleDown::Core->instance;
	$core->debug(
		message => sprintf( "routing message '%s' from '%s' [ %s ]", $self->text, $self->nick, $self->ident),
		color   => $core->debug_yellow
	);

	my $command_regex = lc ( sprintf( '^!%s (.+)$', $core->_config->{app_name} ) );
	if ( $self->text =~ m/$command_regex/ ) {
		$self->process_command( $1 );
	}
	else {
		$self->process_text();
	}

}

sub process_command {

	my $self = shift;
	my $command = shift;

	my $core = DoubleDown::Core->instance;

	$core->debug(
		message => sprintf( "routing command '%s' from '%s' [ %s ]", $command, $self->nick, $self->ident),
		color   => $core->debug_magenta
	);

	my $classes = $core->_commands;

	foreach my $class ( keys %{ $classes } ) {

		foreach my $regex ( keys %{ $classes->{ $class } } ) {
			if ( $command =~ m/$regex/ ) {
				my $func = $classes->{ $class }->{ $regex };
				$core->debug(
					message => sprintf( "command matches '%s' routing to %s::%s", $regex, $class, $func ),
					color   => $core->debug_on_magenta
				);

				my $obj = $class->new();
				$obj->$func( $self );
			}
		}
	}
}

sub process_text {

	my $self = shift;
	my $text = $self->text;

	my $core = DoubleDown::Core->instance;

	$core->debug(
		message => sprintf( "routing text '%s' from '%s' [ %s ]", $text, $self->nick, $self->ident),
		color   => $core->debug_magenta
	);

	my $classes = $core->_text_match;

	foreach my $class ( keys %{ $classes } ) {

		foreach my $regex ( keys %{ $classes->{ $class } } ) {
			if ( $text =~ m/$regex/ ) {
				my $func = $classes->{ $class }->{ $regex };
				$core->debug(
					message => sprintf( "text matches '%s' routing to %s::%s", $regex, $class, $func ),
					color   => $core->debug_on_magenta
				);

				my $obj = $class->new();
				$obj->$func( $self );
			}
		}
	}
}

1;
