# ================================================================
package DateTime::Format::CLDR;
# ================================================================
use strict;
use warnings;
use utf8;

use Carp;

use DateTime;
use DateTime::Locale 0.4000;
use DateTime::TimeZone;
use Params::Validate qw( validate SCALAR BOOLEAN OBJECT CODEREF );

our $VERSION = '1.01';

our %PARTS = (
    year_long   => qr/(\d{4})/o,
    year_short  => qr/(\d{1,2})/o,
    day_month   => qr/(3[01]|[12]\d|[1-9])/o,
    day_year    => qr/([1-3]\d\d|[1-9]\d|[1-9])/o,
    day_week    => qr/[1-7]/o,
    month       => qr/(1[0-2]|[1-9])/o,
    hour_23     => qr/(2[0-4]|1\d|\d)/o,
    hour_24     => qr/(2[0-3]|1?\d)/o,
    hour_12     => qr/(1[0-2]|[1-9])/o,
    hour_11     => qr/(1[01]|\d)/o,
    minute      => qr/([1-5]?\d)/o,
    second      => qr/(6[01]|[1-5]?\d)/o,
    quarter     => qr/([1-4])/o,
    week_year   => qr/(5[0-3]|[1-4]\d|[1-9])/o,
    week_month  => qr/\d/o,
    timezone    => qr/[+-](1[0-4]|0\d)(00|15|30|45)/o,
    number      => qr/\d+/o,
    timezone2   => qr/([A-Z1-9a-z])([+-](1[0-4]|0\d)(00|15|30|45))/o,
);

