package DoubleDown::Config;

use strict;
use warnings;


# ABSTRACT: Singleton for accessing DoubleDown config files

=head1 SYNOPSIS

  use DoubleDown::Config;
  my $config_r = DoubleDown::Config->instance->config;

=cut

use MooseX::Singleton;
use Config::JFDI;
use Dir::Self;

has 'config_file' => (
	isa => 'Maybe[Str]',
	is  => 'ro'
);

has 'config' => (
    isa        => 'HashRef',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_config {
    my $self = shift;
		my $core = DoubleDown::Core->instance;
		my %config;

		$core->debug( message => 'Loading DoubleDown specific config', color => $core->debug_yellow );
    my $dbldown_config = Config::JFDI->new( name => 'DoubleDown', path => $self->base_config_dir )->get();
		%config = ( %config, %{ $dbldown_config } );

		if ( defined $self->config_file ) {
			my $config_file = $self->file_config_dir . '/' . $self->config_file . '.yml';
			$core->debug( message => sprintf( 'Loading %s config', $config_file ), color => $core->debug_yellow );
    	my $file_config = Config::JFDI->new( file => $config_file )->get();
			%config = ( %config, %{ $file_config} );
		}

    return \%config
}

has 'base_config_dir' => (
    isa        => 'Str',
    is         => 'rw',
    lazy_build => 1,
);

sub _build_base_config_dir {
    return __DIR__ . '/../../';
}

has 'file_config_dir' => (
    isa        => 'Str',
    is         => 'rw',
    lazy_build => 1,
);

sub _build_file_config_dir {
    return __DIR__ . '/../../config';
}

1;

