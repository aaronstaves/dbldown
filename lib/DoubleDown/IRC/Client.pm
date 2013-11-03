package DoubleDown::IRC::Client;

use Moose;

use AnyEvent::IRC::Client;

use DoubleDown::IRC::Event;

=head1 ATTRIBUTES

=head2 _c

Condition variable used by AnyEvent

=cut
has '_c' => (
	is => 'rw',
	lazy_build => 1
);

sub _build__c {
	my $self = shift;
	return AnyEvent->condvar;
}

=head2 _con

AnyEvent IRC Client object used by DoublDown

=cut
has '_con' => (
	is => 'rw',
	lazy_build => 1
);

sub _build__con {
	my $self = shift;
	return AnyEvent::IRC::Client->new();
}

=head1 METHODS

=head2 _reg_callbacks

Registers AnyEvent IRC specific callbacks with various
functions in DoublDown::IRC::Event

=cut

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

=head2 connect

Connects to the IRC server and executs condvar->wait

=cut
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

=head2 nicks

Grabs nicks from a specific channel

=cut
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

=head2 table

Returns an array of strings that represent a table that
is suitable for output on IRC.  This is useful when trying
to output large amounts of data (i.e. database tables) for
debugging or admin functions.

The first column is expected to be a header

Input: 
my $data_set = [
  [ 'ID', 'Description', 'URL' ],
	[ 1, 'Google Website', 'http://google.com' ],
	[ 2, 'Yahoo Site', 'http://www.yahoo.com' ]
];

Returns:
[
	'----------------------------------------------',
	'| ID | Description    | URL                  |',
	'----------------------------------------------',
	'| 1  | Google Website | http://google.com    |',
	'| 2  | Yahoo Site     | http://www.yahoo.com |',
	'----------------------------------------------'
];


=cut 
sub table { 

	my $self = shift;
	my $rows = shift;

	my $col_index = [ ];
	# figure out what our max column lengths are
	foreach my $row ( @{ $rows } ) {
		foreach my $col ( 0..scalar @{ $row } - 1 ) {

			# grab value and initialize column length index
			my $value = $row->[ $col ];
			$col_index->[ $col ] = 0 if !defined $col_index->[ $col ];

			# if the lenght is greater than the current one, increase it
			if ( length ( $value ) > $col_index->[ $col ] ) { 
				$col_index->[ $col ] = length $value;
			}
		}
	}

	# Our actual output
	my @output;

	# Figure out the top border`
	my $top_border = '--';
	foreach my $col ( 0..scalar @{ $col_index } - 1 ) {
		my $value = '-' x $col_index->[ $col ] . '--';
		$value = '-' . $value if $col > 0;
		$top_border .= $value;
	}
	push @output, $top_border;

	# First row should be the column headers
	my $header = shift @{ $rows };
	my $header_row = '| ';
	foreach my $col ( 0..scalar @{ $header } - 1 ) {
		my $value = $header->[ $col ];
		$value .= ' ' x ( $col_index->[ $col ] - length ( $value ) ) ;
		$value = ' ' . $value if $col > 0;
		$header_row .= $value . ' |';
	}

	# add the header as well as the bottom border
	push @output, $header_row;
	push @output, $top_border;

	# Add the rest of the columns
	foreach my $row ( @{ $rows } ) {

		my $col_line = '| ';
		foreach my $col ( 0..scalar @{ $row } - 1 ) {

			my $value = $row->[ $col ];

			# add extra spaces
			$value .= ' ' x ( $col_index->[ $col ] - length ( $value ) );
			$value = ' ' . $value if $col > 0;
			$col_line .= $value . ' |';
		}
		push @output, $col_line;
	}

	# add bottom border
	push @output, $top_border;

	# return arrayref of strings
	return \@output;

}
1;
