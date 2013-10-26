package DoubleDown::Plugin::Rhyme;

use Moose;
use namespace::autoclean;

require DoubleDown::Plugin::Rhyme::Word;

use LWP::Simple;
use JSON;

has commands => (
  is => 'ro',
  isa => 'HashRef',
  builder => '_build_commands'
);

sub _build_commands {
  return {
    '^rhyme .+$' => 'process',
  };
}


sub process {
	my ( $self, $message ) = @_;

	my $core = DoubleDown::Core->instance;
	my $con = $core->irc->_con;
	my $parts = $message->parts;
	my $channel = $message->channel;

	# splice it, the first 2 vars will be !dbldown rhyme
	my @args = splice @{ $message->parts }, 2;

	my @words = @args;
	my @output;

	my @do_not_rhyme_list = qw/
		is
		to
		be
		the
		and
		I
	/;

	foreach my $word (@words) {
		$word =~ s/![[:alpha:]]//g;
		if( $word ~~ @do_not_rhyme_list) {
			push @output, $word;
		}
		else
		{
			push @output, DoubleDown::Plugin::Rhyme::Word->new(input => $word)->rhyme;
		}
	}

	my $out_string = join ' ', @output;

    $con->send_msg( undef, PRIVMSG => $channel, String::IRC->new($out_string) );
}

__PACKAGE__->meta->make_immutable;

1;
