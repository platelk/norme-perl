#!/usr/bin/perl -w
## norme.pl for norme in /home/vink/projet/perso/norme
##
## Made by kevin platel
## Login   <platel_k@epitech.net>
##
## Started on  Sun Oct 28 06:03:58 2012 kevin platel
## Last update Fri Nov  2 16:24:16 2012 kevin platel
##

#-----------------
# Use

use strict;
use warnings;

#------------------
# Code
#__________________
# Main
my @l;
my $is_in_func = 0;
my $color = 0;
my @files;
our @user;
our $note = 0;
our @error;
our @error_file;
our @error_line;
my $user = $ENV{USER};

die ("You need to give one file in parameter.\n") if ( !defined($ARGV[0]) );
foreach (@ARGV) {
    if ($_ eq "-c") {
	$color = 1;
    } elsif ($_ =~ m/\-u\=[a-zA-Z0-9,_]*/) {
	$_ =~ m/[^=][a-zA-Z0-9,_]*$/;
	@user = split(',', $&);
    } else {
	push(@files, $_)
    }
}
for (my $a=0; $a < @files; $a++) {
    open(FIC,"<".$files[$a]) or die ("open : $!.");
    @l = <FIC>;
    my $i = 0;
    my $nb_func = 0;
    analyse_header($files[$a], @l);
    foreach (@l) {
	if (is_function($_)) {
	    $nb_func++;
	    if ($nb_func > 5) {
		push(@error, "too many function in file");
		push(@error_line, -1);
		push(@error_file, $files[$a]);
		$note--;
	    }
	}
    }
    foreach (@l) {
	&analyse_line($_, $i, $files[$a]);
	if (is_function($_) && $l[$i + 1] !~ m/^\{$/) {
	    $note--;
	    push(@error, "no { after a function declaration.");
	    push(@error_line, $i);
	    push(@error_file, $files[$a]);
	}
	if (is_function($_)) {
	    $is_in_func = 1;
	    my $j = 0;
	    my $k = $i;
	    while (defined($l[$k]) && $l[$k] !~ m/^\}$/) {
		$j++;
		$k++;
	    }
	    if ($j > 25) {
		my $tot_line = $j - 25;
		$note = $note - $tot_line;
		my $f_name = function_name($_);
		push(@error, "function $f_name is more of 25 lines ($j lines).");
		push(@error_line, $i);
		push(@error_file, $files[0]);
	    }
	}
	&nb_param_of_func($_, $i, $files[$a]) if (is_function($_));
	$is_in_func = 0 if ($is_in_func && ( $_ =~ m/^}$/ ));
	&analyse_func_call($_, $i, $files[$a]) if ($is_in_func);
	&analyse_comment($_, $i, $files[$a]) if ($is_in_func);
	&analyse_keyword($_, $i, $files[$a]) if ($is_in_func);
	&analyse_variable($_, $i, $files[$a]);
	$i++;
    }
}

my $i = 0;
foreach (@error) {
    my $line = $error_line[$i] + 1;
    print "Error : $_ at line $line in file $error_file[$i].\n";
    $i++;
}
print "\nFinal note : $note\n";

#__________________
# sub function

sub analyse_header {
    if ($_[1] !~ m/\/\*\n/) {
	push(@error, "incorrect header.");
	push(@error_line, 0);
	push(@error_file, $_[0]);
	$note = $note - 20;
    }
    if ($_[2] !~ m/\*\* [a-zA-Z0-9_.]* for [a-zA-Z0-9_.]* in [a-zA-Z0-9_.\/]*\n/) {
	push(@error, "incorrect header.");
	push(@error_line, 1);
	push(@error_file, $_[0]);
	$note = $note - 20;
    }
    if ($_[3] !~ m/\*\*[ \t]*\n/) {
	push(@error, "incorrect header.");
	push(@error_line, 2);
	push(@error_file, $_[0]);
	$note = $note - 20;
    }
    if ($_[4] !~ m/\*\* Made by [a-zA-Z]* [a-zA-Z]*\n/) {
	push(@error, "incorrect header.");
	push(@error_line, 3);
	push(@error_file, $_[0]);
	$note = $note - 20;
    }
    if ($_[5] !~ m/\*\* Login   <[a-zA-Z0-9_]*\@epitech\.net>\n/) {
	push(@error, "incorrect header.");
	push(@error_line, 4);
	push(@error_file, $_[0]);
	$note = $note - 20;
    } else {
	my $legal = 0;
	my @log = split('<', $_[5]);
	@log = split('@', $log[1]);
	my $login = $log[0];
	foreach (@user) {
	    $legal = 1 if ($_ eq $login);
	}
	if ($legal == 0) {
	    push(@error, "Triche !! -42.");
	    push(@error_line, 4);
	    push(@error_file, $_[0]);
	    $note = $note - 42;
	}
    }
    if ($_[6] !~ m/\*\*[ \t]*\n/) {
	push(@error, "incorrect header.");
	push(@error_line, 5);
	push(@error_file, $_[0]);
	$note = $note - 20;
    }
    if ($_[7] !~ m/\*\* Started on  [a-zA-Z]{3} [a-zA-Z]{3} .*\n/) {
	push(@error, "incorrect header.");
	push(@error_line, 6);
	push(@error_file, $_[0]);
	$note = $note - 20;
    }
    if ($_[8] !~ m/\*\* Last update [a-zA-Z]{3} [a-zA-Z]{3} .*\n/) {
	push(@error, "incorrect header.");
	push(@error_line, 7);
	push(@error_file, $_[0]);
	$note = $note - 20;
    }
    if ($_[9] !~ m/\*\//) {
	push(@error, "incorrect header.");
	push(@error_line, 8);
	push(@error_file, $_[0]);
	$note = $note - 20;
    }
}