our %ZONEMAP = (
     'A' => '+0100',       'ACDT' => '+1030',       'ACST' => '+0930',
   'ADT' => 'Ambiguous',   'AEDT' => '+1100',        'AES' => '+1000',
  'AEST' => '+1000',        'AFT' => '+0430',       'AHDT' => '-0900',
  'AHST' => '-1000',       'AKDT' => '-0800',       'AKST' => '-0900',
  'AMST' => '+0400',        'AMT' => '+0400',      'ANAST' => '+1300',
  'ANAT' => '+1200',        'ART' => '-0300',        'AST' => 'Ambiguous',
    'AT' => '-0100',       'AWST' => '+0800',      'AZOST' => '+0000',
  'AZOT' => '-0100',       'AZST' => '+0500',        'AZT' => '+0400',
     'B' => '+0200',       'BADT' => '+0400',        'BAT' => '+0600',
  'BDST' => '+0200',        'BDT' => '+0600',        'BET' => '-1100',
   'BNT' => '+0800',       'BORT' => '+0800',        'BOT' => '-0400',
   'BRA' => '-0300',        'BST' => 'Ambiguous',     'BT' => 'Ambiguous',
   'BTT' => '+0600',          'C' => '+0300',       'CAST' => '+0930',
   'CAT' => 'Ambiguous',    'CCT' => 'Ambiguous',    'CDT' => 'Ambiguous',
  'CEST' => '+0200',        'CET' => '+0100',     'CETDST' => '+0200',
 'CHADT' => '+1345',      'CHAST' => '+1245',        'CKT' => '-1000',
  'CLST' => '-0300',        'CLT' => '-0400',        'COT' => '-0500',
   'CST' => 'Ambiguous',   'CSuT' => '+1030',        'CUT' => '+0000',
   'CVT' => '-0100',        'CXT' => '+0700',       'ChST' => '+1000',
     'D' => '+0400',       'DAVT' => '+0700',       'DDUT' => '+1000',
   'DNT' => '+0100',        'DST' => '+0200',          'E' => '+0500',
 'EASST' => '-0500',       'EAST' => 'Ambiguous',    'EAT' => '+0300',
   'ECT' => 'Ambiguous',    'EDT' => 'Ambiguous',   'EEST' => '+0300',
   'EET' => '+0200',     'EETDST' => '+0300',       'EGST' => '+0000',
   'EGT' => '-0100',        'EMT' => '+0100',        'EST' => 'Ambiguous',
  'ESuT' => '+1100',          'F' => '+0600',        'FDT' => 'Ambiguous',
  'FJST' => '+1300',        'FJT' => '+1200',       'FKST' => '-0300',
   'FKT' => '-0400',        'FST' => 'Ambiguous',    'FWT' => '+0100',
     'G' => '+0700',       'GALT' => '-0600',       'GAMT' => '-0900',
  'GEST' => '+0500',        'GET' => '+0400',        'GFT' => '-0300',
  'GILT' => '+1200',        'GMT' => '+0000',        'GST' => 'Ambiguous',
    'GT' => '+0000',        'GYT' => '-0400',         'GZ' => '+0000',
     'H' => '+0800',        'HAA' => '-0300',        'HAC' => '-0500',
   'HAE' => '-0400',        'HAP' => '-0700',        'HAR' => '-0600',
   'HAT' => '-0230',        'HAY' => '-0800',        'HDT' => '-0930',
   'HFE' => '+0200',        'HFH' => '+0100',         'HG' => '+0000',
   'HKT' => '+0800',         'HL' => 'local',        'HNA' => '-0400',
   'HNC' => '-0600',        'HNE' => '-0500',        'HNP' => '-0800',
   'HNR' => '-0700',        'HNT' => '-0330',        'HNY' => '-0900',
   'HOE' => '+0100',        'HST' => '-1000',          'I' => '+0900',
   'ICT' => '+0700',       'IDLE' => '+1200',       'IDLW' => '-1200',
   'IDT' => 'Ambiguous',    'IOT' => '+0500',       'IRDT' => '+0430',
 'IRKST' => '+0900',       'IRKT' => '+0800',       'IRST' => '+0430',
   'IRT' => '+0330',        'IST' => 'Ambiguous',     'IT' => '+0330',
   'ITA' => '+0100',       'JAVT' => '+0700',       'JAYT' => '+0900',
   'JST' => '+0900',         'JT' => '+0700',          'K' => '+1000',
   'KDT' => '+1000',       'KGST' => '+0600',        'KGT' => '+0500',
  'KOST' => '+1200',      'KRAST' => '+0800',       'KRAT' => '+0700',
   'KST' => '+0900',          'L' => '+1100',       'LHDT' => '+1100',
  'LHST' => '+1030',       'LIGT' => '+1000',       'LINT' => '+1400',
   'LKT' => '+0600',        'LST' => 'local',         'LT' => 'local',
     'M' => '+1200',      'MAGST' => '+1200',       'MAGT' => '+1100',
   'MAL' => '+0800',       'MART' => '-0930',        'MAT' => '+0300',
  'MAWT' => '+0600',        'MDT' => '-0600',        'MED' => '+0200',
 'MEDST' => '+0200',       'MEST' => '+0200',       'MESZ' => '+0200',
   'MET' => 'Ambiguous',   'MEWT' => '+0100',        'MEX' => '-0600',
   'MEZ' => '+0100',        'MHT' => '+1200',        'MMT' => '+0630',
   'MPT' => '+1000',        'MSD' => '+0400',        'MSK' => '+0300',
  'MSKS' => '+0400',        'MST' => '-0700',         'MT' => '+0830',
   'MUT' => '+0400',        'MVT' => '+0500',        'MYT' => '+0800',
     'N' => '-0100',        'NCT' => '+1100',        'NDT' => '-0230',
   'NFT' => 'Ambiguous',    'NOR' => '+0100',      'NOVST' => '+0700',
  'NOVT' => '+0600',        'NPT' => '+0545',        'NRT' => '+1200',
   'NST' => 'Ambiguous',   'NSUT' => '+0630',         'NT' => '-1100',
   'NUT' => '-1100',       'NZDT' => '+1300',       'NZST' => '+1200',
   'NZT' => '+1200',          'O' => '-0200',       'OESZ' => '+0300',
   'OEZ' => '+0200',      'OMSST' => '+0700',       'OMST' => '+0600',
    'OZ' => 'local',          'P' => '-0300',        'PDT' => '-0700',
   'PET' => '-0500',      'PETST' => '+1300',       'PETT' => '+1200',
   'PGT' => '+1000',       'PHOT' => '+1300',        'PHT' => '+0800',
   'PKT' => '+0500',       'PMDT' => '-0200',        'PMT' => '-0300',
   'PNT' => '-0830',       'PONT' => '+1100',        'PST' => 'Ambiguous',
   'PWT' => '+0900',       'PYST' => '-0300',        'PYT' => '-0400',
     'Q' => '-0400',          'R' => '-0500',        'R1T' => '+0200',
   'R2T' => '+0300',        'RET' => '+0400',        'ROK' => '+0900',
     'S' => '-0600',       'SADT' => '+1030',       'SAST' => 'Ambiguous',
   'SBT' => '+1100',        'SCT' => '+0400',        'SET' => '+0100',
   'SGT' => '+0800',        'SRT' => '-0300',        'SST' => 'Ambiguous',
   'SWT' => '+0100',          'T' => '-0700',        'TFT' => '+0500',
   'THA' => '+0700',       'THAT' => '-1000',        'TJT' => '+0500',
   'TKT' => '-1000',        'TMT' => '+0500',        'TOT' => '+1300',
  'TRUT' => '+1000',        'TST' => '+0300',        'TUC' => '+0000',
   'TVT' => '+1200',          'U' => '-0800',      'ULAST' => '+0900',
  'ULAT' => '+0800',       'USZ1' => '+0200',      'USZ1S' => '+0300',
  'USZ3' => '+0400',      'USZ3S' => '+0500',       'USZ4' => '+0500',
 'USZ4S' => '+0600',       'USZ5' => '+0600',      'USZ5S' => '+0700',
  'USZ6' => '+0700',      'USZ6S' => '+0800',       'USZ7' => '+0800',
 'USZ7S' => '+0900',       'USZ8' => '+0900',      'USZ8S' => '+1000',
  'USZ9' => '+1000',      'USZ9S' => '+1100',        'UTZ' => '-0300',
   'UYT' => '-0300',       'UZ10' => '+1100',      'UZ10S' => '+1200',
  'UZ11' => '+1200',      'UZ11S' => '+1300',       'UZ12' => '+1200',
 'UZ12S' => '+1300',        'UZT' => '+0500',          'V' => '-0900',
   'VET' => '-0400',      'VLAST' => '+1100',       'VLAT' => '+1000',
   'VTZ' => '-0200',        'VUT' => '+1100',          'W' => '-1000',
  'WAKT' => '+1200',       'WAST' => 'Ambiguous',    'WAT' => '+0100',
  'WEST' => '+0100',       'WESZ' => '+0100',        'WET' => '+0000',
'WETDST' => '+0100',        'WEZ' => '+0000',        'WFT' => '+1200',
  'WGST' => '-0200',        'WGT' => '-0300',        'WIB' => '+0700',
   'WIT' => '+0900',       'WITA' => '+0800',        'WST' => 'Ambiguous',
   'WTZ' => '-0100',        'WUT' => '+0100',          'X' => '-1100',
     'Y' => '-1200',      'YAKST' => '+1000',       'YAKT' => '+0900',
  'YAPT' => '+1000',        'YDT' => '-0800',      'YEKST' => '+0600',
  'YEKT' => '+0500',        'YST' => '-0900',          'Z' => '+0000',
'floating'=> 'Ambiguous',
'UTC'    => '+0000',
);

