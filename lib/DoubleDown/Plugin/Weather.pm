=pod

ABSTRACT: Weather functions

=cut
package DoubleDown::Plugin::Weather;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use String::Util 'trim';
use String::IRC;
use LWP::UserAgent;
use JSON::XS;

has commands => (
  is => 'ro',
  isa => 'HashRef',
  builder => '_build_commands'
);

sub _build_commands {
  return {
    '^weather \d{5}$'=> {
			func => 'conditions',
			match_desc => 'weather <zip_code>',
			desc => 'Gives current weather information'
		},
    '^weather forecast \d{5}$'=>  {
			func => 'forecast',
			match_desc => 'weather forecast <zip_code>',
			desc => 'Gives current weather forecast'
		}
  };
}


has 'api_key' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_api_key'
);

sub _build_api_key {
	my $core = DoubleDown::Core->instance;
	my $config = DoubleDown::Core->_config;

	return $config->{plugin}->{weather}->{api_key};
}

has 'conditions_url' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_conditions_url'
);

sub _build_conditions_url {

	my $self = shift;

	return sprintf "http://api.wunderground.com/api/%s/conditions/q/", $self->api_key
}

has 'forecast_url' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_forecast_url'
);

sub _build_forecast_url {

	my $self = shift;

	return sprintf "http://api.wunderground.com/api/%s/forecast/q/", $self->api_key
}

sub process {
	my ( $self, $channel, $args ) = @_;

  if ( $args =~ m/^\d{5}$/ ) {
    $self->conditions( $channel, $args);
  }
  if ( $args =~ m/^forecast (\d{5})$/i ) {
    $self->forecast( $channel, $1 );
  }


}

=head1 Commands

=over 2

=item weather <zip_code>

Displays current weather for a zip code

=cut
sub conditions {

	my ( $self, $message ) = @_;

	my $core = DoubleDown::Core->instance;
	my $config = DoubleDown::Core->_config;
	my $channel = $message->channel;
	my $zip_code = $message->parts->[-1];
	$core->debug( message => "Got weather conditions command for zip code $zip_code", color => $core->debug_green );

	my $api_url = $self->conditions_url . $zip_code . '.json';
	$core->debug( message => sprintf ( "Grabbing info from %s", $api_url ) );

	my $ua = LWP::UserAgent->new();
	my $response = $ua->get( $api_url );
	if ( $response->is_success ) {
		my $data = decode_json $response->decoded_content;
		$core->debug( message => "Successful response", color => $core->debug_green );

		my $o = $data->{current_observation};
		my $message = sprintf ( "Current weather for %s is %s %s°", $o->{display_location}->{full}, $o->{weather}, $o->{temp_f} );
		if ( $o->{temp_f} != $o->{feelslike_f} ) {
			$message .= sprintf " (feels like %s)", $o->{feelslike_f};
		}
		$core->irc->_con->send_msg( undef, PRIVMSG => $channel, String::IRC->new($message)->yellow('black') );

	}
	else {
		$core->debug( message => "Failed response", color => $core->debug_red);
	}

}

=item weather forecast <zip_code>

Displays forcast weather for a zip code

=cut
sub forecast {

	my ( $self, $message ) = @_;

	my $core = DoubleDown::Core->instance;
	my $config = DoubleDown::Core->_config;
	my $channel = $message->channel;
	my $zip_code = $message->parts->[-1];
	$core->debug( message => "Got weather forecast command for zip code $zip_code", color => $core->debug_green );

	$core->debug( message => sprintf ( "Connecting to weather service using api key %s", $self->api_key ) );

	my $api_url = $self->forecast_url . $zip_code . '.json';
	$core->debug( message => sprintf ( "Grabbing info from %s", $api_url ) );

	my $ua = LWP::UserAgent->new();
	my $response = $ua->get( $api_url );
	if ( $response->is_success ) {
		my $data = decode_json $response->decoded_content;
		$core->debug( message => "Successful response", color => $core->debug_green );

		my $days = $data->{forecast}->{txt_forecast}->{forecastday};
		for(0..1) {
			$core->irc->_con->send_msg( undef, PRIVMSG => $channel, String::IRC->new($days->[$_]->{title} . ': ' . $days->[$_]->{fcttext} )->yellow('black') );
		}

	}
	else {
		$core->debug( message => "Failed response", color => $core->debug_red);
	}

}

1;


1;


