#!/usr/bin/perl -w
#
# Given a metadata file, this script outputs an unsigned metadata aggregate
# that roughly corresponds to UK HE and FE IdPs
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

sub usage {
        my $message = shift(@_);
        if ($message) { print "\n$message\n"; }

        print <<EOF;

        usage: $0 [-h] <file>

        -h - print this help text and exit

        Given an EntityDescriptor or EntitiesDescriptor, output an EntitiesDescriptor
        which roughly contains IdPs from UK HE and FE.

        - registered by the UK federation
        - contain a scope that ends .ac.uk
        - visible IdP

EOF
}

my $help;
GetOptions (    "help" => \$help
           );

if ( $help ) {
        usage;
        exit 0;
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

my @nodes;
my $dom = XML::LibXML->load_xml( location => $xmlfile);
my $xpc = XML::LibXML::XPathContext->new( $dom );
$xpc->registerNs( 'md', 'urn:oasis:names:tc:SAML:2.0:metadata' );
$xpc->registerNs( 'mdrpi', 'urn:oasis:names:tc:SAML:metadata:rpi' );
$xpc->registerNs( 'shibmd', 'urn:mace:shibboleth:metadata:1.0' );

# From the XML::LibXML::XPathContext documentation
$xpc->registerFunction('grep_nodes', \&grep_nodes);

@nodes = $xpc->findnodes( '//md:EntityDescriptor
                [md:IDPSSODescriptor]
                [grep_nodes(md:IDPSSODescriptor/md:Extensions/shibmd:Scope, ".ac.uk$")]
		[md:Extensions/mdrpi:RegistrationInfo/@registrationAuthority="http://ukfederation.org.uk"]
		[not(md:Extensions/mdattr:EntityAttributes/saml:Attribute/saml:AttributeValue="http://refeds.org/category/hide-from-discovery")]
		');

foreach $node (@nodes) {
	@attributelist = $node->attributes();
	print join(';', @attributelist) . "\n";
}

# From the XML::LibXML::XPathContext documentation
sub grep_nodes {
           my ($nodelist,$regexp) =  @_;
           my $result = XML::LibXML::NodeList->new;
           for my $node ($nodelist->get_nodelist()) {
             $result->push($node) if $node->textContent =~ $regexp;
           }
           return $result;
};
