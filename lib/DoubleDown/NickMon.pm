=pod

ABSTRACT: Monitor Nicknames

=cut
package DoubleDown::NickMon;

use strict;
use warnings;

use Moose;
use MooseX::Singleton;

use DoubleDown::Core;

sub BUILD {
  my ($self) = @_;

  my $core = DoubleDown::Core->instance;
  $core->debug(message => 'Initializing ' . __PACKAGE__, color => $core->debug_cyan);

  # register callbacks
  my $con = $core->irc->_con;
  $con->reg_cb(nick_change => sub {
    my ($con, $old_nick, $new_nick, $is_myself) = @_;
    $core->debug(message => 'nick_change');
    $self->rename($old_nick, $new_nick);
  });

  $con->reg_cb(ident_change => sub {
    my ($con, $nick, $ident) = @_;
    $core->debug(message => 'ident_change');
    $self->update($nick, $ident);
  });

  $con->reg_cb(join => sub {
    my ($con, $nick, $channel, $is_myself) = @_;
    if ($is_myself) {
    } else {
      $self->ident($nick);
    }
  });
}

sub core {
  my ($self) = @_;
  if (!$self->{_core}) {
    $self->{_core} = DoubleDown::Core->instance;
  }
  return $self->{_core}
}

sub debug {
  my ($self, @args) = @_;
  $self->core->debug(@args);
}

sub ident {
  my ($self, $nick) = @_;
  my $stash = $self->core->_stash;
  if (!$stash->{nickmon}->{$nick}) {
    my ($n, $ident) = split('!', $self->core->irc->_con->nick_ident($nick));
    $stash->{nickmon}->{$nick} = $ident;
  }
  return $stash->{nickmon}->{$nick};
}

sub rename {
  my ($self, $old_nick, $new_nick) = @_;
  $self->debug(message => "Renaming $old_nick to $new_nick");
  my $stash = $self->core->_stash;
  delete $stash->{nickmon}->{$old_nick};
  $self->ident($new_nick);
}

sub update {
  my ($self, $nick, $ident) = @_;
  $self->debug(message => "Updating $nick to $ident");
  my $stash = $self->core->_stash;
  delete $stash->{nickmon}->{$nick};
  $self->ident($nick);
}

1;
# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=perl
