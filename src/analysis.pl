#!/usr/bin/perl
# Author AAli

# Use UTF-8 encoding, the CGI library for HTML and LWP for URL parsing 
use  CGI qw(-utf-8 :all *table);
use LWP::Simple qw(get);
binmode(STDOUT , ":encoding(utf-8)");

print  header(-charset=>'utf-8'), "\n",
        start_html ({-title=>'Code Analysis',
        -author=>'u6aa'});

if ((! defined(param('url'))) ) {
    # This  branch  is  executed  if the  user  first  visits  this  page/script
    print  start_form ({-method=>"POST"});
    
    print  label('Input URL here: ', 
        textfield ({-name=>'url', -value=>'',
        -size =>200})), "\n";
    print br(), "\n";
    
    print  label('Or input the code directly here: ', 
        textarea ({-name=>'code',
        -value=>''})), "\n";
    print br(), "\n";
    
    print  submit({-name=>'submit',
        -value=>'Submit '}), "\n";
    print  end_form;
} else  {
    # This  branch  is  executed  if the  client  request  is  generated
    # by the  form
    
    # Check to see if user has not inputted anything and if so, print message and link back
    # Else if the user inputted values for both fields, print error and link back again
    # Else carry on with the execution
    if (length(param('url')) == 0 && length(param('code')) == 0)  {
        print p('Enter either a valid URL or the code directly before submitting'), "\n";
        print a({href=>'analysis.pl'}, 'Click here to go back'); 
    } elsif (length(param('url')) > 0 && length(param('code')) > 0) {
        print p('Enter only one of the fields'), "\n";
        print a({href=>'analysis.pl'}, 'Click here to go back'); 
    } else {
        
        # Variable for storing the inputted/linked code
        my $string;
        # If the user is using a URL, print the URL as well as assign the content
        # The printed URL will not link to anything as it is escaped
        # Else set the code directly inputted by the user as the variable
        if (length(param('url')) > 1) {
            print p(escapeHTML(param('url')));
            $string = get(param('url'));
        } else {
            $string = param('code');   
        }

        # Assign the code to a new variable after replacing the newline character for
        # an HTML compatible one
        # Print to a paragraph and preserve the whitespaces
        (my $htmlString = $string) =~ s/\n/<br>/g;
        print p(pre("$htmlString"));
        
        # Assign the code to a new variable and remove the comment code
        # Regex for substituting the comment elements (/* */, //, #) and their content
        # with an empty line 
        # Uses noncapturing groups and alternations for the different type of comment
        (my $instrucString = $string) =~ 
            s/((?:\/\*(?:[^*]|(?:\*+[^*\/]))*\*+\/)|(?:\/\/.*)|(?:\#.*))//g;
        
        # Assign the comment code from the original code to a new variable
        # Modified version of the Regex above that takes only the comment lines with content
        my $commentString = $string;
        $commentString =~ 
            /((?:\/\*(?:[^*]|(?:\*+[^*\/]))*(?:\w+\W)+\*+\/)|(?:\/\/.*(?:\w+\W)+)|(?:\#.*(?:\w+\W)+))/;
        $commentString =$&;
        

        # Print the table that will be used for formatting
        print  start_table ({-border=>1});
        print  caption("Code Analysis");
       

        # Counting
        # Apply regular expressions to each of the strings above based on the scenario
        # to get the required count (scenario written under)
        # Stores the results in a list context and print the scalar (number of elements)
        # as the count
        
        # Regex for lines that contain at least 1  word character
        my @numOfInstruc = $instrucString =~  /\w+.*\n/g;
        print  Tr(td('Number of lines of instruction: '),td(scalar @numOfInstruc));
        
        # Regex for the number of words
        my @numOfElements = $instrucString =~ /\w+\b\W/g;
        print  Tr(td('Number of elements of instruction: '),td(scalar @numOfElements));
        
        # Regex for lines with content
        my @numOfLines = $string  =~ /.+\n/g;
        print  Tr(td('Number of non-empty lines of comment (only ones at starting line): '),
            td((scalar @numOfLines) - (scalar @numOfInstruc)));
       
        # Regex for finding lines with at least 5 words
        my @numOfNonTrivComments = $commentString =~ /(?:.*\w+\b\W){5,}+.*\n/g; 
        print  Tr(td('Number of non-trivial comments (only ones at starting line): '),
            td(scalar @numOfNonTrivComments));
        
        # Regex for finding words
        my @numOfWordsInComments = $commentString =~ /\w+\b\W/g;
        print  Tr(td('Number of words of comment (only ones at starting line): '),
            td(scalar @numOfWordsInComments));
       
        # Ratios
        # Calculate the ratio from the values above and use "sprintf" to print to 1 d.p.
        my $ratioCommentToInstruc = ((scalar @numOfLines) - scalar @numOfInstruc ) / 
            (scalar @numOfInstruc);
        print  Tr(td('Ratio of lines of comment to lines of instruction: '),
            td(sprintf("%.1f", $ratioCommentToInstruc)));
        
        my $ratioNonTrivCommentToInstruc = (scalar @numOfNonTrivComments) / 
            (scalar @numOfInstruc);
        print  Tr(td('Ratio of non-trivial comments to lines of instruction: '),
            td(sprintf("%.1f", $ratioNonTrivCommentToInstruc)));
        
        my $ratioWordsToElement = (scalar @numOfWordsInComments) / 
            (scalar @numOfElements);
        print  Tr(td('Ratio of words of comment to elements of instruction: ')
            ,td(sprintf("%.1f", $ratioWordsToElement)));
    }
    print  end_table;
}
print  end_html;
