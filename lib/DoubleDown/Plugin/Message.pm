package DoubleDown::Plugin::Message;

use Moose;

sub process {

	my ( $self, $payload ) = @_;

	my $core = DoubleDown::Core->instance;
	my $config = $core->_config;

	# No Message defined
	if ( !defined $payload->{message} ) {
		$core->debug( message => 'no message defined in payload sent to Plugin::Message' , color => $core->debug_yellow);
		return;
	}

	# No channel or channelset defined
	if ( !defined $payload->{channel} && !defined $payload->{channelset} ) {
		$core->debug( message => 'no channel(s) defined in payload sent to Plugin::Message' , color => $core->debug_yellow);
		return;
	}

	# Sent a channel or channels
	if ( defined $payload->{channel} ) {

		if ( ref $payload->{channel} ne 'ARRAY' ) {
			$payload->{channel} = [ $payload->{channel} ];
		}

		foreach my $channel ( @{ $payload->{channel} } ) {
			$core->irc->_con->send_msg( undef, PRIVMSG => $channel, $payload->{message} );
		}
	}

	# Sent channelset or channelsets
	if ( defined $payload->{channelset} ) {

		if ( ref $payload->{channelset} ne 'ARRAY' ) {
			$payload->{channelset} = [ $payload->{channelset} ];
		}

		foreach my $channelset ( @{ $payload->{channelset} } ) {

			if ( defined $config->{irc}->{channelset}->{ $channelset } ) {

				foreach my $channel ( @{ $config->{irc}->{channelset}->{ $channelset } } ) {
					$core->irc->_con->send_msg( undef, PRIVMSG => $channel, $payload->{message} );
				}
			}
		}
	}

}


1;
