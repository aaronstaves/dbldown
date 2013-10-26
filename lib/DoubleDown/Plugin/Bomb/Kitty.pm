=pod

ABSTRACT: Reload functions

=cut
package DoubleDown::Plugin::Bomb::Kitty;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;

has commands => (
  is => 'ro',
  isa => 'HashRef',
  builder => '_build_commands'
);

sub _build_commands {

  return {
    '^kitty bomb$' => 'process',
  }
}

sub process {
	my ( $self, $message ) = @_;

	my $core = DoubleDown::Core->instance;
	my $con  = $core->irc->_con;
	my $channel = $message->channel;

  $core->debug( message => 'COMMENCING KITTY BOMB', color => $core->debug_on_magenta);

	for (0..5) {
		my $width = int ( rand ( 200 ) ) + 300;
		my $height = int ( rand ( 200 ) ) + 300;
		$con->send_msg( undef, PRIVMSG => $channel, sprintf("http://placekitten.com/%i/%i#.png", $width, $height ) );
		sleep(5);
	}

}

1;


