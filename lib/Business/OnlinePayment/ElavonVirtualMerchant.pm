package Business::OnlinePayment::ElavonVirtualMerchant;
use base qw(Business::OnlinePayment::viaKLIX);

use strict;
use warnings;
use vars qw( $VERSION %maxlength );

use XML::Fast;

$VERSION = '0.04';
$VERSION = eval $VERSION;

=head1 NAME

Business::OnlinePayment::ElavonVirtualMerchant - Elavon Virtual Merchant backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment::ElavonVirtualMerchant;

  my $tx = new Business::OnlinePayment("ElavonVirtualMerchant", { default_ssl_userid => 'whatever' });
    $tx->content(
        type           => 'VISA',
        login          => 'testdrive',
        password       => '', #password or transaction key
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        customer_id    => 'jsk',
        first_name     => 'Jason',
        last_name      => 'Kohles',
        address        => '123 Anystreet',
        city           => 'Anywhere',
        state          => 'UT',
        zip            => '84058',
        card_number    => '4007000000027',
        expiration     => '09/02',
        cvv2           => '1234', #optional
    );
    $tx->submit();

    if($tx->is_success()) {
        print "Card processed successfully: ".$tx->authorization."\n";
    } else {
        print "Card was rejected: ".$tx->error_message."\n";
    }

=head1 DESCRIPTION

This module lets you use the Elavon (formerly Nova Information Systems) Virtual Merchant real-time payment gateway, a successor to viaKlix, from an application that uses the Business::OnlinePayment interface.

You need an account with Elavon.  Elavon uses a three-part set of credentials to allow you to configure multiple 'virtual terminals'.  Since Business::OnlinePayment only passes a login and password with each transaction, you must pass the third item, the user_id, to the constructor.

Elavon offers a number of transaction types, including electronic gift card operations and 'PINless debit'.  Of these, only credit card transactions fit the Business::OnlinePayment model.

Since the Virtual Merchant API is just a newer version of the viaKlix API, this module subclasses Business::OnlinePayment::viaKlix.

=head1 SUBROUTINES

=head2 set_defaults

Sets defaults for the Virtual Merchant gateway URL.

=cut

sub set_defaults {
    my $self = shift;
    my %opts = @_;

    $self->SUPER::set_defaults(%opts);
    # standard B::OP methods/data
    $self->server('www.myvirtualmerchant.com');
    $self->port('443');
    $self->path('/VirtualMerchant/processxml.do');
}

=head2 _map_fields

Converts credit card types and transaction types from the Business::OnlinePayment values to Elavon's.

=cut

sub _map_fields {
    my ($self) = @_;

    my %content = $self->content();

    #ACTION MAP
    my %actions = (
        'normal authorization' => 'CCSALE',  # Authorization/Settle transaction
        'credit'               => 'CCCREDIT', # Credit (refund)
    );

    $content{'ssl_transaction_type'} = $actions{ lc( $content{'action'} ) }
      || $content{'action'};

    # TYPE MAP
    my %types = (
        'visa'             => 'CC',
        'mastercard'       => 'CC',
        'american express' => 'CC',
        'discover'         => 'CC',
        'cc'               => 'CC',
    );

    $content{'type'} = $types{ lc( $content{'type'} ) } || $content{'type'};

    $self->transaction_type( $content{'type'} );

    # stuff it back into %content
    $self->content(%content);
}

sub _revmap_fields {
    my ( $self, %map ) = @_;
    my %content = $self->content();
    foreach ( keys %map ) {
        if ( ref( $map{$_} ) eq 'HASH' ) {
            $content{$_} = $map{$_};
        }
        elsif ( ref( $map{$_} ) eq 'ARRAY' ) {
            $content{$_} = $map{$_};
        }
        elsif ( ref( $map{$_} ) ) {
            $content{$_} = ${ $map{$_} };
        }
        else {
            $content{$_} = $content{ $map{$_} };
        }
    }
    $self->content(%content);
}

=head2 submit

Maps data from Business::OnlinePayment name space to Elavon's, checks that all required fields
for the transaction type are present, and submits the transaction.  Saves the results.

=cut

