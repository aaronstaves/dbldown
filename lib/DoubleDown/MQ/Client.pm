package DoubleDown::MQ::Client;

use Moose;

use AnyEvent::RabbitMQ;
use Net::RabbitMQ;

use JSON::XS;

use DoubleDown::MQ::Event;

has '_con' => (
	is => 'rw',
	lazy_build => 1
);

sub _build__con {

	my $self = shift;
	my $core = DoubleDown::Core->instance;
	my $config = $core->_config->{mq};
	my $handler = DoubleDown::MQ::Event->new();

  my $mq = AnyEvent::RabbitMQ->new->load_xml_spec()->connect(
		host       => $config->{host},
		port       => $config->{port},
		user       => $config->{user},
		pass       => $config->{pass},
		vhost      => $config->{vhost},
		channel => 1,
		timeout    => 1,
		tls        => 0, # Or 1 if you'd like SSL
		on_success => sub { $handler->connect_success( @_ ) },
		on_failure =>  sub { $handler->connect_failure ( @_ ) },
		on_read_failure => sub { $handler->on_read_failure ( @_ ) },
		on_return  => sub { $handler->on_return( @_ ) },
		on_close   => sub { $handler->on_close ( @_ ) }
		);
	return $mq;
}

sub connect {

	my $self = shift;
	#$self->_reg_callbacks;

	my $con = $self->_con;

}

sub publish {

	my ( $self, $msg, $topic ) = @_;

	use Net::RabbitMQ;
  my $mq = Net::RabbitMQ->new();

	my $core = DoubleDown::Core->instance;
	my $config = $core->_config->{mq};

  $mq->connect(
		$config->{host},
		{
			user => $config->{user},
			password => $config->{pass},
			vhost => $config->{vhost},
			port => $config->{port}
		}
	);
	$mq->channel_open( $config->{channel} );
  my $publish_status = $mq->publish(
  	$config->{channel},
  	$topic,    # Routing Key
    encode_json( $msg ),
    { exchange => $config->{exchange}, },
    {
      content_type  => 'text/javascript',
      delivery_mode => 2,            # persistent
      headers       => { dest_app => 'DoubleDown' },
      timestamp     => time(),
    }
  );

  if ( $publish_status < 0 ) {
		print "ERROR: error publishing message\n";
  }

  $mq->disconnect();
}


1;
