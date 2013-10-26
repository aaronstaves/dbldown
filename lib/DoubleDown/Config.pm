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

has 'config' => (
    isa        => 'HashRef',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_config {
    my $self = shift;
    my $config = Config::JFDI->new( name => 'DoubleDown', path => $self->config_dir );
    return $config->get();
}

has 'config_dir' => (
    isa        => 'Str',
    is         => 'rw',
    lazy_build => 1,
);

sub _build_config_dir {
    return __DIR__ . '/../../';
}

1;

