package LtWiki::I18N::ja;
use Mojo::Base 'LtWiki::I18N';
use utf8;

our %Lexicon = (
	home => 'ホーム',
	login => 'ログイン',
	page_new => '新しいページ',
	page_edit => '編集',
	page_delete => '削除',
	page_history => '履歴',
	page_search => '検索',
	page_list => 'ページ一覧',
	page_name => 'ページ名',
	page_modified_by => '変更者',
	page_modified_date => '変更日時',
	page_permission => 'ページ権限',
	page_notfound => 'ページがありません',
	permission_scope_show => '閲覧権限',
	permission_scope_edit => '編集権限',
	permission_role_everybody => '誰でも',
	permission_role_loggedin => 'ログインユーザ',
	message_page_notfound => 'お探しのページは見つかりませんでした。(´・ω・｀)',
	message_delete_confirm => 'ページを削除します。よろしいですか？',
	button_delete => '削除する',
);

1;