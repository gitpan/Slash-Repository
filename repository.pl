#!/usr/bin/perl -w

###############################################################################
# repository.pl - a software repository system for slashcode
# 
# Copyright (C) 2001 Barrapunto S.L. & Brian Aker
# acs@barrapunto.com
# brian@tangent.org
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#
###############################################################################
use strict;
use Slash;
use Slash::DB;
use Slash::Display;
use Slash::Utility;
use Slash::Repository;
use Slash::XML;
use LWP;

##################################################################
sub main {

	my $form = getCurrentForm();
	my $user = getCurrentUser();
	my $plugins = Slash::Repository->new(getCurrentVirtualUser());

	my %ops = (
		   new_plugin => \&new_plugin_form,
		   preview_plugin => \&preview_plugin,
		   edit_plugin => \&preview_plugin,
		   create_plugin => \&create_plugin,
		   update_plugin => \&update_plugin,
		   delete_plugin => \&delete_plugin,
		   delete_version => \&delete_version,
		   new_version => \&new_version_form,
		   preview_version => \&preview_version,
		   edit_version => \&preview_version,
		   create_version => \&create_version,
		   update_version => \&update_version,
		   default => \&list,
		   get => \&get,
		   list => \&list,
		   validate => \&validate,
		   reject => \&reject,
		   validate_item => \&validate_item,
		   validate_list => \&validate_list,
		   user_plugins => \&mine,
		   mine => \&mine,
		   search => \&search,
		   help => \&help, 
	);

	my %ops_rss = (
		list => \&listRSS,
		default => \&listRSS,
	 );

	if ($form->{content_type} eq 'rss') {
	    if ($ops_rss{$form->{op}}) {
		$ops_rss{$form->{op}}->($form, $user, $plugins);
	    } else {
		$ops_rss{'default'}->($form, $user, $plugins);
	    }
	} else {

	    header("Repository $form->{op}",'repository');
	    titlebar("100%", "Repository");
	    print createMenu('repository');

	    my $op = $form->{'op'};
	    $op = 'default' unless $ops{$op};
	    $ops{$op}->($form, $user, $plugins);
	
	    footer();
	}
	writeLog($form->{'op'});
}

############################################################################
sub validate_item {
	my ($form, $user, $plugins) = @_;

	unless($user->{is_admin}) {
		validate_list(@_);
		return;
	}

	if($form->{type} eq 'version') {
		my $version = get_version_display($plugins, $form->{id});
		slashDisplay("plugin",{
				plugin => get_plugin_display($plugins, $version->{plugin_id}),
				version => $version,
		});
		slashDisplay("validate", {
				version_id => $form->{id},
				type => $form->{type}
		});
	} elsif ($form->{type} eq 'plugin') {
		slashDisplay("plugin_only",{
				plugin => get_plugin_display($plugins, $form->{id}),
		});
		slashDisplay("validate", {
				plugin_id => $form->{id},
				type => $form->{type}
		});
	}
}

############################################################################
sub validate {
	my ($form, $user, $plugins) = @_;
	my $constants = getCurrentStatic();

	unless($user->{is_admin}) {
		validate_list(@_);
		return;
	}

	if($form->{type} eq 'version') {
		$plugins->setVersion($form->{version_id}, { approved => 2, approved_uid => $user->{uid} });
		my $version = $plugins->getVersion($form->{version_id});
		my $plugin = $plugins->getPlugin($version->{plugin_id});
		my $submission = {
		                email   => $plugins->getUser($version->{uid},'fakeemail'),
				uid     => $version->{uid},
				name    => $plugins->getUser($version->{uid},'nickname'),
				story   => slashDisplay("version_submit",{plugin=>$plugin,version=>$version},{ Return => 1}),
				subj    => slashDisplay("data", { value => "announce_new_release" },{ Return => 1, Nocomm => 1})." $plugin->{name} ($version->{version_id})",
				tid     => $constants->{repository_default_topic},
				section => $constants->{repository_default_section}
		};
		$submission->{subid} = $plugins->createSubmission($submission);
	} elsif ($form->{type} eq 'plugin') {
		$plugins->setPlugin($form->{plugin_id}, { approved => 2, , approved_uid => $user->{uid} });
#		my $plugin = $plugins->getPlugin($form->{plugin_id});
#		my $version = $plugins->getVersion($plugins->getPluginVersionID($plugin->{plugin_id}));
#		my $submission = {
#	                email   => $plugins->getUser($plugin->{uid},'fakeemail'),
#				uid     => $plugin->{uid},
#				name    => $plugins->getUser($plugin->{uid},'nickname'),
#				story   => slashDisplay("plugin_submit",{plugin=>$plugin},{ Return => 1}),
#				subj    => $plugin->{name},
#				tid     => $constants->{repository_default_topic},
#				section => $constants->{repository_default_section}
#		};
#		$submission->{subid} = $plugins->createSubmission($submission);
	}

	validate_list(@_);
}