our %PARSER = (
    G1      => 'era_abbreviated',
    G3      => 'era_wide',
    G5      => 'era_narrow',
    y1      => $PARTS{year_long},
    y2      => $PARTS{year_short},
    y3      => $PARTS{year_long},
    Y1      => $PARTS{year_long},
    u1      => $PARTS{year_long},
    Q1      => $PARTS{quarter},
    Q3      => 'quarter_format_abbreviated',
    Q4      => 'quarter_format_wide',
    q1      => $PARTS{quarter},
    q3      => 'quarter_stand_alone_abbreviated',
    q4      => 'quarter_stand_alone_wide',
    M1      => $PARTS{month},
    M3      => 'month_format_abbreviated',
    M4      => 'month_format_wide',
    M5      => 'month_format_narrow',
    L1      => $PARTS{month},
    L3      => 'month_stand_alone_abbreviated',
    L4      => 'month_stand_alone_wide',
    L5      => 'month_stand_alone_narrow',
    w1      => $PARTS{week_year},
    W1      => $PARTS{week_month},
    d1      => $PARTS{day_month},
    D1      => $PARTS{day_year},
    E1      => 'day_format_abbreviated',
    E4      => 'day_format_wide',
    E5      => 'day_format_narrow',
    e1      => $PARTS{day_week},
    e3      => 'day_format_abbreviated',
    e4      => 'day_format_wide',
    e5      => 'day_format_narrow',
    c1      => $PARTS{day_week},
    c3      => 'day_stand_alone_abbreviated',
    c4      => 'day_stand_alone_wide',
    a1      => 'am_pm_abbreviated',
    h1      => $PARTS{hour_12},
    H1      => $PARTS{hour_23},
    K1      => $PARTS{hour_11},
    k1      => $PARTS{hour_24},
    m1      => $PARTS{minute},
    s1      => $PARTS{second},
    s1      => $PARTS{second},
    Z1      => $PARTS{timezone},
    Z4      => $PARTS{timezone2},
    z1      => [ keys %ZONEMAP ],
    z4      => [ DateTime::TimeZone->all_names ],
    v1      => [ keys %ZONEMAP ],
    v4      => [ DateTime::TimeZone->all_names ],
    V1      => [ keys %ZONEMAP ],
    V4      => [ DateTime::TimeZone->all_names ],
);