%maxlength = (
    ssl_card_number        => 19,
    ssl_cvv2cvc2           => 4,
    ssl_cvv2cvc2_indicator => 1,
    ssl_exp_date           => 4,

    ssl_amount                 => 13,
    ssl_discount_amount        => 12,
    ssl_duty_amount            => 12,
    ssl_freight_tax_amount     => 12,
    ssl_freight_tax_rate       => 4,
    ssl_shipping_amount        => 12,
    ssl_shipping_company       => 50,
    ssl_summary_commodity_code => 4,
    ssl_token                  => 20,
    ssl_tracking_number        => 25,
    ssl_transaction_type       => 20,
    ssl_user_id                => 15,

    ssl_description         => 255,
    ssl_invoice_number      => 25,
    ssl_level3_indicator    => 1,
    ssl_customer_code       => 17,
    ssl_customer_vat_number => 13,
    ssl_vat_invoice_number  => 15,

    ssl_merchant_id            => 15,
    ssl_merchant_vat_number    => 20,
    ssl_national_tax_amount    => 12,
    ssl_national_tax_indicator => 1,
    ssl_order_date             => 10,
    ssl_other_fees             => 12,
    ssl_other_tax              => 12,
    ssl_pin                    => 64,
    ssl_salestax               => 8,

    ssl_first_name  => 20,
    ssl_last_name   => 30,
    ssl_company     => 50,
    ssl_avs_address => 30,
    ssl_avs_zip     => 9,
    ssl_address2    => 30,
    ssl_city        => 30,
    ssl_state       => 2,
    ssl_phone       => 20,
    ssl_country     => 3,

    ssl_ship_from_postal_code => 10,
    ssl_ship_to_first_name    => 20,
    ssl_ship_to_last_name     => 30,
    ssl_ship_to_company       => 50,
    ssl_ship_to_address1      => 30,
    ssl_ship_to_address2      => 30,
    ssl_ship_to_city          => 30,
    ssl_ship_to_country       => 50,
    ssl_ship_to_phone         => 20,  #though we don't map anything to this...
    ssl_ship_to_state         => 2,
    ssl_ship_to_zip           => 10,
);

my %maxlength_line_item = (
    ssl_line_Item_alternative_tax    => 15,
    ssl_line_Item_commodity_code     => 12,  # they said 16
    ssl_line_item_description        => 25,  # they said 100
    ssl_line_Item_discount_indicator => 1,
    ssl_line_Item_extended_total     => 9,
    ssl_line_Item_product_code       => 12,
    ssl_line_Item_quantity           => 12,
    ssl_line_Item_tax_amount         => 12,
    ssl_line_Item_tax_indicator      => 1,
    ssl_line_Item_tax_rate           => 5,
    ssl_line_Item_total              => 12,
    ssl_line_Item_unit_cost          => 12,
    ssl_line_Item_unit_of_measure    => 2,
);

