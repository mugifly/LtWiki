package LtWiki::DBSchema;
# Database schema definition for Data::Model

use strict;
use warnings;

use parent qw/ Data::Model /;
use Data::Model::Schema sugar => 'ltwiki';
 
## Column-sugars ##########

column_sugar 'user.id';
 
column_sugar 'page.save_time' => int => {
	inflate => sub { # DB -> Object
		return Time::Piece->new($_[0]);
	},
	deflate => sub { # Object -> DB
		ref( $_[0] ) && $_[0]->isa('Time::Piece') ? $_[0]->epoch : $_[0];
	},
};

## Tables ##########

# Table: user
install_model user => schema {
	key 'id';
	index 'session_token';
	unique 'id';

	# User ID -	char
	utf8_column 'id' => char => {
		required 	=>	1,
		size		=>	20,
	};

	# Session token
	column 'session_token' => char => {
		size		=>	40,
	};

	# Permission	(10=Administrator, 1=General, 0=Blocked)
	column 'role' => int => {
		required	=>	1,
		default		=>	10
	};
};

# Table: page
install_model page => schema {
	key 'id';
	index 'name';
	index 'save_time';
	unique 'id';

	# Page ID -	int, autoincrement
	column 'id' => int => {
		required 		=>	1,
		auto_increment	=>	1,
		unsigned		=>	1,
	};

	# Page name
	utf8_column 'name' => char => {
		required	=>	1,
		size		=>	100,
	};

	# Page content
	utf8_column 'content' => longtext => {
	};

	# Permission - View (0=everybody, 1=logged-in, 10=Administrator)
	column 'role_view' => int => {
		required	=>	1,
	};

	# Permission - Edit
	column 'role_edit' => int => {
		required	=>	1,
	};

	# Saved User ID
	column 'user.id'; # user_id

	# Saved Time
	column 'page.save_time';

	# Saved User IP-address
	column 'save_ip' => char => {
		size		=>	20,
	};
};

# Table: block_keyword
install_model block_keyword => schema {
	key 'str';
	unique 'str';

	# Keyword value -	char
	column 'str' => char => {
		required 		=>	1,
	};
};

# Table: block_ip
install_model block_ip => schema {
	key 'ip';
	unique 'ip';

	# IP-address -	char
	column 'ip' => char => {
		required 		=>	1,
	};
};

# Table: plugin
install_model plugin => schema {
	key 'id';
	unique 'id';

	# Plugin ID -	char
	column 'id' => char => {
		required 		=>	1,
	};

	# Plugin Version -	char
	column 'version' => char => {
		required 		=>	1,
	};

	# Plugin status 	(1=Enabled, 0=Disabled)
	column 'status' => int => {
		required 		=>	1,
		default 			=>	1,
	};

	# Plugin config
	utf8_column 'config' => char => {
		required	=>	0,
	};
};

1;