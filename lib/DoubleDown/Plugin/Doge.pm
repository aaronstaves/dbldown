=pod

ABSTRACT: Webpage functions

=cut
package DoubleDown::Plugin::Doge;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use WWW::Wordnik::API;
use List::Util qw( shuffle );
use Try::Tiny;

has text_match => (
  is => 'ro',
  isa => 'HashRef',
  builder => '_build_text_match'
);

sub _build_text_match {

  return {
  '^doge(\s.+)*$' => {
			func => 'doge',
			match_desc => 'doge, doge <word>',
			desc => 'Generates random doge'
		}
  };
}

sub _get_related {
	my $word = shift;

  my $p = WWW::Wordnik::API->new();
	my $core = DoubleDown::Core->instance;
	my $conf = $core->_config();

  $p->api_key( $conf->{plugin}{wordnik}{api_key} );
  #$p->debug(1);
  $p->cache(100);
  $p->format('perl');

	my $related = [];
	if ( !defined $word ) { 
		$word = $p->randomWord()->{word};
		$core->debug(
			message => sprintf("Random word generated: %s", $word),
			color => $core->debug_green
		);
	}

	try { 
		$related = $p->related($word, type => [qw/
			synonym 
			hyponym 
			same-context
			antonym 
			form 
			variant 
			verb-stem 
			verb-form 
		/]);
	}
	catch { 
		$core->debug(
			message => sprintf("Error getting word: %s", $word),
			color => $core->debug_red
		);
	};
	#cross-reference 

	my @words;
	push @words, $word;
	foreach my $relationship ( @{ $related } ) { 
		push @words, @{ $relationship->{words} };
	}

	return \@words;

}

sub doge {
	my ( $self, $message ) = @_;

	my $core = DoubleDown::Core->instance;
	my $conf = $core->_config();
	my $con  = $core->irc->_con;
	my $channel = $message->channel;
	my $ua = LWP::UserAgent->new();

	if ( !defined $conf->{plugin}{wordnik} && !defined $conf->{plugin}{wordnik}{api_key} ) { 
		$core->debug(
			message => sprintf("No wordnik api key defined in config.  Exiting"),
			color => $core->debug_red
		);
		return;
	}

	my $word;
	my $parts = $message->parts;
	$word = $parts->[1] if defined $parts->[1];

	my @words;
	while ( scalar ( @words < 4 ) ) {
		@words = @{ _get_related( $word ) };
		$word = undef if ( scalar @words < 4 );
	}
	$word = shift @words;

	my @prefix = qw/ the such very many so wow wow /;

	@prefix = shuffle( @prefix );
	@words = shuffle( keys %{{ map { $_ => 1 } @words }} );

	my @doge_lines;
	while ( ( my $line = shift @prefix) && scalar( @words ) && scalar ( @doge_lines < 5 ) ) { 

		if ( $line ne 'wow' ) { 
			$line .= ' ' . ( shift @words );
		}

		$line =~ s/-/ /g;
		@prefix = shuffle ( @prefix );
		@words  = shuffle ( @words  );

		$line = ( ' ' x int ( rand(25) ) ) . $line;
		
		push @doge_lines, $line;
	}

	my @colors = shuffle(qw/ 
	  blue navy
	  green
	  red
	  brown maroon
	  purple
	  orange olive
	  yellow
	  light_green lime
	  teal
	  light_cyan cyan aqua
	  light_blue royal
	  pink light_purple fuchsia
	  grey
	  light_grey silver
	/);
	#my $header_color = shift @colors;
	#$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( (uc $word ) . ":" )->$header_color('black') );
	foreach my $line ( @doge_lines ) { 
		my $color = shift @colors;
		$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new( $line )->$color('black') );
		@colors = shuffle( @colors );
	}




}

1;


