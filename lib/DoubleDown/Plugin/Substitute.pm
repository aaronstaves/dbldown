package DoubleDown::Plugin::Substitute;

use Moose;
use namespace::autoclean;

has text_match => (
	is      => 'ro',
	isa     => 'HashRef',
	builder => '_build_text_match'
);

sub _build_text_match {
	return {
		'^(\S+)?\s*s\/(.+?)\/([^\/]+)' => {
			func       => 'process',
			match_desc => 's/orig/sub or <nick> s/orig/sub',
			desc       => 'Substitues original text with new text'
		},
		'^.+$' => {
			func       => 'stash_last_msg',
			match_desc => '<text>',
			desc       => 'Stores last text entered in by any user'
		}
	};
}

sub process {
	my ( $self, $message ) = @_;

	my $core    = DoubleDown::Core->instance;
	my $con     = $core->irc->_con;
	my $parts   = $message->parts;
	my $channel = $message->channel;
	my $nick    = $message->nick;

	my ( $fixed, $user ) = $self->_perform_substitution($message);
	if ($fixed) {
		$con->send_msg( undef, PRIVMSG => $channel, "<$user> " . $fixed );
		$core->stash->{last_msg}->{$channel}->{$user} = $fixed;
	}
}

sub _perform_substitution {
	my $self    = shift;
	my $message = shift;

	my $core = DoubleDown::Core->instance;

	my $text = $message->text;
	my $nick = $message->nick;

	my $fixed = undef;
	my $user  = undef;

	if (
		$text =~ m{
			^
			(?<nick> \S+)?     # $1: optional nick
			\s*                # optional amount of spacing
			s/                 # start search/replace regex
			(?<search> .+)     # $2: search for chars...
			(?<!\\)            #     until reach an unescaped...
			/                  #     slash
			(?<replace> .+)    # $3: replace with chars
			/                  # end regex
			(?<mods> [gi]+)?   # $4: optional mods
		  }x
	  )
	{

		$user = $+{nick} // $nick;
		my $search  = $+{search};
		my $replace = $+{replace};
		my %mods    = map { $_ => 1 } split( '', $+{mods} // '' );

		my $last_msg = $core->stash->{last_msg}->{ $message->channel }->{$user};
		$fixed = $last_msg;

		# TODO: can't use vars for modifiers, any better ideas?
		if ( $mods{g} && $mods{i} ) {
			$fixed =~ s/$search/$replace/gi;
		}
		elsif ( $mods{g} ) {
			$fixed =~ s/$search/$replace/g;
		}
		elsif ( $mods{i} ) {
			$fixed =~ s/$search/$replace/i;
		}
		else {
			$fixed =~ s/$search/$replace/;
		}

		$fixed = undef if $fixed eq $last_msg;
	}

	return ( $fixed, $user );
}

sub stash_last_msg {

	my ( $self, $message ) = @_;
	my $channel = $message->channel;
	my $nick    = $message->nick;

	return if !defined $nick || $nick eq 'UNKNOWN';

	my $core = DoubleDown::Core->instance;

	$core->stash->{last_msg}->{$channel}->{$nick} = $message->text;
	$core->debug(
		message => sprintf( 'received public message %s in channel %s from %s', $message->text, $channel, $nick ),
		color   => $core->debug_cyan
	);
}

__PACKAGE__->meta->make_immutable;

1;
