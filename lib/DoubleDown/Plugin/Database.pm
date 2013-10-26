=pod

ABSTRACT: Database functions

=cut
package DoubleDown::Plugin::Database;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;

sub process {
	my ( $self, $channel, $args ) = @_;

	if ( $args =~ m/^refresh (.+)$/i ) {
		$self->refresh( $1 );
	}

}

sub refresh {
	my ( $self, $server ) = @_;

	my $core = DoubleDown::Core->instance;
	my $config = $core->_config;

	$core->debug( message => sprintf ( 'Attempting to schedule refresh for %s', $server ), color => $core->debug_cyan );
}

1;


