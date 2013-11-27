=pod

ABSTRACT: Lunch functions

=cut
package DoubleDown::Plugin::Lunch;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;

has commands => (
	is => 'ro',
	isa => 'HashRef',
	builder => '_build_commands'
);

sub _build_commands {

	return {
		'^lunch king$' => {
			func => 'king',
			match_desc => 'lunch king',
			desc => 'Selects a lunch king from the current channel'
		},
		'^lunch coup$' => {
			func => 'coup',
			match_desc => 'lunch coup',
			desc => 'Initiates a lunch coup'
		},
        '^lunch abdicate$' => {
            func => 'abdicate',
            match_desc => 'lunch abdicate',
            desc => 'Abdicates the Lunch Throne'
        }
	}
}

use Try::Tiny;

sub process {
	my ( $self, $channel, $args, $nick ) = @_;
  my $core = DoubleDown::Core->instance;

	try {
		if ( $args !~ m/\s/ ) {
			$self->$args( $channel, $args, $nick );
		}
		else {
  		$core->debug( message => "Not sure how to process command $args", color => $core->debug_cyan );
		}
	} catch {
  	$core->debug( message => "Not sure how to process command $args", color => $core->debug_cyan );
  	$core->debug( message => "$_", color => $core->debug_cyan );
	};
}

sub coup {
	my ( $self, $message ) = @_;

  my $core = DoubleDown::Core->instance;
  my $stash = $core->_stash;
	my $con = $core->irc->_con;
	my $config = $core->_config;
	my $nick = $message->nick;
	my $channel = $message->channel;
	my $coup_conf = $core->_config->{lunch}{coup};

	my $coup_percentage = $coup_conf->{percentage};
	if ( !defined $coup_percentage ) {
		$coup_percentage = 0.5;
	}

	if ( !defined $stash->{lunch}{king}{nick} ) {
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new("There is currently no king!")->green('black') );
		return;
	}

	# Coup currently active
	my $nicks = $core->irc->nicks( $channel );

	# Get original number of votes needed
	my $num_votes = $coup_conf->{num_votes} || int ( ( scalar @{ $nicks } ) * $coup_percentage ) || 1;
	my $votes_needed = $num_votes;
	if ( defined $stash->{lunch}{coup}{vote} ) {
		$votes_needed = $num_votes - ( scalar ( keys %{ $stash->{lunch}{coup}{vote} } ) );
	}

	# Is a coup currently active ?
	if ( $stash->{lunch}{coup}{active} == 1 ) {

		# Nick already voted
		if ( defined $stash->{lunch}{coup}{vote}{$nick}  ) {
			$con->send_msg( undef, PRIVMSG => $nick, String::IRC->new( sprintf "You've already voted in the coup of %s", $stash->{lunch}{king}{nick} )->yellow('black') );
			$con->send_msg( undef, PRIVMSG => $nick, String::IRC->new( sprintf "%i more votes must be cast for a successful coup", $votes_needed)->yellow('black') );
			return if $votes_needed > 0;
		}

		# New vote
		else {
			$stash->{lunch}{coup}{vote}{$nick} = 1;

			# Decrement votes needed
			$votes_needed--;
		}
	}

	# New coup
	else {
  	$core->debug( message => "Attempting coup!", color => $core->debug_cyan );
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new("*** A coup has been initiated by $nick! ***")->yellow('black') );

		# Reset lunch stash
		$stash->{lunch}{coup}{active} = 1;
		$stash->{lunch}{coup}{vote} = { $nick => 1 };

		# Decrement votes needed
		$votes_needed--;
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( sprintf "Use '!%s lunch coup' to cast your vote", $config->{app_name} )->yellow('black') )
			if $votes_needed > 0;
	}

	# King is dead
	if ( $votes_needed <= 0 ) {
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( sprintf "Down with king %s!", $stash->{lunch}{king}{nick})->yellow('black') );

		# Reset king vars
		delete $stash->{lunch}{king}; #removes king->nick and king->selected timestamp

		# Reset coup vars
        # TODO: move this under {lunch}{king} so deleting the king resets everything
		$stash->{coup}{active} = 0;
		$stash->{lunch}{coup}{vote} = { };

		return;
	}

	# Show votes still required
	$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( sprintf "%i more votes must be cast for a successful coup", $votes_needed)->yellow('black') )

}

