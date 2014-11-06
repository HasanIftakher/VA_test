#!/usr/bin/env perl
# Copyright 2014 Frank Breedijk
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ------------------------------------------------------------------------------
# This little script checks all files te see if they are perl files and if so 
# ------------------------------------------------------------------------------

use strict;
use Test::More;

my %exclude = (
	"./SeccubusV2/IVIL.pm" 	=> "MIT Licensed project",
	"./SeccubusV2/OpenVAS/OMP.pm" 	=> "Artistic License 2.0",
	"./bin/dump_ivil" 	=> "MIT Licensed project",
	"./AUTHORS.txt"		=> "Part of the license",
	"./NOTICE.txt"		=> "Part of the license",
	"./ChangeLog.md"	=> "No license needed",
	"./README.md"		=> "No license needed",
	"./Development_environment.md"
				=> "No license needed",
	"./LICENSE.txt"		=> "It is the license itself",
	"./MANIFEST"		=> "Auto generated",
	"./MYMETA.json"		=> "Auto generated",
	"./MYMETA.yml"		=> "Auto generated",
	"Makefile"		=> "Auto generated",
	"./jmvc/seccubus/production.css"	
				=> "Compiled file",
	"./jmvc/seccubus/production.js" 	
				=> "Compiled file",
	"./scanners/NessusLegacy/update-nessusrc"
				=> "Third party software",
	"./deb/debian.changelog"	=> "No comments supported",
	"./deb/debian.control"	=> "No comments supported",
	"./deb/debian.docs"	=> "No comments supported",
	"./deb/seccubus.dsc"	=> "No comments supported",
	"./Makefile"		=> "Generated",
	"./junit_output.xml"	=> "Build file",
);
my $tests = 0;

my @files = split(/\n/, `find . -type f`);

foreach my $file ( @files ) {
	if ( $file !~ /\/\./ &&			# Skip hidden files
	     $file !~ /tmp/ &&			# Skip temp files
	     $file !~ /\.\/blib\// &&		# Skip blib directory
	     $file !~ /\.(3pm|gif|jpg|png|pdf|doc|di2|uml|mwb|pdn|psd|ico|gz|deb|rpm)/i &&
	     					# Skip binary formats
	     $file !~ /\.nbe$|^\.\/scanners\/.*\/(defaults|description)\.txt$/ &&		# Skip formats without comments
	     $file !~ /docs\/(HTML|TXT|WORD)\// &&		# Skip files generated by Word
	     $file !~ /^\.\/jmvc\/(documentjs|MIT\-LICENSE\.txt|changelog\.md|funcunit|js|js\.bat|README|jquery|steal)/ &&
	     					# Skip JMVC framework
	     $file !~ /^\.\/www\// &&		# Skip complied JMVC code
	     $file !~ /^\.\/obs\/home:seccubus/ &&
	     					# OpenSuse Build services files
	     $file !~ /\.(bak|old|log)$/	# Skip backups and logs
	) { #skip certain files
		my $type = `file '$file'`;
		chomp($type);
		if ( $type =~ /Perl|shell script|ASCII|XML\s+document text|HTML document|script text|exported SGML document|Unicode text/i ) {
			if ( ! $exclude{$file} ) {
				if ( $file =~ /\.xml\..*\.example|config\.xml$/ ) {
					# License starts at line 2
					is(checklic($file,2), 0, "Is the Apache license applied to $file");
					$tests++;
					is(hasauthors($file), 1, "Has file '$file' got all 'git blame' authors in it?");
					$tests++;
				} elsif ( $file =~ /jmvc\/.*\.md$/ ) {
					# License starts at line 3
					is(checklic($file,3), 0, "Is the Apache license applied to $file");
					$tests++;
					is(hasauthors($file), 1, "Has file '$file' got all 'git blame' authors in it?");
					$tests++;
				} elsif ( $file =~ /\.ejs$/ ) {
					# License starts at line 0
					is(checklic($file,0), 0, "Is the Apache license applied to $file");
					$tests++;
					is(hasauthors($file), 1, "Has file '$file' got all 'git blame' authors in it?");
					$tests++;
				} else {
					# License starts at line 1
					is(checklic($file,1), 0, "Is the Apache license applied to $file");
					$tests++;
					is(hasauthors($file), 1, "Has file '$file' got all 'git blame' authors in it?");
					$tests++;
				}
			}
		} elsif ( $type =~ /empty/ ) {
			# Skip
		} else {
			die "Unknown file type $type";
		}
	}
}
done_testing($tests);

sub checklic {
	my $file = shift;
	my $start = shift;
	$start = 1 unless defined $start;

	open F, $file or die "Unable to open file $file";
	my @data = (<F>);
	close F;
	return 1 if $data[$start+0] !~ /Copyright/;
	return 2 if $data[$start+2] !~ /Licensed under the Apache License, Version 2\.0 \(the "License"\);/;
	return 3 if $data[$start+3] !~ /you may not use this file except in compliance with the License\./;
	return 4 if $data[$start+4] !~ /You may obtain a copy of the License at/;

	return 5 if $data[$start+6] !~ /http\:\/\/www\.apache\.org\/licenses\/LICENSE\-2\.0/;

	return 6 if $data[$start+8] !~ /Unless required by applicable law or agreed to in writing, software/;
	return 7 if $data[$start+9] !~ /distributed under the License is distributed on an "AS IS" BASIS,/;
	return 8 if $data[$start+10] !~ /WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied\./;
	return 9 if $data[$start+11] !~ /See the License for the specific language governing permissions and/;
	return 10 if $data[$start+12] !~ /limitations under the License\./;
	
	# All OK
	return 0;
}

sub hasauthors {
	my $file = shift;
	my $result = 1;

	my %authors = ();
	my %years = ();
	foreach my $auth ( split /\n/, `git blame '$file'` ) {
		if ( $auth =~ /\((.*?)\s+(\d\d\d\d)\-\d\d\-\d\d/ ) {
			$years{$2}++;
			#print "$auth - $1\n";
			if ( $1 ne "Not Committed Yet" ) {
				$authors{$1}++;
			}
		} else {
			fail("Unknow blame format '$auth'");
			$tests++;
		}
	}
	my $head = `head -20 '$file'|grep Copyright`;
	foreach my $auth (keys %authors) {
		if ( $head !~ /$auth/ ) {
			fail("Author '$auth' not in '$file'");
			$tests++;
			$result =  0;
		} else {
			ok("Author '$auth' in '$file'");
			$tests++;
		}
	}
	$head =~ /Copyright (\d+)/;
	my $copyright = $1;
	foreach my $y (sort keys %years) {
		if ($y > $copyright) {
			fail("File '$file' touched in $y but copyrighted $copyright");
			$tests++;
		} else {
			ok("File '$file' touched in $y and copyrighted $copyright");
			$tests++;
		}
	}
	return $result;
}