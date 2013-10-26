package DoubleDown::Plugin::Rhyme::Word;

use Moose;
use namespace::autoclean;

use LWP::Simple;
use JSON;

has 'input' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has 'matches' => (
	is => 'rw',
	isa => 'ArrayRef[Str]',
	lazy => 1,
	default => sub {
		my $self = shift;
		my @matches;
		my @not_so_good_matches;
		my @horrid_matches;
		my $syllables = %{decode_json( get($self->info_url) )}->{syllables};
		my $json_data = decode_json( get($self->rhyme_url) );

		foreach my $word ( @{$json_data} )
		{
			if( $word->{syllables} == $syllables && $word->{score} >= 300) {
				push @matches, $word->{word};
			}
			elsif( $word->{syllables} != $syllables && $word->{score} >= 300 )
			{
				push @not_so_good_matches, $word->{word};
			}
			elsif ( $word->{score} >= 220 ) {
				push @horrid_matches, $word->{word};
			}

			if( scalar @matches == 0 ) {
				push @matches, @not_so_good_matches;
			}
			if( scalar @matches == 0 ) {
				push @matches, @horrid_matches;
			}

			if( scalar @matches == 0  )
			{
				push @matches, "___";
			}
		}


		return \@matches;

	},
);

has 'info_url' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $self = shift;
		return "http://www.rhymebrain.com/talk?function=getWordInfo&word=".$self->input;
	},
);

has 'rhyme_url' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $self = shift;
		return "http://www.rhymebrain.com/talk?function=getRhymes&word=".$self->input."&maxResults=30";
	},
);

has 'rhyme' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $length = scalar @{$self->matches};
		my $random_entry = int( rand($length) );
		my $retval = $self->matches->[$random_entry];
		$retval = "___" if ( not defined $retval );
		return $retval;
	},
);

__PACKAGE__->meta->make_immutable;

1;