=encoding utf8

=head1 NAME

DateTime::Format::CLDR - Parse and format CLDR time patterns

=head1 SYNOPSIS

    use DateTime::Format::CLDR;
    
    my $cldr = new DateTime::Format::CLDR(
        pattern     => '%T',
        locale      => 'de_AT',
        time_zone   => 'Europe/Vienna',
    );
    
    my $dt = $cldr->parse_datetime('23:16:42');
    
    # Get pattern from selected locale
    my $cldr = new DateTime::Format::CLDR(
        locale      => 'de_AT',
    );
    
    my $dt = $cldr->parse_datetime('23:16:42');

=head1 DESCRIPTION

This module provides a parser (and also a formater) for datetime strings
using patterns as defined by the Unicode CLDR Project 
(Common Locale Data Repository). L<http://unicode.org/cldr/>. 

=head1 METHODS

=head2 Constructor

=head3 new

 DateTime::Format::CLDR->new(%PARAMS);

The following parameters are used by DateTime::Format::CLDR:

=over

=item * locale

Locale.

=item * pattern (optional)

CLDR pattern. See L<DateTime/"CLDR Patterns"> for details. If you don't provide
a pattern the C<date_format_medium> pattern from L<DateTime::Local> for
the selected locale will be used.

=item * time_zone (optional)

Timezone that should be used. The time_zone parameter can be either a scalar 
or a C<DateTime::TimeZone> object. A string will simply be passed to the 
C<DateTime::TimeZone->new> method as its "name" parameter. 

=back

=cut

sub new {
    my $class = shift;
    my %args = validate( @_, {  
        pattern     => { type => SCALAR, optional => 1  },
        time_zone   => { type => SCALAR | OBJECT, optional => 1 },
        locale      => { type => SCALAR | OBJECT, default => 'en' },
        }
    );
   
    my $self = bless \%args, $class;
    
    $args{time_zone} ||= DateTime::TimeZone->new( name => 'floating' );
    $self->time_zone($args{time_zone});
    
    $self->locale($args{locale});
    
    $args{pattern} ||= $self->locale->date_format_medium;
    $self->pattern($args{pattern});
    
    return $self;
}

=head2 Accessors

=head3 pattern

Get/set pattern. 

=cut

sub pattern {
    my $self = shift;
    my $pattern = shift;
    
    # Set pattern
    if ($pattern) {
        $self->{pattern} = $pattern;
        undef $self->{_built_pattern};
    }
    
    return $self->{pattern};
}

=head3 time_zone

Get/set time_zone. Returns a C<DateTime::TimeZone> object.

=cut

sub time_zone {
    my $self = shift;
    my $time_zone = shift;
    
    # Set timezone
    if ($time_zone) {
        if (ref $time_zone
            && $time_zone->isa('DateTime::TimeZone')) {
            $self->{time_zone} = $time_zone;
        } else {
            $self->{time_zone} = DateTime::TimeZone->new( name => $time_zone )
                or croak("Could not create timezone from $time_zone");
        }  
    }
    
    return $self->{time_zone};
}

