package DoubleDown::IRC::Client;

use Moose;

use AnyEvent;
use AnyEvent::IRC::Client;

use DoubleDown::IRC::Event;

has '_c' => (
	is => 'rw',
	lazy_build => 1
);

sub _build__c {
	my $self = shift;
	return AnyEvent->condvar;
}

has '_con' => (
	is => 'rw',
	lazy_build => 1
);

sub _build__con {
	my $self = shift;
	return AnyEvent::IRC::Client->new();
}

sub _reg_callbacks {
	my ( $self, %args ) = @_;

	my $c   = $self->_c;
	my $con = $self->_con;
	my $handler = DoubleDown::IRC::Event->new();

  $con->reg_cb ( registered => sub {
		if ( defined $args{registered} ) {
			$args{registered}();
		}
		$handler->registered( @_ );
	} );
  $con->reg_cb ( disconnect => sub { $handler->disconnect( @_ ) } );
  $con->reg_cb ( join       => sub { $handler->channel_join( @_ ) } );
  $con->reg_cb ( publicmsg  => sub { $handler->public_msg( @_ ) } );
  $con->reg_cb ( privatemsg => sub { $handler->private_msg( @_ ) } );
  $con->reg_cb ( error      => sub { $handler->error( @_ ) } );
}

sub connect {

	my ( $self, $callback ) = @_;
	$self->_reg_callbacks(
		registered => $callback
	);

	my $c = $self->_c;
	my $con = $self->_con;
	my $core = DoubleDown::Core->instance;
	my $config = $core->_config;

	$con->connect( $config->{irc}{server}, $config->{irc}{port}, { nick => $config->{irc}{nick} } );

	foreach my $channel ( @{ $config->{irc}{channels} } ) {
		$con->send_srv( JOIN => $channel );
	}
	$c->wait;
	$con->disconnect;

}

sub nicks {
	my ( $self, $channel ) = @_;


  my $list = $self->_con->channel_list( $channel );

  my @nicks;
  foreach my $nick ( keys %{ $list } ) {

    next if $self->_con->is_my_nick( $nick );
    next if $nick =~ m/imgbot/i;
    push @nicks, $nick;
  }

	return \@nicks;

}
1;