############################################################################
sub reject {
	my ($form, $user, $plugins) = @_;

	unless($user->{is_admin}) {
		validate_list(@_);
		return;
	}

	if($form->{type} eq 'version') {
	    $plugins->setVersion($form->{version_id}, { approved => 3, approved_uid => $user->{uid}});
	    if ($form->{reject_reason}) {
		$plugins->setVersion($form->{version_id}, {reject_reason=>$form->{reject_reason}});
	    } else {
		slashDisplay("reject",{version => get_version_display($plugins, $form->{version_id}), type => $form->{type}});
	    }
	} elsif ($form->{type} eq 'plugin') {
	    $plugins->setPlugin($form->{plugin_id}, { approved => 3, approved_uid => $user->{uid}});
	    if ($form->{reject_reason}) {
		$plugins->setPlugin($form->{plugin_id}, {reject_reason=>$form->{reject_reason}});
	    } else {
		slashDisplay("reject",{plugin => get_plugin_display($plugins, $form->{plugin_id}), type => $form->{type}});
	    }
	}
	validate_list(@_);
}

############################################################################
# Yes, there is no seclev on this on purpose. No real reason to not
# allow someone to look. -Brian
# Maybe we have to rethink the limit os the unvalidated list
sub validate_list {
	my ($form, $user, $plugins) = @_;

	$form->{plugin} = 'plugin'  unless (($form->{type} eq 'plugin') or ($form->{type} eq 'version'));
	if($form->{type} eq 'plugin') {
		slashDisplay("validation_list", { 
				items => $plugins->getPluginsUnValidated(getCurrentStatic('plugins_default_display')),
				type => 'plugin',
		});
	} elsif ($form->{type} eq 'version') {
		slashDisplay("validation_list", {
				items => $plugins->getVersionsUnValidated(getCurrentStatic('plugins_default_display')),
				type => 'version',
		});
	}
}

############################################################################
sub preview_plugin {
	my ($form, $user, $plugins) = @_;

	my ($plugin_info, $version_info);

	if (!$form->{plugin_id}) {
		$plugin_info = {
				uid => $user->{uid},	       
				name => strip_nohtml($form->{name}),
				description => strip_nohtml($form->{description}),
				url => strip_nohtml($form->{url}),
				license => strip_nohtml($form->{license}),
				category => strip_nohtml($form->{category}), 
				uid => $user->{uid},
				created => localtime(),
				updated => localtime(),
		};
		$version_info = {
				uid => $user->{uid},	       
				changes => strip_nohtml($form->{changes}),
				download_url => strip_nohtml($form->{download_url}),
				changelog_url => strip_nohtml($form->{changelog_url}),
				version => strip_nohtml($form->{version}),
				status => $form->{status},
				uid => $user->{uid}
		};
	} else {
		$plugin_info = $plugins->getPlugin($form->{plugin_id});
		$version_info =$plugins->getVersion($plugins->getPluginVersionID($form->{plugin_id})); 
	}
	
	my %display_plugin = %$plugin_info;	
	$display_plugin{category} = $plugins->getDescription('plugin_category',$display_plugin{category});
	$display_plugin{license} = $plugins->getDescription('plugin_license',$display_plugin{license});
	slashDisplay("plugin",{
		plugin=>\%display_plugin,
		version=>$version_info,
	});

	slashDisplay("new_plugin",{
		plugin=>$plugin_info,
		version=>$version_info,
		license => $plugins->getDescriptions('plugin_license'),
		category => $plugins->getDescriptions('plugin_category'),
		status => $plugins->getDescriptions('plugin_status'),
	}) if (!$form->{plugin_id} || $user->{uid} eq $plugin_info->{uid});
}

############################################################################
sub preview_version {
	my ($form, $user, $plugins) = @_;
	
	if (!$form->{plugin_id} && !$form->{version_id}) {
	  slashDisplay("data",{value=>"version_not_found"});
	  return;
	};
 
	my $version_info;
	if ($form->{version_id}) {
		$version_info = $plugins->getVersion($form->{version_id});
	} else {
		$version_info = {
				plugin_id => strip_nohtml($form->{plugin_id}),
				uid => $user->{uid},	       
				changes => strip_nohtml($form->{changes}),
				download_url => strip_nohtml($form->{download_url}),
				changelog_url => strip_nohtml($form->{changelog_url}),
				version => strip_nohtml($form->{version}),
				status => $form->{status},
		};
	}

	slashDisplay('plugin',{
			plugin=>get_plugin_display($plugins, $version_info->{plugin_id}),
			version=>$version_info,
	});

	slashDisplay("new_version",{
		version=>$version_info,
		status => $plugins->getDescriptions('plugin_status'),
	}) if (!$form->{version_id} || $user->{uid} eq $version_info->{uid}); 
}

