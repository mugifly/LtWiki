package LtWiki::Controller::Wikipage;
use Mojo::Base 'Mojolicious::Controller';

# Show page
sub page_show {
	my $self = shift;
	my $page_name = $self->param('page_name');
	unless(defined($page_name)){
		# Redirect default page
		$self->redirect_to('/Index');
		return 0;
	}

	# Load a page
	my $page_row = $self->db->get('page' => {
		where => [ name => $page_name	],
		order => [ { id => 'DESC' } ], # It to get a latest revision.
	})->next;

	unless(defined($page_row)){
		# Page notfound
		$self->render(
			page_name	=> 	'NotFound',
			is_sp_page	=> 	1,
			page_content	=>	"Not found",
			status		=>	404
		);
		return 0;
	}

	# Output a page
	my $m = Text::Markdown->new;
	$self->render(
		page_name =>	$page_row->name,
		is_sp_page => 0,
		page_content => $m->markdown($page_row->content),
	);
}

# Edit page
sub page_edit {
	my $self = shift;
	my $target_page = defined($self->param('page_name')) ? $self->param('page_name') : '';

	if(defined($self->param('save_name')) && $self->param('save_name') ne "" && defined($self->param('save_content'))){
		# Save
		my $save_name =  $self->param('save_name');
		my $page = $self->db->set('page' => {
			name => $save_name,
			content => $self->param('save_content'),
			role_view	=>	0,
			role_edit	=>	0,
			user_id		=>	-1,
			save_time	=>	time(),
			save_ip		=>	$self->tx->remote_address,
		});
		# Redirect
		$self->redirect_to('/'.$save_name);
	} else {
		# Editor
		if($target_page ne ""){
			# Load a page
			my $page_row = $self->db->get('page' => {
				where => [ name => $target_page ],
				order => [ { id => 'DESC' } ], # It to get a latest revision.
			})->next;
			if(defined($page_row)){
				# Edit mode
				$self->render(
					is_new_page => 0,
					is_sp_page => 1,
					page_name => $target_page,
					page_content => $page_row->content,
				);
				return 1;
			}
		}

		# New mode
		$self->render(
			is_new_page => 1,
			is_sp_page => 1,
			page_name => $target_page,
			page_content => '',
		);
	}
}

# Delete page
sub page_delete {
	my $self = shift;
	my $target_page = $self->param('page_name') || '';

	if($target_page eq ''){
		$self->render(status => 404);
	}

	$self->render(
		is_sp_page => 1,
		page_name => $target_page,
	);
	return 0;
}

# Init process
sub init {
	my $self = shift;

	# Initial user

}

1;
