package Slash::Repository;

use strict;

use Slash;
use Slash::Utility;
use Slash::DB::Utility;
use Slash::DB::MySQL;

@Slash::Repository::ISA = qw(Slash::DB::Utility Slash::DB::MySQL);
$Slash::Repository::VERSION = '0.9';

sub new {
	my($class, $user) = @_;
	my $self = {};
	bless($self, $class);
	$self->{virtual_user} = $user;
	$self->sqlConnect();

	return $self;
}

sub createPlugin {
	my ($self, $plugin_info) = @_;
	$self->sqlInsert("repository",$plugin_info);
	# don't know how to make this correctly - acs (look fry Messages)
	my ($plugin_id) = $self->sqlSelect("LAST_INSERT_ID()");
	return $plugin_id;
}

sub createVersion {
	my ($self, $plugin_info) = @_;
	$self->sqlInsert("plugin_release",$plugin_info);
	# don't know how to make this correctly - acs (look fry Messages)
	my ($version_id) = $self->sqlSelect("LAST_INSERT_ID()");
	return $version_id;
}

sub getPlugin {
	my ($self,$plugin_id) = @_;
	my $answer = $self->sqlSelectHashref ('*',
			 'repository', "plugin_id=$plugin_id"
	);

	return $answer;				    
}

sub setPlugin {
	my ($self, $plugin_id, $plugin_info) = @_;
	my $table = "repository";

	$self->sqlUpdate($table,$plugin_info,"plugin_id='$plugin_id'");
}

sub deletePlugin {
	my ($self,$plugin_id) = @_;
	my $answer = $self->sqlDo("DELETE FROM repository WHERE plugin_id='$plugin_id'");
}

sub getPluginVersionID {
    my ($self,$plugin_id) = @_;
    my $column = "version_id";
    my $tables = "repository, plugin_release";
    my $where = "repository.plugin_id = plugin_release.plugin_id";
    $where .=" AND repository.plugin_id='$plugin_id'";
    $where .=" AND plugin_release.approved='2'";
    my $other = "ORDER BY plugin_release.created DESC LIMIT 1";
    my ($version_id) = $self->sqlSelect($column,$tables,$where,$other);
    return $version_id;
}

sub deleteVersionByPluginID {
	my ($self,$plugin_id) = @_;
	my $answer = $self->sqlDo("DELETE FROM plugin_release WHERE plugin_id=$plugin_id");
}

sub deleteVersion {
	my ($self,$version_id) = @_;
	my $answer = $self->sqlDo("DELETE FROM plugin_release WHERE version_id=$version_id");
}

sub getVersion {
	my ($self,$version_id) = @_;
	my $table = "plugin_release";
	my $where = "version_id='$version_id'";
	my $answer = $self->sqlSelectHashref('*', $table, $where);

	return $answer;				    
}

sub setVersion {
	my ($self,$version_id, $version_info) = @_;
	my $table = "plugin_release";

	$self->sqlUpdate($table,$version_info,"version_id='$version_id'");
}

sub getPluginsRecentIDs {
	my ($self, $limit) = @_;
	my $answer;
	my $table = 'repository, plugin_release';
	my $columns = 'DISTINCT(repository.plugin_id)';
	my $where = " plugin_release.approved=2 AND repository.approved=2 AND  repository.plugin_id = plugin_release.plugin_id ";
	my $other = " GROUP BY repository.plugin_id";
	$other .= " ORDER BY plugin_release.updated DESC";
	$other .= " LIMIT $limit" if $limit>0;
	$answer = $self->sqlSelectColArrayref($columns, $table, $where, $other);

	return $answer;
}

sub getPluginsByName {
        my ($self, $query, $limit) = @_;
        my $answer;
        my $table = 'repository,plugin_release';
        my $columns = 'repository.plugin_id, plugin_release.version_id';
        my $where = " plugin_release.approved=2 AND repository.approved=2 AND  repository.plugin_id = plugin_release.plugin_id ";
	$where .=" AND repository.name LIKE '%$query%'";
        my $other = " ORDER BY plugin_release.updated ASC";
        $other .= " LIMIT $limit" if $limit>0;
        $answer = $self->sqlSelectAll($columns, $table, $where, $other);
        
	return $answer;
}


