package DoubleDown::Core;

use Log::Dispatch;
use MooseX::Singleton;
use Term::ANSIColor qw/:constants/;
use Module::Reload;
use POSIX;

use String::IRC;
use Cwd;
use DoubleDown::Config;
use DoubleDown::DB;

=head1 ATTRIBUTES

=attr _config

Config for L<DoubleDown>.

=cut

has 'config_file' => (
	isa => 'Maybe[Str]',
	is  => 'ro',
);

has '_config' => (
    isa        => 'HashRef',
    is         => 'rw',
    lazy_build => 1,
		clearer    => 'clear__config'
);

sub _build__config {
    my $self = shift;
    return DoubleDown::Config->new({ config_file => $self->config_file })->config;
}

=attr _stash

Config for L<DoubleDown>.

=cut

has '_stash' => (
    isa        => 'HashRef',
    is         => 'rw',
    lazy_build => 1,
);

sub _build__stash {
    my $self = shift;
		return { };
}

=attr _commands

Config for L<DoubleDown>.

=cut

has '_commands' => (
    isa        => 'HashRef',
    is         => 'rw',
		default    => sub { return { }; }
);


=attr _text_match

Config for L<DoubleDown>.

=cut

has '_text_match' => (
    isa        => 'HashRef',
    is         => 'rw',
		default    => sub { return { }; }
);

=attr irc

IRC client for L<DoubleDown>

=cut

has 'irc' => (
    isa        => 'DoubleDown::IRC::Client',
    is         => 'rw',
    lazy_build => 1,
);

sub _build_irc {
    my $self = shift;
    return DoubleDown::IRC::Client->new();
}

=attr mq

Message Queue client used by L<DoubleDown>

=cut

has 'mq' => (
    isa        => 'DoubleDown::MQ::Client',
    is         => 'rw',
    lazy_build => 1,
);

sub _build_mq {
    my $self = shift;
    return DoubleDown::MQ::Client->new();
}

=attr logger

Logger used for output used for L<DoubleDown>

=cut

has 'logger' => (
	isa => 'Log::Dispatch',
	is => 'rw',
	lazy_build => 1
);

sub _build_logger {
	my $self = shift;
	return Log::Dispatch->new(
		outputs => [
			[
				'Screen',
				min_level => 'debug',
				newline   => 1
			]
		]
	);
}

=attr stash

Stash, used to store variables across various functions

=cut

has 'stash' => (
	isa => 'HashRef',
	is  => 'rw',
	default => sub { return { }; },
);

=attr db

Database thinger

=cut

has 'db' => (
    isa => 'DoubleDown::DB',
    is => 'rw',
		lazy => 1,
    default => sub { return DoubleDown::DB->instance(); }
);

=attr nickmon

Nick Monitor

=cut

has 'nickmon' => (
    isa => 'DoubleDown::NickMon',
    is => 'ro',
    lazy_build => 1
);

sub _build_nickmon {
    my ($self) = @_;
    return DoubleDown::NickMon->new();
}

sub connect {

	my $self = shift;
	my $config = $self->_config;

	$self->irc->connect( sub {

		if ( defined $config->{mq} ) {
			$self->mq->connect;
		}
    $self->nickmon;
	});
}


sub debug_bold     { return BOLD; }

sub debug_black    { return BLACK; }
sub debug_red      { return RED; }
sub debug_cyan     { return CYAN; }
sub debug_green    { return GREEN; }
sub debug_magenta  { return MAGENTA; }
sub debug_yellow   { return YELLOW; }
sub debug_blue     { return BLUE; }
sub debug_grey     { return WHITE; }
sub debug_white    { return BOLD . WHITE; }

sub debug_on_red     { return ON_RED; }
sub debug_on_magenta { return ON_MAGENTA; }
sub debug_on_yellow  { return ON_YELLOW; }
sub debug_on_green   { return ON_GREEN; }
sub debug_on_blue    { return ON_BLUE; }
sub debug_on_cyan    { return ON_CYAN; }
sub debug_on_white   { return ON_WHITE; }

sub debug {

  my $self = shift;
  my %args = @_;

  my $message = $args{message};
  my $level   = $args{level} || 0;
  my $color   = $args{color} || RESET;

  my ($package, $filename, $line) = caller;
  $message = $package . " - " . $line . " - " . $message;

  $message = $color . $message . RESET;

  $message = POSIX::strftime("%m/%d/%Y %H:%M:%S", localtime) . " - " . $message;

  $self->logger->debug( $message );
}

sub reload_config {

	my $self = shift;

	# Clear singleton
	DoubleDown::Config->instance->_clear_instance;
	$self->clear__config()

}

