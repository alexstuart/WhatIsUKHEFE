#!/usr/bin/perl -w
#
# Given a metadata aggreagte, this script outputs an unsigned metadata aggregate
# that roughly corresponds to UK HE and FE IdPs in it.
#
# Author: Alex Stuart, alex.stuart@jisc.ac.uk
#
#   Copyright 2019 Jisc
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

use XML::LibXML;
use Getopt::Long;
$DEBUG = 0;

sub usage {
        my $message = shift(@_);
        if ($message) { print "\n$message\n"; }

        print <<EOF;

        usage: $0 [-h] [-b <entityID>] [-a <entityID>] <file>

        Given a SAML metadata aggregate, output an unsigned EntitiesDescriptor
        which contains IdPs

        - registered by the UK federation
        - contain a scope that ends .ac.uk
        - are visible

        Typically you would input the UK federation metadata aggregate to this script.
        This gives a first approximation to the community of UK HE and FE providers.
        Then add or remove entities to build the community of IdPs that you require for
        your specific application. Explicitly added entities are added to the output,
        even if they are explicitly blocked or not selected by the algorithm.

	-b <entityID>	- entityID will be removed from output.
			  More than one -b <entityID> can be given.
        -a <entityID>	- entityID that is explicitly allowed.
			  More than one -a <entityID> can be given.

        -h 		- print this help text and exit
        -d		- print debug information. NB: this is to STDOUT as is the XML so beware!

EOF
}

my $help;
my @blocked;
my @allowed;
my $debug;
GetOptions (    "help" => \$help,
		"debug" => \$debug,
		"blocked=s@" => \@blocked,
		"allowed=s@" => \@allowed
           );

if ( $help ) {
        usage;
        exit 0;
}

if ( $debug ) {
	$DEBUG = 1;
}

if ( ! $ARGV[0] ) {
        usage "ERROR: Must provide a file to check";
        exit 1;
}

$xmlfile = $ARGV[0];

if ( ! -r $xmlfile ) {
        usage "ERROR: Must provide a readable XML file, not $xmlfile";
        exit 1;
}

#
# Blocklists and explicit additions
#

$DEBUG && print "Allow list: " . join(' ', @allowed) . "\n";
$DEBUG && print "Blocklist: " . join(' ', @blocked) . "\n";

#
# Aggregate header
#
binmode(STDOUT, ":utf8");
print STDOUT <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<EntitiesDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
EOF

#
# Ingest XML file
#
my @nodes;
my $dom = XML::LibXML->load_xml( location => $xmlfile);
my $xpc = XML::LibXML::XPathContext->new( $dom );
$xpc->registerNs( 'md', 'urn:oasis:names:tc:SAML:2.0:metadata' );
$xpc->registerNs( 'mdrpi', 'urn:oasis:names:tc:SAML:metadata:rpi' );
$xpc->registerNs( 'shibmd', 'urn:mace:shibboleth:metadata:1.0' );

#
# Allowed entities are printed first
#
for $allowed (@allowed) {
        $DEBUG && print "Finding $allowed\n";
        @nodes = $xpc->findnodes( '//md:EntityDescriptor[./@entityID="'.$allowed.'"]');
        for $node (@nodes) {
                $newnode = $node->cloneNode( 1 );
                print $newnode;
        }
}

#
# Now the algorithmically-determined entities
#

# From the XML::LibXML::XPathContext documentation
$xpc->registerFunction('grep_nodes', \&grep_nodes);

@nodes = $xpc->findnodes( '//md:EntityDescriptor
                [md:IDPSSODescriptor]
                [grep_nodes(md:IDPSSODescriptor/md:Extensions/shibmd:Scope, ".ac.uk$")]
		[md:Extensions/mdrpi:RegistrationInfo/@registrationAuthority="http://ukfederation.org.uk"]
		[not(md:Extensions/mdattr:EntityAttributes/saml:Attribute/saml:AttributeValue="http://refeds.org/category/hide-from-discovery")]
		');

foreach $node (@nodes) {
# Removing any in the blocklist
	my @attributelist = $node->attributes();
	$blocked = 0;
	foreach $attribute ( $node->attributes() ) {
		foreach $block ( @blocked ) {
			if ( $attribute =~ m/^\s*entityID="$block"\s*$/ ) { $blocked = 1; }
		}
	}
	next if $blocked == 1;

# Uses cloneNode to get all the namespace prefix definitions
	$newnode = $node->cloneNode( 1 );
	print $newnode;
}

#
# Aggregate footer
#
print STDOUT "\n</EntitiesDescriptor>\n";

#
# Subroutines ----------------------------------------------------------------------
#

# From the XML::LibXML::XPathContext documentation
sub grep_nodes {
           my ($nodelist,$regexp) =  @_;
           my $result = XML::LibXML::NodeList->new;
           for my $node ($nodelist->get_nodelist()) {
             $result->push($node) if $node->textContent =~ $regexp;
           }
           return $result;
};
