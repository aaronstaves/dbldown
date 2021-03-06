=pod

ABSTRACT: Webpage functions

=cut
package DoubleDown::Plugin::Web;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use LWP::UserAgent;

has text_match => (
  is => 'ro',
  isa => 'HashRef',
  builder => '_build_text_match'
);

sub _build_text_match {

  return {
  '\b(([\w-]+://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))' => {
			func => 'webpage',
			match_desc => '<url>',
			desc => 'Grabs webpage title and outputs in channel'
		}
  };
}

sub webpage {
	my ( $self, $message ) = @_;

	my $core = DoubleDown::Core->instance;
	my $conf = $core->_config();
	my $con  = $core->irc->_con;
	my $channel = $message->channel;
	foreach my $part ( @{ $message->parts } ) {

		my $jira_url = $conf->{plugin}{jira}{jira_url};
		next if ( $part =~ m/$jira_url/i );

		# Whoops, this is a crazy url, any better url matches ?
		if ( $part =~ m{\b(([\w-]+://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))} ) {
			$core->debug(
			 	message => sprintf("Valid URL: '%s'", $part),
				color => $core->debug_green
			);
			my $ua = LWP::UserAgent->new();
			my $response = $ua->get( $part );
			if ( $response->is_success ) {
			  $core->debug(
			    message => sprintf("Successfully fetched '%s'", $part),
					color => $core->debug_green
			  );
				if ( defined $response->title() ) {
			  	$core->debug(
			    	message => sprintf("Found title '%s'", $response->title()),
						color => $core->debug_green
			  	);
					$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new(sprintf("Title: %s", $response->title() ) )->yellow('black') );
				}
			}
			else {
			  $core->debug(
			    message => sprintf("Failed to fetch '%s'", $part),
					color => $core->debug_red
			  );
			  $core->debug(
			    message => sprintf("%s", $response->status_line),
					color => $core->debug_red
			  );
			}

		}
		else {
			$core->debug(
			 	message => sprintf("Invalid URL: '%s'", $part),
				color => $core->debug_red
			);
		}

	}

	print STDERR $1;



}

1;