sub analyse_func_call {
    if ($_[0] =~ m/[a-zA-Z0-9_]*[\t ]*\(.*\)/ ) {
	my $res = $&;
	if ($res !~ m/(while|if|else if|else|return)/ ) {
	    if ($res !~ m/[a-zA-Z0-9_]*[^\t ]\(.*\)/ ) {
		push(@error, "space between function name and (");
		push(@error_line, $_[1]);
		push(@error_file, $_[2]);
		$note--;
	    }
	    if ($res =~ m/^(printf|strcpy|strdup|strcmp|strncmp)/ ) {
		push(@error, "forbiden function [$&]!");
		push(@error_line, $_[1]);
		push(@error_file, $_[2]);
		$note = $note - 42;
	    }
	}
    }
}

sub analyse_line {
    if ( $_[0] =~ m/.*;.*;.*/ ) {
	push(@error, "multiple instruction");
	push(@error_line, $_[1]);
	push(@error_file, $_[2]);
	$note--;
    }
    if (length($_[0]) > 80) {
	push(@error, "line of more than 80 columns");
	push(@error_line, $_[1]);
	push(@error_file, $_[2]);
	$note--;
    }
    if ( $_[0] =~ m/.*;[ \t]+/ ) {
	push(@error, "space at end of line");
	push(@error_line, $_[1]);
	push(@error_file, $_[2]);
	my @str = split(';', $_[0]);
	$note = $note - (length($str[@str - 1]) - 1);
    }
}

sub analyse_comment {
    if ($_[0] =~ m/(\/\/|\/\*)/ ) {
	push(@error, "comment in function");
	push(@error_line, $_[1]);
	push(@error_file, $_[2]);
	$note--;
    }
}

sub analyse_variable {
    if ($_[0] =~ m/(char|short|int|long|float|double|struct|t_.*)+[\t ]+.*;$/ ) {
	if ($_[0] !~ m/(char|short|int|long|float|double|struct|t_.*)+[\t ]+[a-zA-Z1-9_]*;$/ ) {
	    push(@error, "no right to declare and initialize variable on the same line in line $_[1] of file $_[2].");
	    push(@error_line, $_[1]);
	    push(@error_file, $_[2]);
	    $note--;
	}
	if ($_[0] =~ m/struct/ ) {
	    if ($_[0] !~ m/struct[\t ]+s_.*/) {
		push(@error, "structure declaration without s_.");
		push(@error_line, $_[1]);
		push(@error_file, $_[2]);
		$note--;
	    }
	}
	if ($_[0] =~ m/(char|short|int|long|float|double|struct|t_[a-zA-Z1-9_])\*/ ) {
	    print "\nError * on type\n"
	}
    }
}

sub analyse_keyword {
    if ( $_[0] =~ m/(while|if|if else)/ ) {
	if ( $_[0] !~ m/(while|if|if else) \(.*\)/ ) {
	    push(@error, "space after keyword");
	    push(@error_line, $_[1]);
	    push(@error_file, $_[2]);
	    $note--;
	}
	elsif ($_[0] =~ m/while/) {
	    if ($_[0] !~ m/while \(.*\);?$/) {
		push(@error, "no space after keyword");
		push(@error_line, $_[1]);
		push(@error_file, $_[2]);
		$note--;
	    }
	}
	elsif ($_[0] !~ m/(if|if else) \(.*\)$/) {
	    push(@error, "condition on one line  in line $_[1] of file $_[2].");
	    push(@error_line, $_[1]);
	    push(@error_file, $_[2]);
	    $note--;
	}
    }
    if ( $_[0] =~ m/[^a-zA-Z1-9_](for|switch|goto|do)[^a-zA-Z1-9_]/ ) {
	push(@error, "use a forbiden keyword");
	push(@error_line, $_[1]);
	push(@error_file, $_[2]);
	$note--;
    }
    if ($_[0] =~ m/(return|else)/ ) {
	if ( $_[0] =~ m/return/ ) {
	    if ($_[0] !~ m/return \(.*\);$/) {
		push(@error, "no space after keyword");
		push(@error_line, $_[1]);
		push(@error_file, $_[2]);
		$note--;
	    }
	}
	else {
	    if ( $_[0] !~ m/else$/ ) {
		push(@error, "condition on one line");
		push(@error_line, $_[1]);
		push(@error_file, $_[2]);
		$note--;
	    }
	}
    }
}

sub is_function {
    if ( $_[0] =~ m/^(char|short|int|long|float|double|struct|void)([\t| ])+(.*)\((.*,?)\)$/ ) {
	return (1);
    }
    return (0);
}

sub function_name {
    if ( $_[0] =~ m/^(char|short|int|long|float|double|struct|void|static)([\t| ])+(.*)\((.*,?)\)$/ ) {
	return ($3);
    }
    return ($3);
}

sub param_func {
   if ( $_[0] =~ m/^(char|short|int|long|float|double|struct|void|static)([\t| ])+(.*)\((.*,?)\)$/ ) {
	return ($4);
    }
    return ($4);
}

sub nb_param_of_func {
    my @param = split(',', param_func($_[0]));
    my $f_name = function_name($_[0]);
    my $i = 0;
    $i++ foreach (@param);
    if ($i > 4) {
	push(@error, "too many param in function $f_name");
	push(@error_line, $_[1]);
	push(@error_file, $_[2]);
	$note--;
    }
}
#========
# End
