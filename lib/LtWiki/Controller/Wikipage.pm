package LtWiki::Controller::Wikipage;
use Mojo::Base 'Mojolicious::Controller';

# Wiki page render
sub page_show {
	my $self = shift;
	my $page_name = $self->param('page_name');
	unless(defined($page_name)){
		$self->redirect_to('/Index');
	}

	my $page_content = "";
	my $mkdwn = <<'EOF';
Wiki文法が
====

解釈されて...

## イイ感じ〜。

### は〜い、OK〜！(´∀｀*)ｳﾌﾌ♪

----

* ヽ(*´∀｀)ノ ｷｬｯﾎｰｲ!!

    * perl （・∀・）ｲｲ!!

    * ...

### Powered by [Text::Markdown](http://search.cpan.org/~bobtfish/Text-Markdown-1.000031/lib/Text/Markdown.pm).

EOF
	my $m = Text::Markdown->new;
	$self->render(
		page_name => $page_name,
		is_sp_page => 0,
		page_content => $m->markdown($mkdwn)
	);
}

sub page_edit {
	my $self = shift;
	my $target_page = $self->param('page_name') || '';

	if($target_page eq ''){
		# New mode
		$self->render(
			is_new_page => 1,
			is_sp_page => 1,
			page_name => '',
		);
	} else {
		# Edit mode
		$self->render(
			is_new_page => 0,
			is_sp_page => 1,
			page_name => $target_page,
		);
	}
	return 0;
}

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

1;
