package DoubleDown;

use strict;
use warnings;

use DoubleDown::Core;


use Moose;

has config_file => (
	isa => 'Maybe[Str]',
	is  => 'ro'
);

sub run {

	my $self = shift;

	# Create an instance of the core
	# For some reason initialize doesn't work here, using new for now
	my $core = DoubleDown::Core->new({ config_file => $self->config_file });

	# Initialize performs all initial setup
	$core->initialize();

}

1;