############################################################################
sub create_plugin {
	my ($form, $user, $plugins) = @_;

	my $plugin_info = {
	    uid => $user->{uid},	       
	    name => strip_nohtml($form->{name}),
	    description => strip_nohtml($form->{description}),
	    url => strip_nohtml($form->{url}),
	    category => $form->{category}, 
	    license => $form->{license}, 
	    -created => 'now()',
	};

	my $plugin_id = $plugins->createPlugin($plugin_info);

	my $version_id = create_version($form, $user, $plugins, $plugin_id);
	slashDisplay("plugin",{
			plugin=>get_plugin_display($plugins, $plugin_id),
			version=>get_version_display($plugins, $version_id)
	}) if $version_id;

	if(!$version_id) {
	    $plugins->deletePlugin ($plugin_id);
	    slashDisplay("data", { value => "error_new_plugin" });
	}
}

############################################################################
sub get_plugin_display {
	my ($obj, $id) = @_;

	my $plugin = $obj->getPlugin($id);
	$plugin->{license} = $obj->getDescription('plugin_license',$plugin->{license});
	$plugin->{category} = $obj->getDescription('plugin_category',$plugin->{category});
	$plugin->{approved} = $obj->getDescription('plugin_approve',$plugin->{approved});

	return $plugin;
}

############################################################################
sub get_version_display {
	my ($obj, $id, $pid) = @_;

	my $version = $obj->getVersion($id);
	$version->{status} = $obj->getDescription('plugin_status',$version->{status});
	$version->{approved} = $obj->getDescription('plugin_approve',$version->{approved});

	return $version;
}

############################################################################
sub delete_plugin {
	my ($form, $user, $plugins) = @_;

	# This is a hog
	my $plugin = $plugins->getPlugin($form->{plugin_id});

	if($plugin and ($plugin->{uid} == $user->{uid} or $user->{is_admin})) {
		$plugins->deletePlugin($form->{plugin_id});
		$plugins->deleteVersionByPluginID($form->{plugin_id});
	}
	mine(@_);
}

############################################################################
sub delete_version {
	my ($form, $user, $plugins) = @_;

	# This is a hog
	my $version = $plugins->getVersion($form->{version_id});

	if($version and ($version->{uid} == $user->{uid} or $user->{is_admin})) {
		$plugins->deleteVersion($form->{version_id});
	}
	mine(@_);
}

############################################################################
sub update_plugin {
	my ($form, $user, $plugins) = @_;

	my $plugin_info = {
		uid => $user->{uid},	       
		name => strip_nohtml($form->{name}),
		description => strip_nohtml($form->{description}),
		url => strip_nohtml($form->{url}),
		category => $form->{category}, 
		license => $form->{license}, 
		approved => 1,
	};

	$plugins->setPlugin($form->{plugin_id},$plugin_info);
	update_version ($form, $user, $plugins);
}

	

############################################################################
sub create_version {
	my ($form, $user, $plugins, $plugin_id) = @_;

	$plugin_id = $form->{plugin_id} if !$plugin_id;

	if ($plugin_id) {
		 # Yep, perfomance blow -Brian
		 $plugin_id = $plugins->getPlugin($plugin_id) ? $plugin_id : '';
	} else {
	 slashDisplay("data",{value=>"plugin_not_found"});
	 return;  
	}

	my $version_info = {
		 uid => $user->{uid},	       
		 plugin_id => $plugin_id,	       
		 changes => strip_nohtml($form->{changes}),
		 download_url => strip_nohtml($form->{download_url}),
		 changelog_url => strip_nohtml($form->{changelog_url}),
		 version => strip_nohtml($form->{version}),
		 status => $form->{status},
		 -created => 'now()',
	};

	my $version_id = $plugins->createVersion($version_info);
	return unless $version_id;

	slashDisplay("plugin",{
		plugin=>get_plugin_display($plugins, $plugin_id),
		version=>get_version_display($plugins, $version_id, $plugin_id)
	});

	return $version_id;
}

