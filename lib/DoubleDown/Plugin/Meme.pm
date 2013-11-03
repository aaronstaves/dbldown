=pod

ABSTRACT: Webpage functions

=cut
package DoubleDown::Plugin::Meme;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose; use LWP::UserAgent;

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
		'^.+$' => {
			func => 'find_meme',
			desc => 'Attempts to match a meme with any text seen'
		},
		'^show memes$' => {
			func => 'show_memes',
			desc => 'Lists memes in the current DB (private)'
		},
		'^add meme (.+?) (.+)$' => {
			func => 'add_meme',
			desc => 'Adds meme to the current DB (private)'
		},
		'^rm meme \d+$' => {
			func => 'rm_meme',
			desc => 'Removes a meme from the current DB (private)'
		}
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
  while (my $row = $sth->fetchrow_hashref) {
		my $match = $row->{match};
		my $image = $row->{image};
		if ( $message->text =~ m/$match/ ) { 
			$core->debug( message => sprintf( "text matches '%s' - showing %s" , $match, $image), color => $core->debug_on_green);
			$con->send_msg( undef, PRIVMSG => $channel, $image );

		}
	}
}

sub show_memes {
	my ( $self, $message ) = @_;

	# Only show meme commands in private
	return if $message->msg_type ne 'private';

	my $core = DoubleDown::Core->instance();
	my $db = $core->db;
	my $con  = $core->irc->_con;
	my $channel = $message->channel;


  my $sth = $db->execute("SELECT * FROM " . $self->meme_table);
	my $rows = [ ];
	push @{ $rows }, [ 'ID', 'Match', 'Image' ];
  while (my $row = $sth->fetchrow_hashref) {
		my $id    = $row->{id};
		my $match = $row->{match};
		my $image = $row->{image};
		push @{ $rows }, [ $id, $match, $image ];
	}
	my $output = $core->irc->table( $rows );
	foreach my $line ( @{ $output } ) {
		#$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( sprintf( '%i - /%s/ - %s', $id, $match, $image ) )->white('black') );
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( $line )->white('black') );
	}

}

sub add_meme {
	my ( $self, $message ) = @_;

	# Only show meme commands in private
	return if $message->msg_type ne 'private';

	my $core = DoubleDown::Core->instance();
	my $db = $core->db;
	my $con  = $core->irc->_con;
	my $channel = $message->channel;
	my $parts = $message->parts;

	my $match = $parts->[2];
	my $image = $parts->[3];

  my $sth = $db->execute("INSERT INTO " . $self->meme_table . '(match, image) VALUES(?,?)', $match, $image);
	$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( sprintf( "Added image '%s' with match /%s/", $image, $match ) )->white('black') );

}

sub rm_meme {
	my ( $self, $message ) = @_;

	# Only show meme commands in private
	return if $message->msg_type ne 'private';

	my $core = DoubleDown::Core->instance();
	my $db = $core->db;
	my $con  = $core->irc->_con;
	my $channel = $message->channel;
	my $parts = $message->parts;

	my $id = $parts->[2];
  my $sth = $db->execute("SELECT * FROM " . $self->meme_table . " WHERE id=?", $id);
  if (my $row = $sth->fetchrow_hashref) {

  	$sth = $db->execute( "DELETE FROM " . $self->meme_table . ' WHERE id=?', $id );
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( sprintf( "Removed meme /%s/ with id %d", $row->{match}, $row->{id} ) )->white('black') );
	}

}
1;



