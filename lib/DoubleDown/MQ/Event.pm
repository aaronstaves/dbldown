package DoubleDown::MQ::Event;

use strict;
use warnings;

use Try::Tiny;
use Moose;
use JSON::XS;

sub connect_success {

	my ( $self, $con ) = @_;

	my $core = DoubleDown::Core->instance;
	my $config = $core->_config->{mq};
	$core->debug( message => sprintf ( "Connected to MQ %s:%i", $config->{host}, $config->{port} ) , color => $core->debug_green );

	$con->open_channel(
		on_success => sub { $self->open_channel_success( @_ ) }
	);
}

sub open_channel_success {

	my ( $self, $channel ) = @_;

	my $core = DoubleDown::Core->instance;
	my $config = $core->_config->{mq};
	my $channels = $channel->{connection}->channels;

	$core->debug( message => sprintf ( "Connected to MQ on channel(s) %s", join(', ', keys %{ $channel->{connection}->channels } ) ) , color => $core->debug_green );

	foreach my $queue ( keys %{ $config->{queues} } ) {
		$core->debug( message => "Attempting to declare queue $queue" );
		$channel->declare_queue(
			queue => $queue,
			durable => 1,
			auto_delete => 0,
			no_ack => 0,
			on_success => sub { $self->declare_queue_success( @_, $channel ) }
		);
	}

}


sub declare_queue_success {

	my ( $self, $frame, $channel ) = @_;

	my $core = DoubleDown::Core->instance;
	my $config = $core->_config->{mq};


	$core->debug( message => sprintf ( "Declared queue %s on channel %s", $frame->method_frame->queue, $frame->channel ) , color => $core->debug_green );

	# see if there's a topic defined
	my $topic = 'DoubleDown.'.$config->{queues}->{ $frame->method_frame->queue }->{topic};

	# attempt to bind queue on topic
	if ( defined $topic ) {
		$core->debug( message => sprintf ( "Bound queue %s on channel %s with topic %s", $frame->method_frame->queue, $frame->channel, $topic ) , color => $core->debug_green );
		$channel->bind_queue(
			queue => $frame->method_frame->queue,
			exchange => 'DoubleDown',
			routing_key => $topic
		);
	}

	# consume queue
	$channel->consume(
		queue      => $frame->method_frame->queue,
		on_success => sub { $self->consume_queue_success( @_, $frame ) },
		on_consume => sub { $self->consume_msg ( @_ ) }
	);

}

sub consume_queue_success {

	my ( $self, $frame, $queue_frame ) = @_;

	my $core = DoubleDown::Core->instance;
	my $config = $core->_config->{mq};

	$core->debug( message => sprintf ( "Consuming queue %s with tag %s", $queue_frame->method_frame->queue, $frame->method_frame->consumer_tag ) , color => $core->debug_green );

}

sub consume_msg {

	my ( $self, $mq_msg ) = @_;

	my $core = DoubleDown::Core->instance;
	my $config = $core->_config;

	my $body = $mq_msg->{body};
	my $deliver = $mq_msg->{deliver};
	my $header = $mq_msg->{header};

	$core->debug( message => sprintf ( "Received message '%s'", $body->{payload} ) , color => $core->debug_cyan );

	my $key = $deliver->method_frame->routing_key;
	$key =~ s/\./::/g;
	$key =~ m/^DoubleDown::(.+)$/;

	if ( !defined $1 ) {
		$core->debug( message => 'No plugin specified, skipping message', color => $core->debug_yellow );
		return;
	}



	my $class = "DoubleDown::Plugin::$1";
	if ( eval "require $class" ) {
		my $plugin = $class->new();
		$plugin->process( decode_json $body->payload );
	}
	else {
		$core->debug( message => sprintf ( 'Error loading plugin %s. Skipping message', "DoubleDown::Plugin::$1" ) , color => $core->debug_yellow );
		return;
	}

#	my $broadcast = lc $1;
#
#	my $message = decode_json $body->payload;
#
#
#	if ( $broadcast eq 'all' ) {
#		foreach my $channel ( @{ $config->{irc}{channels} } ) {
#			$core->irc->_con->send_msg( undef, PRIVMSG => $channel, $message->{message} );
#		}
#	}
#	else {
#		$core->irc->_con->send_msg( undef, PRIVMSG => "#$broadcast", $message->{message} );
#	}
}




1;

