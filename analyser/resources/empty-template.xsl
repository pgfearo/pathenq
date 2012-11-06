<xsl:transform
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:f="urn:local-function"
version="2.0"
>

<xsl:template match="/">
<top>
!!!TEMPLATECALL
</top>
</xsl:template>

<xsl:template name="wrap">
<xsl:param name="c" as="item()*"/>
<xsl:for-each select="$c">
<result type="{if (. instance of xs:boolean) then 'xs:boolean'
else if (. instance of xs:integer) then 'xs:integer'
else if (. instance of xs:decimal) then 'xs:decimal'
else if (. instance of xs:float) then 'xs:float'
else if (. instance of xs:double) then 'xs:double'
else if (. instance of xs:string) then 'xs:string'
else if (. instance of xs:QName) then 'xs:QName'
else if (. instance of xs:anyURI) then 'xs:anyURI'
else if (. instance of xs:hexBinary) then 'xs:hexBinary'
else if (. instance of xs:base64Binary) then 'xs:base64Binary'
else if (. instance of xs:date) then 'xs:date'
else if (. instance of xs:dateTime) then 'xs:dateTime'
else if (. instance of xs:time) then 'xs:time'
else if (. instance of xs:duration) then 'xs:duration'
else if (. instance of xs:gYear) then 'xs:gYear'
else if (. instance of xs:gYearMonth) then 'xs:gYearMonth'
else if (. instance of xs:gMonth) then 'xs:gMonth'
else if (. instance of xs:gMonthDay) then 'xs:gMonthDay'
else if (. instance of xs:gDay) then 'xs:gDay'
else if (. instance of xs:untypedAtomic) then 'xs:untypedAtomic'
else if (. instance of document-node()) then 'document-node'
else if (. instance of element()) then 'element'
else if (. instance of comment()) then 'comment'
else if (. instance of processing-instruction()) then 'processing-instruction'
else if (. instance of text()) then 'text'
else if (. instance of attribute()) then 'attribute'
else 'node'}"
name="{if (. instance of xs:anyAtomicType) then '' else name(.)}"
path="{if (. instance of xs:anyAtomicType) then () else
f:pathlocation(.)}">
<xsl:value-of select="."/>
</result>
</xsl:for-each>
</xsl:template>

<xsl:function name="f:pathlocation">
<xsl:param name="node"/>
<xsl:value-of select="string-join(reverse(f:getpath($node)),'/')"/>
</xsl:function>

<xsl:function name="f:getpath">
<xsl:param name="node"/>
<xsl:for-each select="$node">
<xsl:variable name="n" select="."/>
<xsl:value-of select="if ($node instance of element()) then
    for $c in count(preceding-sibling::*[name(.) eq name($n)]) return
    if ($c gt 0 or count(following-sibling::*[name(.) eq name($n)]) gt 0) then concat(name(.), '[',$c + 1,']') else name($n)
else if ($node instance of attribute()) then
    concat('@',name($n))
else if ($node instance of text()) then
    for $t in count(preceding-sibling::text()) return
    if ($t gt 0 or count(following-sibling::text()) gt 0) then concat('text()[', $t + 1, ']') else 'text()'
else if ($node instance of comment()) then
    for $ct in count(preceding-sibling::comment()) return
    if ($ct gt 0 or count(following-sibling::comment) gt 0) then concat('comment()[', $ct + 1, ']') else 'comment()'
else if ($node instance of processing-instruction()) then
    for $pi in count(preceding-sibling::processing-instruction()) return
    if ($pi gt 0 or count(following-sibling::processing-instruction()) gt 0) then concat('processing-instruction()[', $pi + 1, ']') else 'processing-instruction()'
else ()"/>
<xsl:for-each select="$node/parent::*">
<xsl:sequence select="f:getpath($node/parent::*)"/>
</xsl:for-each>
</xsl:for-each>
</xsl:function>

</xsl:transform>