sub initialize {
	my $self = shift;
	$self->debug( message => (sprintf 'Initializing dbldown'), color => $self->debug_on_green );

	# find perl modules
	$self->initialize_modules();

	# Connect to IRC
	$self->connect();

	$Module::Reload::Debug = 1;
}

sub initialize_modules {
	my $self = shift;

	# reset command and text match lookups
	$self->_commands({ });
	$self->_text_match({ });

	$self->debug( message => (sprintf 'Initializing modules'), color => $self->debug_on_green );

	# find perl modules
	my $dir = getcwd;
	$self->_load_dir( $dir );
}

sub _load_dir {
	my $self = shift;
	my $dir  = shift;

	$self->debug( message => (sprintf 'Reading dir %s', $dir), color => $self->debug_on_magenta );
	my $dh;
	opendir ( $dh, $dir ) or die "Could not open $dir";;
	while ( my $file = readdir( $dh ) ) {

		my $full_file = "$dir/$file";

		if ( $file =~ m/^.+?\.pm$/ ) {
			$self->debug( message => ( sprintf 'Parsing file %s', $file ), color => $self->debug_on_cyan );

			# figure out class_name
			if ( $full_file =~ m/^.+?\/lib\/(.+?)\.pm$/ ) {
				my $class_file = $1.'.pm';
				my $class = $1;
				$class =~ s/\//::/g;
				if ( defined $INC{ $class_file} ) {
					$self->debug( message => ( sprintf 'Already loaded Module %s from %s', $class, $class_file ), color => $self->debug_on_cyan);
					$self->register_commands( $class );
					$self->register_text_match( $class );
				}
				elsif ( eval "require $class" ) {
					$self->debug( message => ( sprintf 'Successfully loaded Module %s from %s', $class, $class_file ), color => $self->debug_on_green);
					$self->register_commands( $class );
					$self->register_text_match( $class );
					$self->init_module( $class );
				}
				else {
					$self->debug( message => ( sprintf 'Failed to load Module %s', $class), color => $self->debug_on_red);
					$self->debug( message => ( sprintf '%s', $@ ), color => $self->debug_on_red);
				}
			}

		}
		elsif ( $file !~ m/^\./ && -d $full_file && $full_file !~ /\/local$/ && $full_file !~ /\/bundle$/ ) {
			$self->_load_dir( $full_file );
		}
	}
}

sub register_commands {

	my $self = shift;
	my $class = shift;
	$self->debug( message => ( sprintf 'Registering commands for %s', $class), color => $self->debug_on_blue);
	if ( $class->can('commands') ) {

		my $plugin   = $class->new();
		my $commands = $plugin->commands;
		foreach my $regex ( keys %{ $commands } ) {
			if ( $plugin->can ( $commands->{ $regex }->{func} ) ) {
				$self->debug( message => ( sprintf 'registering command %s to %s::%s', $regex, $class, $commands->{ $regex }->{func} ), color => $self->debug_on_yellow);
				$self->_commands->{ $class }->{ $regex } = $commands->{ $regex };
			}
			else {
				$self->debug( message => ( sprintf 'unable to register command %s to %s::%s. Function does not exist', $regex, $class, $commands->{ $regex }->{func} ), color => $self->debug_on_red);
			}
		}
	}
}

sub register_text_match {

	my $self = shift;
	my $class = shift;
	$self->debug( message => ( sprintf 'Registering text_match for %s', $class), color => $self->debug_on_blue);
	if ( $class->can('text_match') ) {

		my $plugin   = $class->new();
		my $text_match = $plugin->text_match;
		foreach my $regex ( keys %{ $text_match} ) {
			if ( $plugin->can ( $text_match->{ $regex }->{func} ) ) {
				$self->debug( message => ( sprintf 'registering text_match %s to %s::%s', $regex, $class, $text_match->{ $regex }->{func} ), color => $self->debug_on_yellow);
				$self->_text_match->{ $class }->{ $regex } = $text_match->{ $regex };
			}
			else {
				$self->debug( message => ( sprintf 'unable to register command %s to %s::%s. Function does not exist', $regex, $class, $text_match->{ $regex }->{func} ), color => $self->debug_on_red);
			}
		}
	}
}

sub init_module {

	my $self = shift;
	my $class = shift;
	$self->debug( message => ( sprintf 'Initializing Module %s', $class), color => $self->debug_on_blue);
	if ( $class->can('init_module') ) {

		my $plugin   = $class->new();
		my $text_match = $plugin->init_module();
	}
}

1;
