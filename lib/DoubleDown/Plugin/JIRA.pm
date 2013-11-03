=pod

ABSTRACT: Webpage functions

=cut
package DoubleDown::Plugin::JIRA;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use JIRA::Client;
use Encode qw(decode encode);
use Try::Tiny;

=head1 Text Matches

General text to key off of

=cut

has text_match => (
  is => 'ro',
  isa => 'HashRef',
  builder => '_build_text_match'
);

sub _build_text_match {

  return {
  	'[A-Za-z0-9]+?\-\d+' => {
			func => 'get_ticket',
			desc => 'Outputs JIRA ticket information matching ABCD-1234'
		}
  }
}

=head1 ATTRIBUTES

=head2 jira

Interface to the jira client.  Expects values in the local config

=cut

has jira => (
  is         => 'ro',
  isa        => 'JIRA::Client',
  lazy_build => 1,
	builder    => '_build_jira',
  handles => {
    get_available_actions => 'getAvailableActions',
    get_fields_for_action => 'getFieldsForAction',
  },
);

sub _build_jira {
	my $self = shift;
	my $core = DoubleDown::Core->instance;
  my $conf = $core->_config();

  my $jira_url = $conf->{plugin}{jira}{jira_url} || $conf->{plugin}{jira}{jira_hostname};
  my $jira_user = $conf->{plugin}{jira}{jira_username};
  my $jira_passwd = $conf->{plugin}{jira}{jira_password};

	$core->debug(
		message => sprintf('Connecting to jira server %s as %s [ %s ]', $jira_url, $jira_user, $jira_passwd),
		color => $core->debug_green
	);

  return JIRA::Client->new($jira_url, $jira_user, $jira_passwd);

}

=head2 STATUSES

Holds status references for JIRA

=cut

has statuses => (
	is => 'ro',
	isa => 'HashRef',
	lazy_build => 1,
	builder => '_build_statuses'
);

sub _build_statuses {
	my $self = shift;

	use Data::Dumper;
	my $statuses = $self->jira->get_statuses;
	my $status_ref = { };
	foreach my $name ( keys %{ $statuses } ) {
		$status_ref->{ $statuses->{ $name }->{id} } = $name;
	}
	return $status_ref;
}


=head1 METHODS

=head2 get_ticket

Gets ticket information

=cut


sub get_ticket {
	my ( $self, $message ) = @_;

	my $core = DoubleDown::Core->instance;
	my $con  = $core->irc->_con;
	my $channel = $message->channel;
	my $jira = $self->jira;


	# Go through all message parts
	foreach my $part ( @{ $message->parts } ) {

		# If it matches a jira ticket style number
		if ( $part =~ m/([A-Za-z0-9]+?)\-(\d+)/ ) {

			# Save ticket identifier
			my $ticket = $1.'-'.$2;
			$core->debug(
				message => sprintf("Grabbing JIRA ticket information for '%s'", $ticket ),
				color => $core->debug_green
			);

			# Try to get the issue, return if it doesn't exist
			my $issue = eval { $jira->getIssue( $ticket ) };
			next if !defined $issue;

			# If it matches a url, no need to re-output the url
			my $line1 = sprintf ( "https://jira.corvisa.com/browse/%s ( %s )", $ticket, $self->statuses->{ $issue->{status} } );
			if ( $part =~ m/https*\:\/\// ) {
				$line1 = sprintf( 'Status: %s', $self->statuses->{ $issue->{status} } );
			}

			# Output jira info
			$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new(sprintf( encode('utf-8', $line1) ) )->yellow('black') );
			$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new(encode('utf-8', sprintf("Reporter/Assignee: %s/%s", $issue->{reporter}, $issue->{assignee} ) ) )->yellow('black') );
			$con->send_msg( undef, PRIVMSG => $channel, String::IRC->new(encode('utf-8', sprintf("Summary: %s", $issue->{summary} ) ) )->yellow('black') );
		}
	}


}

1;