############################################################################
sub update_version {
	my ($form, $user, $plugins) = @_;
	
	slashDisplay("data",{value=>"version_not_found"}) if !$form->{version_id};

	my $version_info = $plugins->getVersion($form->{version_id});

	if (!$version_info) {
		slashDisplay("data",{value=>"version_not_found"});
		return;  
	}

	$version_info = {
			changes => strip_nohtml($form->{changes}),
			download_url => strip_nohtml($form->{download_url}),
			changelog_url => strip_nohtml($form->{changelog_url}),
			version => strip_nohtml($form->{version}),
			status => $form->{status},
			approved => 1,
	};

	$plugins->setVersion($form->{version_id},$version_info);   

	slashDisplay("plugin",{
			plugin=>get_plugin_display($plugins, $form->{plugin_id}),
			version=>get_version_display($plugins, $form->{version_id})
	});
}

############################################################################
sub new_plugin_form {
	my ($form, $user, $plugins) = @_;

	slashDisplay("new_plugin", {
			license => $plugins->getDescriptions('plugin_license'),
			category => $plugins->getDescriptions('plugin_category'),
			status => $plugins->getDescriptions('plugin_status'),
			});
}

############################################################################
sub new_version_form {
	my ($form, $user, $plugins) = @_;
	
	my $plugin = get_plugin_display($plugins, $form->{plugin_id});
	if (!$plugin) {
	    slashDisplay("data", { value => "error_new_version" });
	    return;
	}
	slashDisplay("plugin",{
		plugin=>$plugin
	});
	slashDisplay("new_version",{
			version=>{
			plugin_id=>$form->{plugin_id},
			status => $plugins->getDescriptions('plugin_status'),
	    }
	});
}

############################################################################
sub get {
	my ($form, $user, $plugins) = @_;

	my $plugin = get_plugin_display($plugins, $form->{plugin_id});

	if($plugin) {
		if($form->{version_id}) {
			slashDisplay("plugin",{
					plugin=>$plugin,
					version=>get_version_display($plugins, $form->{version_id})
			});
		} else {
			slashDisplay("plugin_only",{
					plugin=>$plugin
			});
		}
	} else {
		if (!$plugin) {
				slashDisplay("data",{value=>"plugin_not_found"});
				return;
		}
	}
	
	unless($form->{version_id}) {
	    my $ids;
	    if ($user->{uid} eq $plugin->{uid}) { 
		$ids = $plugins->getVersionIDs($form->{plugin_id});
	    } else {
		$ids = $plugins->getVersionIDs($form->{plugin_id},"2");
	    }
	    for(@$ids) {
		slashDisplay("version_link",{
		    version=>get_version_display($plugins, $_)
		    });
	    }
	}
}

############################################################################
sub list {
	my ($form, $user, $plugins) = @_;

	my $current_plugins = $plugins->getPluginsRecentIDs(getCurrentStatic('plugins_default_display'));
	slashDisplay("search");
	foreach (@$current_plugins) {
		slashDisplay("plugin",{
			plugin=>get_plugin_display($plugins, $_),
			version=>get_version_display($plugins, $plugins->getPluginVersionID($_))
		});
	}
}

############################################################################
sub mine {
	my ($form, $user, $plugins) = @_;

	my $uid = $form->{uid} ? $form->{uid} : $user->{uid};
	my $all = ($uid == $user->{uid}) ? 1 : 0;
	my $current_plugins = $plugins->getPluginsForUser($user->{uid}, $all);
	for(@$current_plugins) {
		slashDisplay("plugin_only",{
			plugin=>get_plugin_display($plugins, $_)
		});
		slashDisplay("plugin_info",{
			plugin_id=>$_
		});
	}
	if (!@$current_plugins) {
	    slashDisplay("data", { value => "has_no_plugins" });
	}
}

############################################################################
sub search {
    my ($form, $user, $plugins) = @_;

    my $search_plugins = $plugins->getPluginsByName($form->{query},getCurrentStatic('plugins_default_display'));
	slashDisplay("search");
    for my $item (@$search_plugins) {
	my ($plugin, $version) = @$item;
	slashDisplay("plugin",{
	    plugin=>get_plugin_display($plugins, $plugin),
	    version=>get_version_display($plugins, $version),
	});
    }
    
}
############################################################################
sub help {
   slashDisplay("help"); 
}


############################################################################
sub listRSS {
	my ($form, $user, $plugins) = @_;
	my($submissions, @items);
	my $constants = getCurrentStatic();

	my $current_plugins = $plugins->getPluginsRecentIDs(getCurrentStatic('plugins_default_display'));
	foreach (@$current_plugins) {
	    my $plugin = $plugins->getPlugin ($_); 
	    push (@items, {
		title   => $plugin->{name},
		link  => "$constants->{absolutedir}/repository.pl?op=get&plugin_id=$_",
	    });
	}

	return xmlDisplay('rss', {
                channel => {
                        title   => "$constants->{sitename} repository",
                        'link'  => "$constants->{absolutedir}/repository.pl?op=list",
                },
                items   => \@items,
        });
}

main();






