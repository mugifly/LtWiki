package LtWiki::Controller::Wikipage;
use Mojo::Base 'Mojolicious::Controller';

# Show page
sub page_show {
	my $self = shift;

	# Load the helper
	$self->app->plugin('LtWiki::Helper::Wiki');

	my $page_name = $self->param('page_name');
	unless(defined($page_name)){
		# Redirect default page
		$self->redirect_to('/Index');
		return 0;
	}

	# Load a page
	my $page_row;
	my $is_specified_save_time = 0;
	# Show Latest page
	$page_row = $self->db->get('page' => {
		where => [
			name => $page_name
		],
		order => [ { id => 'DESC' } ], # It to get a latest revision.
	})->next;

	unless(defined($page_row)){
		# Page notfound
		$self->render( template => 'notfound', is_sp_page => 1, status	 => 404 );
		return 0;
	}

	# Output a page
	my $m = Text::Markdown->new;
	$self->render(
		page_name				=>	$page_row->name,
		page_content 			=>	$m->markdown($page_row->content),
		page_save_time 			=>	$page_row->save_time,
		is_sp_page				=>	0,
	);
}

# Show page source
sub page_source {
	my $self = shift;
	my $page_name = $self->param('page_name');
	unless(defined($page_name)){
		# Redirect default page
		$self->redirect_to('/Index');
		return 0;
	}

	# Load a page
	my $page_row;
	my $is_specified_save_time = 0;
	if(defined($self->param('save_time') && $self->param('save_time') ne '')){
		# Show Old page
		$is_specified_save_time = 1;
		$page_row = $self->db->get('page' => {
			where => [
				name => $page_name,
				save_time => $self->param('save_time')
			]
		})->next;
	}else{
		# Show Latest page
		$page_row = $self->db->get('page' => {
			where => [
				name => $page_name
			],
			order => [ { id => 'DESC' } ], # It to get a latest revision.
		})->next;
	}
	
	unless(defined($page_row)){
		# Page notfound
		$self->render( template => 'notfound', is_sp_page => 1, status	 => 404 );
		return 0;
	}

	# Output a source
	$self->render(
		page_name				=>	$page_row->name,
		page_source 				=>	$page_row->content,
		page_save_time 			=>	$page_row->save_time,
		is_specified_save_time	=>	$is_specified_save_time,
		is_sp_page				=>	1,
	);
}

# Show page history
sub page_histories {
	my $self = shift;
	my $page_name = $self->param('page_name');
	unless(defined($page_name)){
		# Redirect default page
		$self->redirect_to('/Index');
		return 0;
	}

	# Load a page
	my $page = $self->db->get('page' => {
		where => [ name => $page_name	],
		order => [ { id => 'DESC' } ], # It to get a latest revision.
	});

	# Output histories
	my @histories;
	while(my $page_row = $page->next){
		push(@histories, $page_row->{column_values});
	}
	
	$self->render(
		page_name	=>	$page_name,
		histories	=> 	\@histories,
		is_sp_page	=>	1,
	);
}

# Edit page
sub page_edit {
	my $self = shift;
	my $target_page = defined($self->param('page_name')) ? $self->param('page_name') : '';
	my $save_name = defined($self->param('save_name')) ? $self->param('save_name') : '';
	my $error_flg = '';

	# Check save name
	while(index($save_name, '/') eq 0){
		substr($save_name,0,1) = '';
	}

	if($save_name ne '' && defined($self->param('save_content'))){
		# Save mode

		my $reqest_latest_save_time = $self->param('latest_save_time'); # for conflict check.

		# Check old page
		my $old_page = $self->db->get('page' => {
				where => [ name => $target_page ],
				order => [ { id => 'DESC' } ], # It to get a latest revision.
		});
		my $c = 0;
		while(my $page_row = $old_page->next){
			# Conflict check (Compare the save time, Request and Latest.)
			if($c eq 0 && ($page_row->save_time->epoch() ne $reqest_latest_save_time)){ 
				# CONFLICT!
				$error_flg = "conflict";
				last;
			}

			# Auto delete
			if($c >= $self->app->config->{store_generation}){
				$page_row->delete();
			}
			$c += 1;
		}

		if($error_flg eq ''){ # Not error...
			# Save page to database
			my $page = $self->db->set('page' => {
				name => $save_name,
				content => $self->param('save_content'),
				role_view	=>	$self->param('permission_view'),
				role_edit	=>	$self->param('permission_edit'),
				user_id		=>	-1,
				save_time	=>	time(),
				save_ip		=>	$self->tx->remote_address,
			});

			# Redirect
			$self->redirect_to('/'.$save_name);
		}
	}

	if($target_page ne ""){
		# Editor mode - modified

		# Load a page
		my $page_row = $self->db->get('page' => {
			where => [ name => $target_page ],
			order => [ { id => 'DESC' } ], # It to get a latest revision.
		})->next;
		if(defined($page_row)){
			# Edit mode
			$self->render(
				is_new_page 		=> 0,
				is_sp_page 		=> 1,
				page_name 		=> $target_page,
				page_content 	=> defined($self->param('save_content')) ? $self->param('save_content') : $page_row->content,
				latest_save_time	=> $page_row->save_time->epoch(),
				permission_view => $page_row->role_view,
				permission_edit => $page_row->role_edit,
				error_flg		=> $error_flg,
			);
			return 1;
		}
	}

	# Editor mode - New

	$self->render(
		is_new_page		=> 1,
		is_sp_page		=> 1,
		page_name		=> $target_page,
		page_content		=> defined($self->param('save_content')) ? $self->param('save_content') : '',
		latest_save_time	=> '',
		permission_view	=> 'everybody',
		permission_edit	=> 'everybody',
		error_flg		=> $error_flg,
	);
}

# Delete page
sub page_delete {
	my $self = shift;
	my $target_page = $self->param('page_name') || '';

	if($target_page eq ''){
		$self->render( template => 'notfound', is_sp_page => 1, status	 => 404 );
	}

	$self->render(
		is_sp_page => 1,
		page_name => $target_page,
	);
	return 0;
}

# List page
sub page_list {
	my $self = shift;

	my $page;
	my $query = $self->param('query') || '';
	if($query ne ''){
		# Page name search
		$page = $self->db->get('page' => {
			where => [ name => {like => "\%$query\%"} ],
			order => [ { id => 'DESC' } ],
		});
	}else{
		# List-up page items
		$page = $self->db->get('page' => {
			order => [ { id => 'DESC' } ],
		});
	}

	# Filter latest pages
	my $pages = {};
	while(my $page_row = $page->next){
		unless(defined($pages->{$page_row->name})){
			$pages->{$page_row->name} = $page_row->{column_values};
		}
	}

	$self->render(pages => $pages, is_sp_page => 1, page_name => '', query => $query);
	return 0;
}

# Init process
sub init {
	my $self = shift;

	# Initial user

}

1;
