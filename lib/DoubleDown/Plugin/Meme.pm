=pod

ABSTRACT: Webpage functions

=cut
package DoubleDown::Plugin::Meme;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use LWP::UserAgent;

has meme_table => (
	is => 'ro',
	isa => 'Str',
	default => sub{ 'dbldown_meme'; }
);

has text_match => (
  is => 'ro',
  isa => 'HashRef',
  builder => '_build_text_match'
);


sub _build_text_match {

  return { 
		'^.+$' => 'find_meme'
	};
}

sub init_module { 

	my $self = shift;
	my $core = DoubleDown::Core->instance();
	$core->debug( message => 'Checking to see if meme database has been initialized', color => $core->debug_on_white);

	my $db = $core->db;
  my $sth = $db->execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?", $self->meme_table);
  if (my $row = $sth->fetchrow_hashref) {
		$core->debug( message => sprintf( 'Table %s found, nothing to do', $self->meme_table ), color => $core->debug_on_green);
  }
	else { 
		$core->debug( message => sprintf( 'Table %s not found, creating table', $self->meme_table ), color => $core->debug_on_magenta);
		$self->_init_meme_table();
	}
}

sub _init_meme_table { 

	my $self = shift;
	my $core = DoubleDown::Core->instance();
	$core->debug( message => 'Checking to see if meme database has been initialized', color => $core->debug_on_white);

	my $table = $self->meme_table;

	my $sql = <<SQL
	CREATE TABLE $table(
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		match TEXT NOT NULL,
		image TEXT NOT NULL
	);

SQL
;

	my $db = $core->db;
  my $sth = $db->execute( $sql );
	$core->debug( message => sprintf( '%s table has been created', $table ), color => $core->debug_on_green);

}

sub find_meme {
	my ( $self, $message ) = @_;
	my $core = DoubleDown::Core->instance();
	my $db = $core->db;
	my $con  = $core->irc->_con;
	my $channel = $message->channel;


	$core->debug( message => sprintf( "Attempting to find meme matching '%s'" , $message->text ), color => $core->debug_on_cyan);

  my $sth = $db->execute("SELECT * FROM " . $self->meme_table);
  if (my $row = $sth->fetchrow_hashref) {
		my $match = $row->{match};
		my $image = $row->{image};
		if ( $message->text =~ m/$match/ ) { 
			$core->debug( message => sprintf( "text matches '%s' - showing %s" , $match, $image), color => $core->debug_on_green);
			$con->send_msg( undef, PRIVMSG => $channel, $image );

		}
	}
}
1;

