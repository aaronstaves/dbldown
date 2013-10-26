=pod

ABSTRACT: Fail functions

=cut
package DoubleDown::Plugin::Fail;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use Try::Tiny;
use XML::Simple;

has commands => (
  is => 'ro',
  isa => 'HashRef',
  builder => '_build_commands'
);

sub _build_commands {
  return {
    '^fail$' => 'process',
  };
}

sub process {
	my ( $self, $message ) = @_;

  my $core = DoubleDown::Core->instance;
  my $stash = $core->_stash;
	my $con = $core->irc->_con;
	my $config = $core->_config;
	my $channel = $message->channel;

  my $api_url = 'http://corvisafail.tumblr.com/api/read';

  my $ua = LWP::UserAgent->new();
  my $response = $ua->get( $api_url );

	if ( $response->is_success ) {
    my $data = $response->decoded_content;
    $core->debug( message => sprintf( "Successful response from %s", $api_url ), color => $core->debug_green );

		my $ref = XMLin( $data );
		my $posts = $ref->{posts}{post};
		my @fails;
		foreach my $post_id ( keys %{ $posts } ) {
			my $post_data = $posts->{ $post_id };
			my $photos = $post_data->{'photo-url'};

			foreach my $photo ( @{ $photos } ) {
				if ( $photo->{'max-width'} == 500 ) {
					push @fails, $photo->{content};
				}
			}
		}
		my $fail_index = int( rand ( scalar( @fails ) -1 ) );
		$core->irc->_con->send_msg( undef, PRIVMSG => $channel, $fails[ $fail_index ] );



  }
  else {
    $core->debug( message => "Failed response", color => $core->debug_red);
  }



}

1;
