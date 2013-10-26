package DoubleDown;

use strict;
use warnings;

use DoubleDown::Core;


use Moose;

sub run {

	my $core = DoubleDown::Core->instance;

	$core->initialize();

}

1;
