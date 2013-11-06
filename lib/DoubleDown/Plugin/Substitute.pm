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

	$message->text =~ m{
    ^(\S+)?
    \s*
    s/
    (.+?)
    /
    ([^/]+)
  }x;

	my $user     = $1 // $nick;
	my $search   = $2;
	my $replace  = $3;
	my $last_msg = $core->stash->{last_msg}->{$channel}->{$user};
	$core->debug(
		message => sprintf(
			'search and replace "%s" with "%s" in %s for %s in channel %s',
			$search, $replace, $last_msg, $nick, $channel
		)
	);

	my $fixed = $last_msg;
	$fixed =~ s/$search/$replace/g;

	$con->send_msg( undef, PRIVMSG => $channel, "<$user> " . $fixed ) if $fixed ne $last_msg;
	$core->stash->{last_msg}->{$channel}->{$user} = $fixed;
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
