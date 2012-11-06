<xsl:transform
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:js="http://saxonica.com/ns/globalJS"
xmlns:style="http://saxonica.com/ns/html-style-property"
xmlns:f="urn:internal.function"
extension-element-prefixes="ixsl"
version="2.0"
>

<xsl:template match="/">
<xsl:result-document href="#nav" method="replace-content">
<xsl:call-template name="shownode">
<xsl:with-param name="isfirst" select="true()"/>
</xsl:call-template>
</xsl:result-document>
</xsl:template>

<xsl:template name="shownode">
<xsl:param name="isfirst" as="xs:boolean"/>
<xsl:if test="exists(*)">
<ul>
<xsl:for-each select="*">
<li class="{if (exists(*)) then
if ($isfirst) then 'open' else 'closed'
else 'empty'}"
data-id="{position()}">
<span class="item"><xsl:value-of select="name(.)"/></span>
<xsl:if test="$isfirst">
<xsl:call-template name="shownode">
<xsl:with-param name="isfirst" select="false()"/>
</xsl:call-template>
</xsl:if>
</li>
</xsl:for-each>
</ul>
</xsl:if>
</xsl:template>


</xsl:transform>
