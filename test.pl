# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Slash::Repository;
use Slash::Utility;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# Put here a valid virtual user for your site
my $virtual_user = "slashcode";
my $plugins = Slash::Repository->new($virtual_user);
my $constants = getCurrentStatic();

print "Actual plugins in the database:\n";
my $plugin_list =$plugins->getPluginsRecentIDs();
foreach (@$plugin_list) {
    print "    $_: ";
    my $plugin = $plugins->getPlugin($_);
    print $plugin->{name};
    my $version = $plugins->getVersion($plugins->getPluginVersionID($_));
    print " ($version->{version})\n";
} 

print "Different approve status for the plugin ...\n";
my $hashref = $plugins->getDescriptions('plugin_approve');
for (keys %$hashref) {
    print "$_ : $hashref->{$_}\n";
}
print "First approve status...\n";
print $plugins->getDescription('plugin_approve',1)."\n";

print "Repository creation OK\n";
print "Testing descriptions ...\n";
for my $type (qw | plugin_status plugin_category plugin_license plugin_approve | ) {
	print "Testing $type\n";
	my $values = $plugins->getDescriptions($type);
	for(keys %$values) {
		print "Key $_ Values $values->{$_}\n";
	}
}
print "Test the creation of plugins ...\n";
my %info;
$info{name} = "Test";
$info{description} = "Test de plugins";
$info{url} = "http://barrapunto.com";
$info{license} = 1;
$info{category} = 1;
# This is for the version
$info{changelog_url} = "http://plugins.barrapunto.com/test/changelog";
$info{changes} = "Great advance in stability";
$info{version} = "0.3.13";
$info{status} = "1";

my $form = \%info;

my %plugin_info = (
		   uid => 45,	       
		   name => strip_nohtml($form->{name}),
		   description => strip_nohtml($form->{description}),
		   url => strip_nohtml($form->{url}),
		   category => $form->{category}, 
		   license => $form->{license}, 
		   -created => 'now()',
		   );

my $plugin_id = $plugins->createPlugin(\%plugin_info);

print "Created new plugin: $plugin_id\n";

my %version_info = (
		uid => 45,	       
		changes => strip_nohtml($form->{changes}),
		download_url => strip_nohtml($form->{url}),
		changelog_url => strip_nohtml($form->{changelog_url}),
		version => strip_nohtml($form->{version}),
		status => $form->{status},
		-created => 'now()',
		plugin_id => $plugin_id,
	);

my $version_id = $plugins->createVersion(\%version_info);

print "Created new version: $version_id\n";

my $current_plugins_for_check = $plugins->getPluginsRecentIDs($constants->{plugins_default_display},0,1); 
print "Total number of plugins unchecked: ".scalar(@$current_plugins_for_check)."\n";
for(@$current_plugins_for_check) {
    print "Plugin: ".$_."\n";
}

my $current_plugins_checked = $plugins->getPluginsRecentIDs($constants->{plugins_default_display}); 
print "Total number of plugins checked: ".scalar(@$current_plugins_checked)."\n";
for(@$current_plugins_checked) {
    print "Plugin: ".$_."\n";
}

my $current_plugins_rejected = $plugins->getPluginsRecentIDs($constants->{plugins_default_display},0,3); 
print "Total number of plugins rejected: ".scalar(@$current_plugins_rejected)."\n";
for(@$current_plugins_rejected) {
    print "Plugin: ".$_."\n";
}






