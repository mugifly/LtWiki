package LtWiki;

# Ltwiki (Lite-talking wiki)
# (C) Masanori Ohgita - 2013.
# based on: mojo_template

use Mojo::Base 'Mojolicious';

use Data::Model;
use Data::Model::Driver::DBI;
use LtWiki::DBSchema;

use Text::Markdown;

use Net::OAuth2::Client;

# This method will run once at server start
sub startup {
	my $self = shift;
	
	# Load the plugin for Internationalization
	$self->plugin('I18N' => {default => 'en', namespace => 'LtWiki::I18N', support_url_langs => [qw(ja en)]});
	
	# Initialize router
	my $r = $self->routes;
	
	# Set the namespace of controller
	$r = $r->namespaces(['LtWiki::Controller']);
	
	# Read the app configuration
	my $conf = $self->plugin('Config',{file => 'config/config.conf'});
	
	# Set configration for cookie
	$self->app->sessions->cookie_name($conf->{session_name} || 'ltwiki');
	$self->secret('ltwiki-'.$conf->{session_secret});
	
	# Prepare database
	my $schema = LtWiki::DBSchema->new();
	{
		my $dbpath = defined($conf->{db_filepath}) ? $conf->{db_filepath} : 'db_ltwiki.db';
		my $driver = Data::Model::Driver::DBI->new(dsn => 'dbi:SQLite:dbname='.$dbpath);
		$schema->set_base_driver($driver);
	}
	for my $target ($schema->schema_names) {
		my $dbh = $schema->get_driver($target)->rw_handle;
		for my $sql ($schema->as_sqls($target)) { eval{$dbh->do($sql)};	}
	}

	# Set database helper
	$self->attr(db => sub{return $schema});
	$self->helper('db' => sub { shift->app->schema });
	
	# Bridge for pre-processing
	$r = $r->bridge->to('bridge#pre_process');
	$r = $r->bridge->to('bridge#login_check');
	
	# Routes
	$r->route('')->to('wikipage#page_show',); # Show default page
	$r->route('/:mode', mode => ['sp:new'])->to('wikipage#page_edit',); # New page

	$r->route('/:page_name')->to('wikipage#page_show'); # Show page
	$r->route('/:page_name/:mode', mode => ['sp:edit'])->to('wikipage#page_edit'); # Edit page
	$r->route('/:page_name/:mode', mode => ['sp:delete'])->to('wikipage#page_delete'); # Delete page
	
	$r->route('/session/oauth_google_redirect')->to('session#oauth_google_redirect');
	$r->route('/session/oauth_google_callback')->to('session#oauth_google_callback');
	$r->route('/session/logout')->to('session#logout');
}

1;