sub king {
	my ( $self, $message ) = @_;

  my $core = DoubleDown::Core->instance;
  my $stash = $core->_stash;
	my $con = $core->irc->_con;
	my $channel = $message->channel;

  $core->debug( message => "Selecting Lunch King", color => $core->debug_cyan );
	my $nicks = $core->irc->nicks( $channel );

	my $king;
	my $last_selected = $stash->{lunch}{king}{selected};

	# No king was ever selected, select one
	if ( !defined $last_selected ) {
  	$core->debug( message => "Selecting new king", color => $core->debug_magenta);
		$king = $nicks->[ int( rand( scalar @{ $nicks }) ) ];
		$stash->{lunch}{king}{nick}     = $king;
		$stash->{lunch}{king}{selected} = time;

		# Coup settings
		$stash->{lunch}{coup}{active} = 0;
		$stash->{lunch}{coup}{vote} = {};
	}
	else {

		# Last king was selected over 6 hours ago, select a new one
		my $hours_last_selected = ( ( time - ( $stash->{lunch}{king}{selected} ) ) / 60 / 60 );
		$king = $stash->{lunch}{king}{nick};
  	$core->debug( message => "King $king last selected $hours_last_selected hours ago", color => $core->debug_magenta);
		if ( $hours_last_selected > 6 ) {
  		$core->debug( message => "Selecting new king", color => $core->debug_magenta);
			$king = $nicks->[ int( rand( scalar @{ $nicks }) ) ];
			$stash->{lunch}{king}{nick}     = $king;
			$stash->{lunch}{king}{selected} = time;

			# Coup settings
			$stash->{lunch}{coup}{active} = 0;
			$stash->{lunch}{coup}{vote} = {};
		}
	}



	my @crown = (
'          _.+._          ',
'        (^\/^\/^)        ',
'         \@*@*@/         ',
'         {_____}         ',
);

	my $padding = ( ( ( length $crown[-1] ) - ( length $king ) ) / 2 );
	push @crown, (' ' x $padding ).$king.(' ' x $padding);

	foreach my $line ( @crown ) {
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new("$line")->green('black') );
	}


}

sub abdicate {
    my ($self, $message) = @_;

    my $core = DoubleDown::Core->instance;
    my $stash = $core->_stash;
    my $nick = $message->nick;
    my $channel = $message->channel;
    my $con = $core->irc->_con;

    if (!defined $stash->{lunch}{king}{nick}) {
        $con->send_msg(undef, PRIVMSG => $channel, String::IRC->new("There is currently no king!")->green('black'));
        return;
    }

    if ($stash->{lunch}{king}{nick} eq $nick) {
        $core->debug(message => "King is abdicating!", color => $core->debug_magenta);

        $con->send_msg(undef, PRIVMSG => $channel, String::IRC->new("*** $nick has abdicated the throne! ***")->yellow('black') );
        $con->send_msg(undef, PRIVMSG => $channel, String::IRC->new(sprintf "Down with coward %s!", $stash->{lunch}{king}{nick})->yellow('black'));

        # Reset king vars
        delete $stash->{lunch}{king};

        # Reset coup vars
        # TODO: move this under {lunch}{king} so deleting the king resets everything
        $stash->{coup}{active} = 0;
        $stash->{lunch}{coup}{vote} = {};

        return;
    } else {
        $con->send_msg(undef, PRIVMSG => $nick, String::IRC->new("You are not the king!")->green('black'));
        return;
    }
}

1;
# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=perl