sub submit {
    my ($self) = @_;

    $self->_map_fields();

    my %content = $self->content;

    my %required;
    $required{CC_CCSALE}
        = [ qw( ssl_transaction_type ssl_merchant_id ssl_pin ssl_amount ssl_card_number ssl_exp_date ) ];
    $required{CC_CCCREDIT} = $required{CC_CCSALE};
    my %optional;
    $optional{CC_CCSALE} = [
        qw(
            ssl_invoice_number
            ssl_description
            ssl_customer_code
            ssl_salestax
            ssl_token
            ssl_cvv2cvc2_indicator
            ssl_cvv2cvc2
            ssl_avs_zip
            ssl_avs_address
            ssl_ship_to_zip
            ssl_ship_to_country
            ssl_shipping_amount
            ssl_ship_from_postal_code
            ssl_discount_amount
            ssl_duty_amount
            ssl_national_tax_indicator
            ssl_national_tax_amount
            ssl_order_date
            ssl_other_tax
            ssl_summary_commodity_code
            ssl_merchant_vat_number
            ssl_customer_vat_number
            ssl_freight_tax_amount
            ssl_freight_tax_rate
            ssl_vat_invoice_number
            ssl_tracking_number
            ssl_shipping_company
            ssl_other_fees
            ssl_level3_indicator
            ssl_company
            ssl_first_name
            ssl_last_name
            ssl_address2
            ssl_city
            ssl_state
            ssl_country
            ssl_phone
            ssl_email
            ssl_ship_to_company
            ssl_ship_to_first_name
            ssl_ship_to_last_name
            ssl_ship_to_address1
            ssl_ship_to_address2
            ssl_ship_to_city
            ssl_ship_to_state
            LineItemProducts
            )
    ];
    $optional{CC_CCCREDIT} = $optional{CC_CCSALE};

    my $type_action = $self->transaction_type(). '_'. $content{ssl_transaction_type};
    unless ( exists( $required{$type_action} ) ) {
        $self->error_message( q{Elavon can't handle transaction type: }
                . $content{action}
                . q{ on }
                . $self->transaction_type() );
        $self->is_success(0);
        return;
    }

    my $expdate_mmyy = $self->expdate_mmyy( $content{'expiration'} );
    my $zip          = $content{'zip'};
    $zip =~ s/[^[:alnum:]]//g;

    my $cvv2indicator = $content{'cvv2'} ? 1 : 9; # 1 = Present, 9 = Not Present

    $self->_revmap_fields(

        ssl_merchant_id        => 'login',
        ssl_pin                => 'password',

        ssl_amount             => 'amount',
        ssl_card_number        => 'card_number',
        ssl_exp_date           => \$expdate_mmyy,    # MMYY from 'expiration'
        ssl_cvv2cvc2_indicator => \$cvv2indicator,
        ssl_cvv2cvc2           => 'cvv2',
        ssl_description        => 'description',
        ssl_invoice_number     => 'invoice_number',
        ssl_customer_code      => 'customer_id',

        ssl_first_name         => 'first_name',
        ssl_last_name          => 'last_name',
        ssl_company            => 'company',
        ssl_avs_address        => 'address',
        ssl_city               => 'city',
        ssl_state              => 'state',
        ssl_avs_zip            => \$zip,          # 'zip' with non-alnums removed
        ssl_country            => 'country',
        ssl_phone              => 'phone',
        ssl_email              => 'email',

        ssl_ship_to_first_name => 'ship_first_name',
        ssl_ship_to_last_name  => 'ship_last_name',
        ssl_ship_to_company    => 'ship_company',
        ssl_ship_to_address1   => 'ship_address',
        ssl_ship_to_city       => 'ship_city',
        ssl_ship_to_state      => 'ship_state',
        ssl_ship_to_zip        => 'ship_zip',
        ssl_ship_to_country    => 'ship_country',

    );

    my %params = $self->get_fields( @{$required{$type_action}},
                                    @{$optional{$type_action}},
                                  );

    my $products = [];
    if ( $content{products} and ref $content{products} eq 'ARRAY' ) {
        for my $prod ( @{ $content{products} } ) {
            next unless ref $prod;
            $prod->{$_} = substr( $prod->{$_}, 0, $maxlength_line_item{$_} )
                for grep exists $maxlength_line_item{$_}, keys %$prod;
        }
        $params{LineItemProducts} = { product => $content{products} };
        $params{ssl_level3_indicator} = 'Y';
    }

    $params{$_} = substr( $params{$_}, 0, $maxlength{$_} )
        for grep exists( $maxlength{$_} ), keys %params;

    for ( keys( %{ ( $self->{_defaults} ) } ) ) {
        $params{$_} = $self->{_defaults}->{$_} unless exists( $params{$_} );
    }

    $params{ssl_test_mode}='true' if $self->test_transaction;
    
    $params{ssl_show_form}='false';
    $params{ssl_result_format}='ASCII';

    $self->required_fields(@{$required{$type_action}});
    
    warn join("\n", map{ "$_ => $params{$_}" } keys(%params)) if $self->debug > 1;

    my $xml = { xmldata => hash2xml( { txn => \%params } ) };

    my ( $page, $resp, %resp_headers ) = $self->https_post( $xml );

    $self->response_code( $resp );
    $self->response_page( $page );
    $self->response_headers( \%resp_headers );

    warn "$page\n" if $self->debug > 1;
    # $page contains XML

    my $status = '';
    my $result_hash = xml2hash $page;
    my %results = %{$result_hash->{txn}};

    # AVS and CVS values may be set on success or failure
    $self->avs_code( $results{ssl_avs_response} );
    $self->cvv2_response( $results{ ssl_cvv2_response } );
    $self->result_code( $status = $results{ errorCode } || $results{ ssl_result } );
    $self->order_number( $results{ ssl_txn_id } );
    $self->authorization( $results{ ssl_approval_code } );
    $self->error_message( $results{ errorMessage } || $results{ ssl_result_message } );

    if ( $resp =~ /^(HTTP\S+ )?200/ and $status eq '0' ) {
        $self->is_success(1);
    } else {
        $self->is_success(0);
    }
}

1;
__END__

=head1 SEE ALSO

Business::OnlinePayment, Business::OnlinePayment::viaKlix, Elavon Virtual Merchant Developers' Guide

=head1 AUTHORS

Richard Siddall, E<lt>elavon@elirion.netE<gt>

Josh Lavin, E<lt>digory@cpan.orgE<gt>

=head1 BUGS

Duplicates code to handle deprecated 'type' codes.

Method for passing raw card track data is not documented by Elavon.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Richard Siddall.  This module is largely based on Business::OnlinePayment::viaKlix by Jeff Finucane.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

