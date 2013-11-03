=pod

ABSTRACT: Duke of Perl functions

=cut
package DoubleDown::Plugin::Duke;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;

use Try::Tiny;

has commands => (
  is => 'ro',
  isa => 'HashRef',
  builder => '_build_commands'
);

sub _build_commands {
  return {
    '^perl duke$' => {
			func => 'duke',
			desc => 'Selects a perl duke from current channel'
		},
    '^perl coup$' => {
			func => 'coup',
			desc => 'Initiates a perl coup'
		}
  };
}

sub coup {
	my ( $self, $message ) = @_;

  my $core = DoubleDown::Core->instance;
  my $stash = $core->_stash;
	my $con = $core->irc->_con;
	my $config = $core->_config;
	my $channel = $message->channel;
	my $nick = $message->nick;

    # TODO
    # I cant get at this :C
	my $coup_conf = $core->_config->{duke}{coup};

	my $coup_percentage = $coup_conf->{percentage};
	if ( !defined $coup_percentage ) {
		$coup_percentage = 0.5;
	}

	if ( !defined $stash->{perl}{duke}{nick} ) {
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new("There is currently no duke!")->green('black') );
		return;
	}

	# Coup currently active
	my $nicks = $core->irc->nicks( $channel );

	# Get original number of votes needed
	my $num_votes = $coup_conf->{num_votes} || int ( ( scalar @{ $nicks } ) * $coup_percentage ) || 1;
	my $votes_needed = $num_votes;
	if ( defined $stash->{perl}{coup}{vote} ) {
		$votes_needed = $num_votes - ( scalar ( keys %{ $stash->{perl}{coup}{vote} } ) );
	}

	# Is a coup currently active ?
	if ( $stash->{perl}{coup}{active} == 1 ) {

		# Nick already voted
		if ( defined $stash->{perl}{coup}{vote}{$nick}  ) {
			$con->send_msg( undef, PRIVMSG => $nick, String::IRC->new( sprintf "You've already voted in the coup of %s", $stash->{perl}{duke}{nick} )->yellow('black') );
			$con->send_msg( undef, PRIVMSG => $nick, String::IRC->new( sprintf "%i more votes must be cast for a successful coup", $votes_needed)->yellow('black') );
			return if $votes_needed > 0;
		}

		# New vote
		else {
			$stash->{perl}{coup}{vote}{$nick} = 1;

			# Decrement votes needed
			$votes_needed--;
		}
	}

	# New coup
	else {
  	$core->debug( message => "Attempting coup!", color => $core->debug_cyan );
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new("*** A coup has been initiated by $nick!***")->yellow('black') );

		# Reset perl stash
		$stash->{perl}{coup}{active} = 1;
		$stash->{perl}{coup}{vote} = { $nick => 1 };

		# Decrement votes needed
		$votes_needed--;
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( sprintf "Use '!%s perl coup' to cast your vote", $config->{app_name} )->yellow('black') )
			if $votes_needed > 0;
	}

	# Duke is dead
	if ( $votes_needed <= 0 ) {
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( sprintf "Down with Duke %s!", $stash->{perl}{duke}{nick})->yellow('black') );

	  my @guillotine = (
'       __.--.____________.--.__      ',
'      (       _.------._       ).    ',
'       \'._.--\'    ||    \'--._.\'  )   ',
'        | |================| || (    ',
'        | ||               | ||  )   ',
'        | ||              _| || (    ',
'        | ||          _.-\' | ||  )   ',
'        | ||      _.-\'     | || (    ',
'        | ||  _.-\'         | ||  )   ',
'        | |.-\'             | || (    ',
'        | ||               | ||  )   ',
'        | ||               | || (    ',
'        | ||               | ||  )   ',
'        | ||               | || (    ',
'        | ||               | ||  )   ',
'        | ||               | || (    ',
'        | .---.            | ||  )   ',
'        | |   |            | || (    ',
'        | |   |            | ||  )   ',
'        | |  .\'            | || (    ',
'        | | \'              | ||  )   ',
'        | |  \'.            | || (    ',
'        | |   |            | ||  )   ',
'        | |O__|  .))).     | || (    ',
'        | ||    ( O O )    | ||      ',
'        | ||===._ (_) _.===| ||      ',
'        | ||     \'-.-\'     | ||      ',
'        | || not one of my | ||      ',
'        | ||  better days  | ||      ',
'        | ||    ______     | ||      ',
'        | ||   /      \    | ||      ',
'      __| ||  (\______/)   | ||_____ ',
'     /__| ||___) |\'\'| (____| ||____/ ',
'    /___|_|/  (________)   |_|/___/  ',
'   /_____________________________/   ',
);

	  my $padding = ( ( ( length $guillotine[-1] ) - ( length $stash->{perl}{duke}{nick} ) ) / 2 );
	  push @guillotine, (' ' x $padding ).$stash->{perl}{duke}{nick}.(' ' x $padding);

	  foreach my $line ( @guillotine ) {
		  $con->send_msg( undef, PRIVMSG => $channel, String::IRC->new("$line")->red('black') );
	  }

		# Reset duke vars
		delete $stash->{perl}{duke}; #removes duke->nick and duke->selected timestamp

		# Reset coup vars
		$stash->{coup}{active} = 0;
		$stash->{perl}{coup}{vote} = { };

		return;
	}

	# Show votes still required
	$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( sprintf "%i more votes must be cast for a successful coup", $votes_needed)->yellow('black') )

}

sub duke {
	my ( $self, $message ) = @_;

  my $core = DoubleDown::Core->instance;
  my $stash = $core->_stash;
	my $con = $core->irc->_con;
	my $channel = $message->channel;
	my $nick = $message->nick;

  $core->debug( message => "Selecting Duke of Perl", color => $core->debug_cyan );
	my $nicks = $core->irc->nicks( $channel );

	my $duke;
	my $last_selected = $stash->{perl}{duke}{selected};

	# No duke was ever selected, select one
	if ( !defined $last_selected ) {
  	$core->debug( message => "Selecting new duke", color => $core->debug_magenta);
		$duke = $nicks->[ int( rand( scalar @{ $nicks }) ) ];
		$stash->{perl}{duke}{nick}     = $duke;
		$stash->{perl}{duke}{selected} = time;

		# Coup settings
		$stash->{perl}{coup}{active} = 0;
		$stash->{perl}{coup}{vote} = {};
	}
	else {

		# Last duke was selected over 6 hours ago, select a new one
		my $hours_last_selected = ( ( time - ( $stash->{perl}{duke}{selected} ) ) / 60 / 60 );
		$duke = $stash->{perl}{duke}{nick};
  	$core->debug( message => "Duke $duke last selected $hours_last_selected hours ago", color => $core->debug_magenta);
		if ( $hours_last_selected > 6 ) {
  		$core->debug( message => "Selecting new duke", color => $core->debug_magenta);
			$duke = $nicks->[ int( rand( scalar @{ $nicks }) ) ];
			$stash->{perl}{duke}{nick}     = $duke;
			$stash->{perl}{duke}{selected} = time;

			# Coup settings
			$stash->{perl}{coup}{active} = 0;
			$stash->{perl}{coup}{vote} = {};
		}
	}



	my @crown = (
'          _.+._          ',
'        (^\/^\/^)        ',
'         \@*@*@/         ',
'         {_____}         ',
);

	my $padding = ( ( ( length $crown[-1] ) - ( length $duke ) ) / 2 );
	push @crown, (' ' x $padding ).$duke.(' ' x $padding);

	foreach my $line ( @crown ) {
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new("$line")->green('black') );
	}


}

1;
# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=perl

