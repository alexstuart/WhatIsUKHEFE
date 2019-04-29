<?xml version="1.0" encoding="UTF-8"?>
<!--

        list-ac-uk.xsl

        Lists entityIDs of all visible IdPs which are registered by the UK federation and
        which have at least one scope ending .ac.uk.

	Uses method described in https://stackoverflow.com/questions/11848780/use-ends-with-in-xslt-v1-0#11857166

	License: Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
	URL: https://creativecommons.org/licenses/by-sa/3.0/
        
        Author: Alex Stuart, alex.stuart@jisc.ac.uk

-->
<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
        xmlns:mdrpi="urn:oasis:names:tc:SAML:metadata:rpi"
        xmlns:shibmd="urn:mace:shibboleth:metadata:1.0"
        xmlns:mdattr="urn:oasis:names:tc:SAML:metadata:attribute"
        xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

        <xsl:output method="text" encoding="UTF-8"/>

        <xsl:template match="md:EntityDescriptor
		['.ac.uk'=substring(md:IDPSSODescriptor/md:Extensions/shibmd:Scope, string-length(md:IDPSSODescriptor/md:Extensions/shibmd:Scope) - string-length('.ac.uk') + 1)]
		[md:Extensions/mdrpi:RegistrationInfo[@registrationAuthority='http://ukfederation.org.uk']]
                [not(md:Extensions/mdattr:EntityAttributes/saml:Attribute/saml:AttributeValue='http://refeds.org/category/hide-from-discovery')]">
                <xsl:value-of select="@entityID"/>
                <xsl:text>&#10;</xsl:text>
        </xsl:template>

        <xsl:template match="text()">
                <!-- do nothing -->
        </xsl:template>
</xsl:stylesheet>