=head3 locale

Get/set locale. Returns a C<DateTime::Locale> object.

=cut

sub locale {
    my $self = shift;
    my $locale = shift;
    
    # Set locale
    if ($locale) {
        unless (ref $locale
            && $locale->isa('DateTime::Locale::Base')) {
            $self->{locale} = DateTime::Locale->load( $locale )
                or croak("Could not create locale from $locale");
        } else {
            $self->{locale} = $locale;
        }  
        undef $self->{_built_pattern};
    }
    
    return $self->{locale};
}

=head2 Public Methods

=head3 parse_datetime

 my $datetime = $cldr->parse_datetime($string);

Parses a string and returns a C<DateTime> object on success. If the string
cannot be parsed with the given pattern C<undef> is returned.

=cut

sub parse_datetime {
    my ( $self, $string ) = @_;
    
    my $pattern = $self->_build_pattern();

    my $datetime_initial = $string;
    my %datetime_info = ();
    my %datetime_check = ();
    
    # Set default datetime values
    my %datetime = (
        hour        => 0,
        minute      => 0,
        second      => 0,
        time_zone   => $self->{time_zone},
        locale      => $self->{locale},
        nanosecond  => 0,
    );
    
    foreach my $part (@{$pattern}) {
        
        # Pattern
        if (ref $part eq 'ARRAY') {
            my ($regexp,$command,$index) = @{$part};
            return undef
                unless ($string =~ s/\s* $regexp \s*//ix);
            
            my $capture = $1;
            
            # Pattern is a list: get index instead of value
            if (grep { $command.$index eq $_ } 
                qw(G1 G3 G5 Q3 Q4 q3 q4 M3 M4 M5 L3 L4 L5 E1 E4 E5 e3 e4 e5 c3 c4 a1 )) {
                my $function = $PARSER{$command.$index};
                my $count = 1;
                foreach my $element (@{$self->{locale}->$function}) {
                    if ($element eq $capture) {
                        $capture = $count;
                        last;
                    }
                    $count ++;
                }
            }
            
            # simple pattern
            if ($command eq 'G' ) {
                $datetime_check{era_name} = $capture;
            } elsif ($command eq 'y' && $index == 2) {
                $datetime{year} = $capture;
                if ($datetime{year} >= 70) {
                    $datetime{year} += 1900;
                } else {
                    $datetime{year} += 2000;
                }
            } elsif ($command eq 'y' ) {
                $datetime{year} = $capture;
            } elsif ($command eq 'Q' || $command eq 'q') {
                $datetime_check{quarter} = $capture; 
            } elsif ($command eq 'M' || $command eq 'L') {
                $datetime{month} = $capture; 
            } elsif ($command eq 'w') {
                $datetime_check{week_number} = $capture;
            } elsif ($command eq 'W') {
                $datetime_check{week_of_month} = $capture;
            } elsif ($command eq 'd') {
                $datetime{day} = $capture;
            } elsif ($command eq 'D') {
                $datetime_check{day_of_year} = $capture;
            } elsif ($command eq 'E' || $command eq 'e' || $command eq 'c') {   
                $datetime_check{day_of_week} = $capture;
            } elsif ($command eq 'a' ) {     
                $datetime_info{ampm} = $capture;
            } elsif ($command eq 'h') { # 1-12
                $datetime_info{hour12} = $capture;
            } elsif ($command eq 'K') { # 0-11
                $datetime_info{hour12} = $capture+1;
            } elsif ($command eq 'H') { # 0-23
                $datetime{hour} = $capture;
            } elsif ($command eq 'k') { # 1-24
                $datetime{hour} = $capture - 1;
            } elsif ($command eq 'm') {
                $datetime{minute} = $capture;
            } elsif ($command eq 's') {
                $datetime{second} = $capture;
            } elsif ($command eq 'Z') {
                if ($index >= 4) {
                    $capture = $3;
                }
                $datetime{time_zone} = DateTime::TimeZone->new(name => $capture);
            } elsif (($command eq 'z' || $command eq 'v' || $command eq 'V') && $index == 1) {
                if (! defined $ZONEMAP{$capture} 
                    || $ZONEMAP{$capture} eq 'Ambiguous') {
                    warn ("Ambiguous timezone: $capture $command");
                    next;
                }
                $datetime{time_zone} = DateTime::TimeZone->new(name => $ZONEMAP{$capture});
            } elsif ($command eq 'z' || $command eq 'v' || $command eq 'V') {
                $datetime{time_zone} = DateTime::TimeZone->new(name => $capture);
            }
       
        # String
        } else {
           
            return undef
                unless ($string =~ s/\s
                ? $part \s?//ix);
        }
    }
    
    if (defined $datetime_info{hour12} 
        && defined $datetime_info{ampm}) {
        $datetime{hour} = $datetime_info{hour12};
        $datetime{hour} += 12
            if $datetime_info{ampm} == 2 && $datetime{hour} < 12;
    }
    
    my $dt;
    
    eval {
        $dt = DateTime->new(%datetime);
    };
    return undef if $@;
    
    foreach my $check ( keys %datetime_check ) {
        warn ("Datetime '$check' does not match ($datetime_check{$check} - ".$dt->$check.") for $datetime_initial")
            unless $dt->$check == $datetime_check{$check};
    }
    

    return $dt;
}

=head3 format_datetime

 my $string = $cldr->format_datetime($datetime);

Formats a C<DateTime> object using the set time_zone, locale and pattern.

=cut

sub format_datetime {
    my ( $self, $dt ) = @_;
    my $pattern = $self->{pattern};
    return $dt->format_cldr($pattern);
}

sub _build_pattern {
    my $self = shift;
    
    # Return cached pattern
    return $self->{_built_pattern}
        if defined $self->{_built_pattern};
       
    $self->{_built_pattern} = [];
    
    while ($self->{pattern} =~ m/\G
        (?:
            '((?:[^']|'')*)' # quote escaped bit of text
                           # it needs to end with one
                           # quote not followed by
                           # another
            |
            (([a-zA-Z])\3*)  # could be a pattern
            |
            (.)              # anything else
        )
        /sxg) {
        my ($string,$pattern,$rest) = ($1,$2,$4);
        
        # Quoted string
        if ($string) {
            $string =~ s/\'\'/\'/g;
            push @{$self->{_built_pattern}}, "\Q".$string."\E";
            
        # Pattern
        } elsif ($pattern) {
            my $length = length $pattern;
            my $command = substr $pattern,0,1;
            my ($rule,$regexp,$index);
            for (my $count = $length; $count > 0; $count --) {
                if (defined $PARSER{$command.$count}) {
                    $rule = $PARSER{$command.$count};
                    $index = $count;
                    last;
                }
            }
            die("Broken pattern: $command $length")
                unless $rule ;
            
            # Regular expression
            if (ref $rule eq 'Regexp') {
                $regexp =  '0*'.$rule;
            
            # Array of possible values
            } elsif (ref $rule eq 'ARRAY') {
                
                $regexp = '('.(join '|',map {
                    "\Q".$_."\E";
                } sort { length $b <=> length $a } @{$rule}).')';
                
            # DateTime::Locale method (returning an array)
            } else {
                $regexp = '('.(join '|',map {
                    "\Q".$_."\E";
                } sort { length $b <=> length $a } @{$self->{locale}->$rule()}).')';
            }
            
            push @{$self->{_built_pattern}},[$regexp,$command,$index];
            
        # Unqoted string
        } elsif ($rest) {
            $rest =~ s/\'\'/\'/g;
            push @{$self->{_built_pattern}}, "\Q".$rest."\E";
        }
    }
    
    return $self->{_built_pattern};
}
#
#sub _build_timezone {
#    my $regexp =  $PARTS{timezone}.
#        '('.(join '|',map {
#        "\Q".$_."\E";
#        } sort { length $b <=> length $a } keys %ZONEMAP).')';
#    return qr/$regexp/o;
#}


