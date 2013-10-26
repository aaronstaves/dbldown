package DoubleDown::DB;

use strict;
use warnings;

use Moose;
use MooseX::Singleton;
use DBI;

use DoubleDown::Core;

has '_dbh' => (
  is => 'ro',
  lazy_build => 1
);

sub _build__dbh {
  my ($self) = @_;
  my $core = DoubleDown::Core->instance;
  my $conf = $core->_config;
  return DBI->connect($conf->{db}->{dsn});
}

sub do {
  my ($self, $query, $attr, @args) = @_;
  my $core = DoubleDown::Core->instance;
  $core->debug(message => 'EXECUTING: ' . $query);
  # TODO: check return value ..don't remember what that should look like
  return $self->_dbh->do($query, $attr, @args);
}

sub _prepare {
  my ($self, $query) = @_;
  my $core = DoubleDown::Core->instance;
  $core->debug(message => 'PREPARING: ' . $query);
  return $self->_dbh->prepare($query);
}

sub execute {
  my ($self, $query, @bind_values) = @_;
  my $core = DoubleDown::Core->instance;
  $core->debug(message => 'EXECUTING: ' . $query);
  my $sth = $self->_prepare($query);
  my $res = $sth->execute(@bind_values);
  # TODO: check $res ..don't remember what that should look like
  return $sth;
}

1;
# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=perl
