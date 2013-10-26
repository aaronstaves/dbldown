package DoubleDown;

use strict;
use warnings;

use DoubleDown::Core;


use Moose;

sub run {

	# Create an instance of the core
	my $core = DoubleDown::Core->instance;

	# Initialize performs all initial setup
	$core->initialize();

}

1;