1;

=head1 CLDR PATTERNS

See L<DateTime/"CLDR Patterns">.

CLDR provides the following pattenrs:

=over 4

=item * G{1,3}

The abbreviated era (BC, AD).

Not used to construct a date.

=item * GGGG

The wide era (Before Christ, Anno Domini).

Not used to construct a date.

=item * GGGGG

The narrow era, if it exists (and it mostly doesn't).

Not used to construct a date.

=item * y and y{3,}

The year, zero-prefixed as needed.

=item * yy

This is a special case. It always produces a two-digit year, so "1976"
becomes "76".

=item * Y{1,}

The week of the year, from C<< $dt->week_year() >>.

=item * u{1,}

Same as "y" except that "uu" is not a special case.

=item * Q{1,2}

The quarter as a number (1..4).

=item * QQQ

The abbreviated format form for the quarter.

=item * QQQQ

The wide format form for the quarter.

=item * q{1,2}

The quarter as a number (1..4).

=item * qqq

The abbreviated stand-alone form for the quarter.

=item * qqqq

The wide stand-alone form for the quarter.

=item * M{1,2}

The numerical month.

=item * MMM

The abbreviated format form for the month.

=item * MMMM

The wide format form for the month.

=item * MMMMM

The narrow format form for the month.

=item * L{1,2}

The numerical month.

=item * LLL

The abbreviated stand-alone form for the month.

=item * LLLL

The wide stand-alone form for the month.

=item * LLLLL

The narrow stand-alone form for the month.

=item * w{1,2}

The week of the year, from C<< $dt->week_number() >>.

Not used to construct a date.

=item * W

The week of the month, from C<< $dt->week_of_month() >>.

Not used to construct a date.

=item * d{1,2}

The numeric day of of the month.

=item * D{1,3}

The numeric day of of the year.

Not used to construct a date.

=item * F

The day of the week in the month, from C<< $dt->weekday_of_month() >>.

=item * g{1,}

The modified Julian day, from C<< $dt->mjd() >>.

=item * E{1,3}

The abbreviated format form for the day of the week.

=item * EEEE

The wide format form for the day of the week.

=item * EEEEE

The narrow format form for the day of the week.

=item * e{1,2}

The I<local> day of the week, from 1 to 7. This number depends on what
day is considered the first day of the week, which varies by
locale. For example, in the US, Sunday is the first day of the week,
so this returns 2 for Monday.

=item * eee

The abbreviated format form for the day of the week.

=item * eeee

The wide format form for the day of the week.

=item * eeeee

The narrow format form for the day of the week.

=item * c

The numeric day of the week (not localized).

=item * ccc

The abbreviated stand-alone form for the day of the week.

=item * cccc

The wide stand-alone form for the day of the week.

=item * ccccc

The narrow format form for the day of the week.

=item * a

The localized form of AM or PM for the time.

=item * h{1,2}

The hour from 1-12.

=item * H{1,2}

The hour from 0-23.

=item * K{1,2}

The hour from 0-11.

=item * k{1,2}

The hour from 1-24.

=item * j{1,2}

The hour, in 12 or 24 hour form, based on the preferred form for the
locale. In other words, this is equivalent to either "h{1,2}" or
"H{1,2}".

=item * m{1,2}

The minute.

=item * s{1,2}

The second.

=item * S{1,}

Not supported by DateTime::Format::CLDR

=item * A{1,}

Not supported by DateTime::Format::CLDR

=item * z{1,3}

The time zone short name.

=item * zzzz

The time zone long name.

=item * Z{1,3}

The time zone short name and the offset as one string, so something
like "CDT-0500".

=item * ZZZZ

The time zone long name.

=item * v{1,3}

The time zone short name.

=item * vvvv

The time zone long name.

=item * V{1,3}

The time zone short name.

=item * VVVV

The time zone long name.

=back


=head1 SUPPORT

Please report any bugs or feature requests to 
C<datetime-format-cldr@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=DateTime::Format::CLDR>.
I will be notified and then you'll automatically be notified of the progress 
on your report as I make changes.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.revdev.at>

=head1 ACKNOWLEDGEMENTS 

This module was written for Revdev L<http://www.revdev.at>, a nice litte
software company I run with Koki and Domm (L<http://search.cpan.org/~domm/>).

=head1 COPYRIGHT

DateTime::Format::CLDR is Copyright (c) 2008 Maroš Kollár 
- L<http://www.revdev.at>

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

datetime@perl.org mailing list

L<http://datetime.perl.org/>

L<DateTime>, L<DateTime::Locale>, L<DateTime::TimeZone>

=cut