sub getPluginsForUser {
	my ($self, $uid, $all) = @_;
	my $answer;
	my $table = 'repository';
	my $columns = 'plugin_id';
	my $where = " uid='$uid' ";
	$where .= " AND approved=2 " unless $all;
	my $other = " ORDER BY updated ASC";
	$answer = $self->sqlSelectColArrayref($columns, $table, $where, $other);

	return $answer;
}

sub getPluginsUnValidated {
	my ($self, $limit) = @_;
	my $answer;
	my $table = 'repository';
	my $columns = 'plugin_id as id , name, created';
	my $where = " approved=1";
	my $other = " ORDER BY updated DESC";
	$other .= " LIMIT $limit" if $limit>0;
	$answer = $self->sqlSelectAllHashrefArray($columns, $table, $where, $other);

	return $answer;
}

sub getVersionsUnValidated {
	my ($self, $limit) = @_;
	my $answer;
	my $table = 'repository, plugin_release';
	my $columns = 'plugin_release.version_id as id, repository.name as name, plugin_release.created as created';
	my $where = " plugin_release.approved=1 AND plugin_release.plugin_id = repository.plugin_id ";
	my $other = " ORDER BY plugin_release.created DESC";
	$other .= " LIMIT $limit" if $limit>0;
	$answer = $self->sqlSelectAllHashrefArray($columns, $table, $where, $other);

	return $answer;
}

sub getVersionIDs {
	my ($self, $plugin_id, $approved) = @_;
	my $answer;
	my $table = 'plugin_release';
	my $columns = 'version_id';
	my $where = " plugin_id='$plugin_id' ";
	$where .= " AND approved='$approved' " if $approved;
	my $other = " ORDER BY created DESC ";
	$answer = $self->sqlSelectColArrayref($columns, $table, $where, $other);

	return $answer;
}

my %descriptions = (
	'plugin_status'
		=> sub { $_[0]->sqlSelectMany('code,name', 'code_param', "type='plugin_status'") },
	'plugin_category'
		=> sub { $_[0]->sqlSelectMany('code,name', 'code_param', "type='plugin_category'") },
	'plugin_license'
		=> sub { $_[0]->sqlSelectMany('code,name', 'code_param', "type='plugin_license'") },
	'plugin_approve'
		=> sub { $_[0]->sqlSelectMany('code,name', 'code_param', "type='plugin_approve'") },
		);


########################################################
# This is from Slash::DB::Mysql. This will be expanded
# in the future in Slashcode, to make this redundant.
# Basically, when Fry is released this can be dropped
# -Brian
# pass in additional optional descriptions
sub getDescriptions {
	my($self, $codetype, $optional, $flag) =  @_;
	return unless $codetype;
	my $codeBank_hash_ref = {};
	my $cache = '_getDescriptions_' . $codetype;

	if ($flag) {
		undef $self->{$cache};
	} else {
		return $self->{$cache} if $self->{$cache};
	}

	my $descref = $descriptions{$codetype};

	my $sth = $descref->(@_);
	while (my($id, $desc) = $sth->fetchrow) {
		$codeBank_hash_ref->{$id} = $desc;
	}
	$sth->finish;

	$self->{$cache} = $codeBank_hash_ref if getCurrentStatic('cache_enabled');
	return $codeBank_hash_ref;
}

########################################################
sub getDescription {
	my($self, $codetype, $key) =  @_;
	return unless $codetype;
	return unless $key;

	my $codeBank_hash_ref = $self->getDescriptions($codetype);

	return $codeBank_hash_ref->{$key};
}

1;
__END__


=head1 NAME

Slash::Repository - Perl extension for a system plugin fro slashcode

=head1 SYNOPSIS

  use Slash::Repository;

=head1 DESCRIPTION

A plugin for slashcode to manage a plugin system

=head1 AUTHOR

Alvaro del Castillo, acs@barrapunto.com
Brian Aker, brian@tangent.org

=head1 SEE ALSO

perl(1). Slash(3).

=cut
